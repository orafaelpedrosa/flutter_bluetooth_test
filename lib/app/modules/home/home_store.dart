import 'dart:async';
import 'dart:developer';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeStore extends NotifierStore<Exception, List<DiscoveredDevice>> {
  bool foundDeviceWaitingToConnect = false;
  bool scanStarted = false;
  bool connected = false;

  FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<List<int>>? subscribeStream;
  StreamSubscription<DiscoveredDevice>? scanStream;
  final deviceConnectionController = StreamController<ConnectionStateUpdate>();
  StreamSubscription<ConnectionStateUpdate>? _connection;
  late StreamSubscription subscription;
  final listDevices = <DiscoveredDevice>[];
  late QualifiedCharacteristic rxCharacteristic;

  final List<Uuid> serviceIds = [
    Uuid.parse('00001810-0000-1000-8000-00805f9b34fb'),
    Uuid.parse('46a970e00d5f11e28b5e0002a5d5c51b'),
  ];
  Uuid characteristicUuid = Uuid.parse('00002A35-0000-1000-8000-00805f9b34fb');
  //Uuid characteristicUuid = Uuid.parse('0aad7ea00d6011e28e3c0002a5d5c51b');

  String? readOutput;
  String? writeOutput;
  String? subscribeOutput;

  HomeStore() : super([]);

  Future<void> scanStart(
    List<Uuid> serviceIds,
  ) async {
    listDevices.clear();
    stopScan();
    var bleStatus = await Permission.bluetoothScan.status;
    log(bleStatus.toString());

    if (bleStatus.isGranted) {
      await Permission.bluetoothScan.request();
    }
    
    scanStarted = true;
    scanStream = flutterReactiveBle.scanForDevices(
      withServices: [],
      requireLocationServicesEnabled: false,
    ).listen(
      (device) {
        final knownDeviceIndex =
            listDevices.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          listDevices[knownDeviceIndex] = device;
        } else {
          if (device.name != '') {
            listDevices.add(device);
            update(listDevices);
          }
        }
      },
    );
  }

  Future<void> stopScan() async {
    if (scanStream != null) scanStream?.cancel();
    scanStarted = false;
  }

  Future<void> connect(DiscoveredDevice device) async {
    setLoading(true);
    _connection?.cancel();
    _connection = flutterReactiveBle
        .connectToDevice(
      id: device.id,
    )
        .listen(
      (update) {
        log('${device.name}: ${update.connectionState}');
        deviceConnectionController.add(update);
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            {
              foundDeviceWaitingToConnect = true;
              connected = true;

              device.name == 'Nonin3230_501570986'
                  ? rxCharacteristic = QualifiedCharacteristic(
                      characteristicId:
                          Uuid.parse('0aad7ea00d6011e28e3c0002a5d5c51b'),
                      serviceId: Uuid.parse('46a970e00d5f11e28b5e0002a5d5c51b'),
                      deviceId: device.id,
                    )
                  : rxCharacteristic = QualifiedCharacteristic(
                      characteristicId: Uuid.parse('2a35'),
                      serviceId: Uuid.parse('1810'),
                      deviceId: device.id,
                    );

              break;
            }
          case DeviceConnectionState.disconnected:
            {
              break;
            }
          default:
        }
      },
      onError: (Object e) =>
          log('Connecting to device ${device.name} resulted in error $e'),
    );

    if (connected) {
      setLoading(false);
    }
  }

  Future<void> disconnect(DiscoveredDevice device) async {
    try {
      log('disconnecting to device: ${device.name}');
      await _connection?.cancel();
    } on Exception catch (e, _) {
      log("Error disconnecting from a device: $e");
    } finally {
      deviceConnectionController.add(
        ConnectionStateUpdate(
          deviceId: device.id,
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      );
    }
  }

  Future<List<DiscoveredService>> discoverServices(
      DiscoveredDevice device) async {
    setLoading(true);
    try {
      log('Start discovering services for: ${device.name}');
      final result = await flutterReactiveBle.discoverServices(device.id);
      log('Discovering services finished');
      return result;
    } on Exception catch (e) {
      log('Error occured when discovering services: $e');
      rethrow;
    }
  }

  Future<void> subscribeCharacteristic() async {
    if (connected) {
      log('Iniciando caracteristica');

      log(rxCharacteristic.toString());
      subscribeStream =
          flutterReactiveBle.subscribeToCharacteristic(rxCharacteristic).listen(
        (data) {
          subscribeOutput = data.toString();
          log(data.toString());
        },
      );
    }
  }

  Future<void> readCharacteristic() async {
    setLoading(true);
    final result =
        await flutterReactiveBle.readCharacteristic(rxCharacteristic);
    readOutput = result.toString();
    log(result.toString());
    setLoading(false);
  }

  Future<void> writeCharacteristicWithResponse() async {
    setLoading(true);
    await flutterReactiveBle.writeCharacteristicWithResponse(
      rxCharacteristic,
      value: [0xff],
    );
    setLoading(false);
  }

  Future<void> writeCharacteristicWithoutResponse() async {
    setLoading(true);
    await flutterReactiveBle.writeCharacteristicWithoutResponse(
      rxCharacteristic,
      value: [0xff],
    );
    setLoading(false);
  }

  Future<void> dispose() async {
    await deviceConnectionController.close();
  }
}
