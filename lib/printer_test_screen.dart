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

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    try {
      await printer.connect(device);
      setState(() {
        selectedDevice = device;
        isConnected = true;
      });
    } catch (e) {
      print('Error connecting to printer: $e');
    }
  }

  Future<void> _printSampleReceipt() async {
    if (!isConnected || selectedDevice == null) {
      print('Printer not connected');
      return;
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(
      PaperSize.mm58,
      profile,
    );

    List<int> bytes = [];
    bytes += generator.text('Sample Store',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('123 Main Street',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('City, State, ZIP',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6),
      PosColumn(text: 'Qty', width: 3),
      PosColumn(text: 'Price', width: 3),
    ]);
    bytes += generator.hr();
    bytes += generator.text('Thank You!',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.cut();

    try {
      await printer.writeBytes(Uint8List.fromList(bytes));
    } catch (e) {
      print('Error printing receipt: $e');
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
              onPressed: isConnected ? _printSampleReceipt : null,
              child: Text('Print Sample Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
