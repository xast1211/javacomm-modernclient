import 'dart:convert';
import 'package:flutter_client/data/models/protocol/token.dart';

void main() {
  // Test Token creation
  final token = Token(
    userid: 'xast1211',
    email: 'xast@xast.de',
    password: 'LarsBabs',
  );
  
  print('Token JSON:');
  print(token.toString());
  
  print('\nExpected (JChat):');
  print('{"USERID":"xast1211","EMAIL":"xast@xast.de","PASSWORD":"LarsBabs"}');
}
