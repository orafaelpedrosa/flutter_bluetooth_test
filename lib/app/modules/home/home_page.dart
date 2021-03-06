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
                DeviceList(
                  discoveredDevice: store.listDevices,
                ),
              ],
            ),
          );
        },
      ),
      /*floatingActionButton: TripleBuilder(
        store: store,
        builder: (_, triple) {
          return store.scanStarted
              ? FloatingActionButton(
                  onPressed: () => store.stopScan(),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.stop),
                )
              : FloatingActionButton(
                  onPressed: () => store.scanStart([]),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.search),
                );
        },
      ),*/

      floatingActionButton: store.scanStarted
          ? FloatingActionButton(
              onPressed: () => store.stopScan(),
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            )
          : FloatingActionButton(
              onPressed: () => store.scanStart([]),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.search),
            ),
    );
  }
}
