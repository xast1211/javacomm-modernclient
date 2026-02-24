import 'enums.dart';
import 'update_user.dart';
import 'message.dart';
import 'chat_models.dart';
import 'usrlogin.dart';
import 'call_remote_user.dart';
import '../../../core/debug/global_debug.dart';

class MessageFactory {
  static Message fromJson(Map<String, dynamic> json) {
    String? commandStr;
    try {
      // Basic check
      commandStr = json['COMMAND'] as String?;
      
      // Debug log for troubleshooting
      if (commandStr == 'USERONLINELIST') {
         print('Factory parsing USERONLINELIST. JSON keys: ${json.keys}'); 
         GlobalDebug.add('Factory: Found USERONLINELIST. Keys: ${json.keys}');
      }
      
      // print('Factory: Decoded Command: $commandStr');

      if (commandStr == null) return Message.fromJson(json); // Fallback

      switch (commandStr) {
        case 'USERONLINELIST':
          return UserOnlineList.fromJson(json);
        case 'PRIVATEMESSAGE':
          return PrivateMessage.fromJson(json);

        case 'CALLPRIVATECHAT':
          return CallPrivateChat.fromJson(json);
        case 'CALLREMOTEUSER':
          return CallRemoteUser.fromJson(json);
        case 'USRLOGIN':
          return UsrLogin.fromJson(json);
        case 'LEAVEPRIVATECHAT':
          return LeavePrivateChat.fromJson(json);
          
        case 'UPDATEUSER':
          return UpdateUser.fromJson(json);
          
        // Add other commands here
        default:
          return Message.fromJson(json);
      }
    } catch (e, stack) {
      print('MessageFactory error parsing $commandStr: $e\n$stack');
      GlobalDebug.add('Factory Error ($commandStr): $e');
      return Message.fromJson(json);
    }
  }
}
