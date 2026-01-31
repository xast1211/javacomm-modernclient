import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../data/models/protocol/message.dart';
import '../../data/models/protocol/enums.dart';
import '../../data/models/protocol/message_factory.dart';

import '../../core/debug/global_debug.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Message>.broadcast();

  Stream<Message> get messages => _messageController.stream;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      GlobalDebug.add('WebSocket connecting to: $url');
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('WebSocket Error: $error');
          GlobalDebug.add('WebSocket Error: $error');
          _messageController.addError(error);
        },
        onDone: () {
          print('WebSocket Closed');
          GlobalDebug.add('WebSocket Closed from Server');
        },
      );
    } catch (e) {
      print('Connection failed: $e');
      GlobalDebug.add('WebSocket Connection Failed: $e');
      rethrow;
    }
  }

  void sendMessage(Message message) {
    if (_channel != null) {
      final jsonString = jsonEncode(message.toJson());
      print('Sending: $jsonString');
      // Truncate long messages for UI (e.g. USERONLINELIST updates can be huge, but here we want to see UPDATEUSER)
      if (message.command == Command.UPDATEUSER) {
         GlobalDebug.add('OUT -> UPDATEUSER: $jsonString');
      } else {
         final logMsg = jsonString.length > 200 ? '${jsonString.substring(0, 200)}...' : jsonString;
         GlobalDebug.add('OUT: $logMsg');
      }
      _channel!.sink.add(jsonString);
    } else {
      print('WebSocket not connected');
      GlobalDebug.add('Error: WebSocket not connected, cannot send.');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      // GlobalDebug.add('IN RAW: $data'); // Too spammy? Maybe
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) {
         // Only log important stuff fully
         final checkHeader = json['HEADER'];
         final checkCommand = json['COMMAND'];
         
         if (checkCommand == 'UPDATEUSER' || checkCommand == 'USRLOGIN') {
             GlobalDebug.add('IN <- $checkCommand ($checkHeader): $data');
         } else if (checkCommand != 'KEEPALIVE') {
             // Log others briefly
             GlobalDebug.add('IN: $checkCommand ($checkHeader)');
         }
         
         final message = MessageFactory.fromJson(json);
         _messageController.add(message);
      }
    } catch (e) {
      print('Failed to decode message: $e');
      GlobalDebug.add('Failed to decode incoming message: $e\nData: $data');
    }
  }

  void disconnect() {
    GlobalDebug.add('WebSocket Disconnecting...');
    _channel?.sink.close();
  }
}
