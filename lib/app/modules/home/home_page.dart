import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:test_final/app/modules/bluetooth/device_list_widget.dart';
import 'home_store.dart';

class HomePage extends StatefulWidget {
  final String title;
  HomePage({Key? key, this.title = "Home"}) : super(key: key);
  HomeStore store = Modular.get();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ModularState<HomePage, HomeStore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
      ),
      body: ScopedBuilder<HomeStore, Exception, List<DiscoveredDevice>>(
        store: store,
        onState: (_, scoped) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => store.scanStart(store.serviceIds),
                      child: const Text('Scan'),
                    ),
                  ],
                ),
                DeviceList(
                  discoveredDevice: store.listDevices,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
