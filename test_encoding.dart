import 'dart:convert';

void main() {
  // Test different encoding methods
  final testString = 'aUFkmltx4/z7wjM4Zl0MK0ReBnuG/yw02eNfLhzhJGVyLu0nIo2fySn8sV1Xyh6HTM6cRI4ZTeafqcPtBDal2NTcTZmyjer6AK6zphpCvBV4f/Gekfjg3BsPFlCWTHOJYL0mDQto3sg=';
  
  print('Original string:');
  print(testString);
  print('');
  
  print('Standard jsonEncode:');
  print(jsonEncode(testString));
  print('');
  
  print('With map:');
  final map = {'IDENTITY': testString};
  print(jsonEncode(map));
  print('');
  
  // Check if = is at the end
  print('Last char: "${testString[testString.length - 1]}"');
  print('Is equals: ${testString[testString.length - 1] == "="}');
}
