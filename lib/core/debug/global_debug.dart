import 'package:flutter/foundation.dart';

class GlobalDebug {
  static final ValueNotifier<String> log = ValueNotifier<String>('');
  
  static void add(String message) {
     final time = DateTime.now().toIso8601String().split('T').last;
     log.value = '$time: $message\n' + log.value;
     // Keep last 50 lines
     if (log.value.length > 5000) {
       log.value = log.value.substring(0, 5000);
     }
  }
}
