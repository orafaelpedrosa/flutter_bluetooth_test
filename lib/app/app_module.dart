import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_final/app/modules/bluetooth/device_details_page.dart';

import 'modules/home/home_module.dart';

class AppModule extends Module {
  @override
  final List<Bind> binds = [
  ];

  @override
  final List<ModularRoute> routes = [
    ModuleRoute(Modular.initialRoute, module: HomeModule()),
    ChildRoute("/device_details", child: (_, args) => DeviceDetailsPage(
      device: args.data,
    )),
  ];
}
