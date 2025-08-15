import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth HC Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GetStartedPage(),
    );
  }
}

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConnectBluetoothPage()),
            );
          },
          child: const Text("Connect Bluetooth"),
        ),
      ),
    );
  }
}

class ConnectBluetoothPage extends StatefulWidget {
  const ConnectBluetoothPage({super.key});

  @override
  State<ConnectBluetoothPage> createState() => _ConnectBluetoothPageState();
}

class _ConnectBluetoothPageState extends State<ConnectBluetoothPage> {
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devices = [];
  bool isConnecting = false;
  String status = "Not connected";
  BluetoothConnection? connection;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
    _getBondedDevices();
  }

  Future<void> _checkBluetooth() async {
    bool? isEnabled = await bluetooth.isEnabled;
    if (isEnabled != true) {
      await bluetooth.requestEnable();
    }
  }

  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> bonded = await bluetooth.getBondedDevices();
    setState(() {
      devices = bonded;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
      status = "Connecting to ${device.name ?? device.address}...";
    });

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        connectedDevice = device;
        status = "Connected to ${device.name ?? device.address}";
        isConnecting = false;
      });

      connection!.input?.listen((_) {
        // bisa dipakai untuk handle data masuk
      }).onDone(() {
        setState(() {
          status = "Disconnected";
          connectedDevice = null;
          connection = null;
        });
      });
    } catch (_) {
      setState(() {
        status = "Gagal connect ke Bluetooth";
        isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    await connection?.close();
    setState(() {
      status = "Not connected";
      connectedDevice = null;
      connection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connect Bluetooth")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (connectedDevice != null)
              ElevatedButton(
                onPressed: _disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("Disconnect"),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: devices.isEmpty
                  ? const Center(child: Text("No paired devices found"))
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          title: Text(device.name ?? "Unknown"),
                          subtitle: Text(device.address),
                          trailing: ElevatedButton(
                            onPressed: isConnecting || connectedDevice != null
                                ? null
                                : () => _connectToDevice(device),
                            child: const Text("Connect"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
