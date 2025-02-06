import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';

class PrinterTestScreen extends StatefulWidget {
  const PrinterTestScreen({super.key});

  @override
  PrinterTestScreenState createState() => PrinterTestScreenState();
}

class PrinterTestScreenState extends State<PrinterTestScreen> {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices = await printer.getBondedDevices();
      setState(() {
        devices = bondedDevices;
      });
    } catch (e) {
      print('Error fetching paired devices: $e');
    }
  }

  Future<void> _connectToPrinter(
    BluetoothDevice device,
  ) async {
    try {
      await printer.connect(device);
      setState(() {
        selectedDevice = device;
        isConnected = true;
      });
    } catch (e) {
      if (mounted) {
        showAboutDialog(context: context, children: [
          Text('Error connecting to printer: $e'),
        ]);
      }
    }
  }

  Future<void> _printSampleReceipt() async {
    try {
      if (!isConnected || selectedDevice == null) {
        showAboutDialog(context: context, children: [
          Text('Please connect to a printer first.'),
        ]);
        return;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(
        PaperSize.mm58,
        profile,
      );

      List<int> bytes = [];

      // Header
      bytes += generator.text(
        '***Simplified tax invoice***',
        styles: PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'VAT: 456788899999',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Receipt Info
      bytes += generator.text(
        'This is the receipt for a payment of 50 SAR',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Invoice Details
      bytes += generator.row([
        PosColumn(
          text: 'Invoice No.\n#7788',
          width: 6,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'إسم الفندق',
          width: 6,
          styles: PosStyles(
            align: PosAlign.right,
            codeTable: 'CP1256',
          ),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Cashier No.\n#7',
          width: 6,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'Address\n6991, Bada,ah, Madinah\n42311, Saudia Arabia',
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);

      // Invoice Date
      bytes += generator.text(
        'Invoice date\n3/12/2024 04:07 pm',
        styles: PosStyles(align: PosAlign.left),
      );
      // bytes += generator.feed(1);

      // Price and VAT Details
      bytes += generator.row([
        PosColumn(
          text: 'Price:\n100 SAR',
          width: 6,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'VAT : 15 SAR (15%)',
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.text(
        'Total With Vat: 115 SAR',
        styles: PosStyles(align: PosAlign.left, bold: true),
      );
      // bytes += generator.feed(1);

      // QR Code
      // bytes += generator
      //     .qrcode('https://example.com'); // Replace with actual QR code content

      // Cut
      // bytes += generator.cut();

      try {
        await printer.writeBytes(Uint8List.fromList(bytes));
      } catch (e) {
        if (mounted) {
          showAboutDialog(context: context, children: [
            Text('Error printing receipt: $e'),
          ]);
        }
      }
    } catch (e) {
      if (mounted) {
        showAboutDialog(context: context, children: [
          Text('Error printing receipt: $e'),
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Printer Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paired Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(devices[index].name ?? 'Unknown Device'),
                    subtitle: Text(devices[index].address ?? 'Unknown Address'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _connectToPrinter(devices[index]);
                      },
                      child: Text('Connect'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.blue : Colors.grey,
              ),
              onPressed: isConnected ? _printSampleReceipt : null,
              child: Text('Print Sample Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
