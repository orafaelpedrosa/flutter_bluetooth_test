import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:test_final/app/modules/home/device_list.dart';
import 'home_store.dart';

class HomePage extends StatefulWidget {
  final String title;
  HomePage({Key? key, this.title = "Home"}) : super(key: key);
  Store store = HomeStore();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ModularState<HomePage, HomeStore> {
  // final Stream<List<DiscoveredDevice>> bids = (() {
  //   late final StreamController<List<DiscoveredDevice>> controller;
  //   controller = StreamController<List<DiscoveredDevice>>(
  //     onListen: () async {
  //       await Future<void>.delayed(
  //         const Duration(seconds: 1),
  //       );
  //       controller.stream;
  //       await Future<void>.delayed(
  //         const Duration(seconds: 1),
  //       );
  //       await controller.close();
  //     },
  //   );
  //   return controller.stream;
  // })();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
      ),
      body: ScopedBuilder<HomeStore, Exception, List<DiscoveredDevice>>(
        store: store,
        onLoading: (_) => const Text('Carregando...'),
        onState: (_, scoped) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => store.scanStart([]),
                      child: const Text('Scan'),
                    ),
                  ],
                ),
                DeviceList(
                  discoveredDevice: store.listDevices,
                ),
                /*FloatingActionButton(
                  onPressed: () => store.scanStart([]),
                  child: const Icon(Icons.search),
                )*/
              ],
            ),
          );
        },
      ),
    );
  }
}
