
import 'package:flutter_test/flutter_test.dart';
import 'package:javacomm_client/data/models/protocol/message_factory.dart';
import 'package:javacomm_client/data/models/protocol/chat_models.dart';
import 'package:javacomm_client/data/models/protocol/enums.dart';

void main() {
  test('Parses USERONLINELIST correctly', () {
    final json = {
      "HEADER": "RESPONSE",
      "COMMAND": "USERONLINELIST",
      "DATASET": {
        "USERID": "testuser",
        "USERONLINELIST": [
          {
            "USERID": "user1",
            "NICKNAME": "User 1",
            "IP": "127.0.0.1"
          },
          {
             "USERID": "user2",
             "NICKNAME": "User 2",
             "IP": "192.168.0.1"
          }
        ]
      }
    };

    try {
      final message = MessageFactory.fromJson(json);
      print('Parsed message type: ${message.runtimeType}');
      
      if (message is UserOnlineList) {
         print('Is UserOnlineList');
         final users = message.userOnline;
         print('Users: ${users?.length}');
         if (users != null) {
            for (var u in users) {
               print('User: ${u.userid} - ${u.nickname}');
            }
         }
         expect(users?.length, 2);
      } else {
         fail('Message is not UserOnlineList');
      }
    } catch (e) {
      fail('Parsing failed: $e');
    }
  });
}
