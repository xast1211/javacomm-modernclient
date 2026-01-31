import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../data/models/protocol/message.dart';
import '../../data/models/protocol/enums.dart';
import '../../data/models/protocol/message_factory.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Message>.broadcast();

  Stream<Message> get messages => _messageController.stream;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _messageController.addError(error);
        },
        onDone: () {
          print('WebSocket Closed');
        },
      );
    } catch (e) {
      print('Connection failed: $e');
      rethrow;
    }
  }

  void sendMessage(Message message) {
    if (_channel != null) {
      final jsonString = jsonEncode(message.toJson());
      print('Sending: $jsonString');
      _channel!.sink.add(jsonString);
    } else {
      print('WebSocket not connected');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) {
         final message = MessageFactory.fromJson(json);
         _messageController.add(message);
      }
    } catch (e) {
      print('Failed to decode message: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
