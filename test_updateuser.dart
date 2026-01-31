import 'dart:convert';
import 'package:flutter_client/data/models/protocol/update_user.dart';
import 'package:flutter_client/data/models/protocol/enums.dart';

void main() {
  // Create a test UpdateUser message
  final updateUser = UpdateUser(
    dataset: UpdateUserDataset(
      identity: 'TEST_ENCRYPTED_IDENTITY',
      nickname: 'TestNickname',
      foregroundColor: -16777216,
      backgroundColor: -1,
    ),
  );
  
  // Print the JSON
  final json = updateUser.toJson();
  print('UpdateUser JSON:');
  print(jsonEncode(json));
  
  // Print formatted
  print('\nFormatted:');
  final encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(json));
}
