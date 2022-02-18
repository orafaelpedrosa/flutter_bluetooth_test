import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:test_final/app/modules/home/home_store.dart';

class DeviceList extends StatefulWidget {
  late List<DiscoveredDevice> discoveredDevice;
  DeviceList({
    Key? key,
    required this.discoveredDevice,
  }) : super(key: key);

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  final store = HomeStore();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: null,
      builder: (context, snapshot) {
        return ListView(
          shrinkWrap: true,
          children: widget.discoveredDevice
              .map(
                (device) => ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.name),
                  onTap: () => store.connect(device),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
