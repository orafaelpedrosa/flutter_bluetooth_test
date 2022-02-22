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
  late List<DiscoveredService> listDiscoveredService = <DiscoveredService>[];
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

  Future<void> scanStart(List<Uuid> serviceIds) async {
    listDevices.clear();
    stopScan();
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
      connectionTimeout: const Duration(seconds: 5),
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

  Future<void> discoverServices(DiscoveredDevice device) async {
    setLoading(true);
    try {
      log('Start discovering services for: ${device.name}');
      bool onDevice = false;
      listDiscoveredService =
          await flutterReactiveBle.discoverServices(device.id);
      listDiscoveredService.forEach(
        (service) {
          service.characteristics.forEach(
            (characteristics) {
              switch (characteristics.characteristicId.toString()) {
                case '2a35':
                  onDevice = true;
                  break;
                case '0aad7ea0-0d60-11e2-8e3c-0002a5d5c51b':
                  onDevice = true;
                  break;
                default:
                  onDevice = false;
              }
              if (onDevice) {
                onDevice = false;
                rxCharacteristic = QualifiedCharacteristic(
                  characteristicId: characteristics.characteristicId,
                  serviceId: characteristics.serviceId,
                  deviceId: device.id,
                );
              }
            },
          );
        },
      );
    } on Exception catch (e) {
      log('Error occured when discovering services: $e');
      rethrow;
    }
  }

  Future<void> subscribeCharacteristic() async {
    if (connected) {
      log('Starting subscribe characteristic...');
      subscribeStream =
          flutterReactiveBle.subscribeToCharacteristic(rxCharacteristic).listen(
        (data) {
          subscribeOutput = data.toString();
          log(data.toString());
        },
      );
    }
  }

  Future<void> getData(DiscoveredDevice device) async {
    setLoading(true);
    _connection?.cancel();
    _connection = flutterReactiveBle
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen(
      (update) async {
        log('${device.name}: ${update.connectionState}');
        deviceConnectionController.add(update);
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            {
              bool onDevice = false;
              listDiscoveredService =
                  await flutterReactiveBle.discoverServices(device.id);
              listDiscoveredService.forEach(
                (service) {
                  service.characteristics.forEach(
                    (characteristics) {
                      switch (characteristics.characteristicId.toString()) {
                        case '2a35':
                          onDevice = true;
                          break;
                        case '0aad7ea0-0d60-11e2-8e3c-0002a5d5c51b':
                          onDevice = true;
                          break;
                        default:
                          onDevice = false;
                      }
                      if (onDevice) {
                        onDevice = false;
                        rxCharacteristic = QualifiedCharacteristic(
                          characteristicId: characteristics.characteristicId,
                          serviceId: characteristics.serviceId,
                          deviceId: device.id,
                        );
                      }
                    },
                  );
                },
              );
              subscribeStream = flutterReactiveBle
                  .subscribeToCharacteristic(rxCharacteristic)
                  .listen(
                (data) {
                  subscribeOutput = data.toString();
                  log(data.toString());
                },
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
