import 'dart:io';

import 'package:flutter/foundation.dart';

void terminateApp(String message) {
  debugPrint('SECURITY ALERT: $message');
  exit(0);
}
