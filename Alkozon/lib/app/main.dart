import 'package:flutter/material.dart';

import '../core/di/injection_container.dart';
import 'alkozon_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await InjectionContainer.instance.init();
  await InjectionContainer.I.checkDeviceSecurityUseCase();
  await InjectionContainer.I.notificationService.initialize();

  runApp(const AlkozonApp());
}
