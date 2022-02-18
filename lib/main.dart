import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool foundDeviceWaitingToConnect = false;
  bool scanStarted = false;
  bool connected = false;

  FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  //late DiscoveredDevice deviceBle;
  late StreamSubscription<DiscoveredDevice> scanStream;
  //late QualifiedCharacteristic rxCharacteristic;
  late Stream<ConnectionStateUpdate> currentConnectionStream;
  late StreamSubscription<ConnectionStateUpdate> connection;
  final listDevices = <DiscoveredDevice>[];
  late List listDevices2 = [];

  final Uuid serviceUuid = Uuid.parse('46a970e00d5f11e28b5e0002a5d5c51b');
  // final characteristicUuid = Uuid.parse('0aad7ea00d6011e28e3c0002a5d5c51b');

  //late Uuid serviceUuid = Uuid.parse('00001810-0000-1000-8000-00805f9b34fb');
  final characteristicUuid = Uuid.parse('2a35');

  final List<Uuid> uuidList = [
    Uuid.parse('00001810-0000-1000-8000-00805f9b34fb'),
    Uuid.parse('46a970e00d5f11e28b5e0002a5d5c51b'),
  ];

  void scanStart() {
    scanStream = flutterReactiveBle.scanForDevices(
      withServices: [],
    ).listen(
      (device) {
        final knownDeviceIndex =
            listDevices.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          listDevices[knownDeviceIndex] = device;
        } else {
          if (device.name != '') {
            listDevices.add(device);
          }
        }
      },
    );
  }

  void connectDevice(DiscoveredDevice device) {
    log('Conectando ao dispositivo ${device.name}');
    listDevices2 = listDevices.toSet().toList();
    scanStream.cancel();
    currentConnectionStream = flutterReactiveBle.connectToDevice(
      id: device.id,
    );

    currentConnectionStream.listen(
      (event) {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            {
              setState(
                () {
                  foundDeviceWaitingToConnect = true;
                  connected = true;
                },
              );
              log('Conectado: $connected');

              /*rxCharacteristic = QualifiedCharacteristic(
                characteristicId: characteristicUuid,
                serviceId: uuidList.first,
                deviceId: device.id,
              );*/
              //log(rxCharacteristic.toString());
            }
            break;
          case DeviceConnectionState.disconnected:
            {
              log('Desconectado');
              break;
            }
          default:
        }
      },
    );
  }

  /*Future<String> getData() async {
    int oxymeter = 0;
    if (connected) {
      log('Escrevendo caracteristica');
      flutterReactiveBle.subscribeToCharacteristic(rxCharacteristic).listen(
        (data) {
          log('Sub: $data');
        },
      );
    }

    log('Medição: $oxymeter');
    return oxymeter.toString();
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => scanStart(),
                  child: const Text('Scan'),
                ),
              ],
            ),
            StreamBuilder<Object>(
              stream: null,
              builder: (context, snapshot) {
                return ListView(
                  shrinkWrap: true,
                  children: listDevices
                      .map(
                        (device) => ListTile(
                          title: Text(device.name),
                          onTap: () => connectDevice(device),
                        ),
                      )
                      .toList(),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
