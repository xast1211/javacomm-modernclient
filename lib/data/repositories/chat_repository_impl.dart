
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/constants/api_constants.dart';

import '../../core/network/websocket_service.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/protocol/chat_models.dart';
import '../models/protocol/enums.dart';
import '../models/protocol/message.dart';
import '../models/protocol/usrlogin.dart';
import '../models/protocol/keepalive.dart';
import '../models/protocol/call_remote_user.dart';
import '../../core/debug/global_debug.dart';

class ChatRepositoryImpl implements ChatRepository {
  final WebSocketService webSocketService;
  @override
  String? myUserId;
  String? myNickname;
  String? mySessionId;
  
  List<UserOnline> _lastRawUsers = [];
  List<UserOnline> _lastFilteredUsers = [];

  final _onlineUsersController = StreamController<List<UserOnline>>.broadcast();
  final _privateMessageController = StreamController<PrivateMessage>.broadcast();
  final _privateChatRequestController = StreamController<CallPrivateChat>.broadcast();
  final _callPrivateChatResponseController = StreamController<CallPrivateChat>.broadcast();
  final _leavePrivateChatController = StreamController<LeavePrivateChat>.broadcast();
  final _callRemoteUserController = StreamController<CallRemoteUser>.broadcast();

  Timer? _keepAliveTimer;

  ChatRepositoryImpl({
    required this.webSocketService,
  }) {
    webSocketService.messages.listen(_handleMessage);
  }

  // ... (existing overrides)

  @override
  Stream<LeavePrivateChat> get leavePrivateChatStream => _leavePrivateChatController.stream;

  // ... (handleMessage switch)



  @override
  void initializeUser(String userId, String nickname, {String? sessionId}) {
    myUserId = userId;
    myNickname = nickname;
    mySessionId = sessionId;
    
    // Send initial KeepAlive immediately
    if (mySessionId != null) {
         final keepAlive = KeepAlive(
            header: Header.REQUEST, 
            command: Command.KEEPALIVE, 
            dataset: {'SESSIONID': mySessionId},
          );
          print('Sending Initial KeepAlive');
          webSocketService.sendMessage(keepAlive);
          webSocketService.sendMessage(keepAlive);
    }
    
    // requestOnlineUsers(); // Server pushes list automatically
    if (myUserId != null) {
       _onlineUsersController.add(
         _lastRawUsers.where((u) => u.userid != myUserId).toList()
       );
    }
    
    // Safety fallback: If list is empty, request it after delay
    Future.delayed(const Duration(seconds: 1), () {
        if (_lastRawUsers.isEmpty) {
            print('Fallback: Requesting online users manually');
            requestOnlineUsers();
        }
    });
    
    _startKeepAlive();
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    // Server expectation: PUT /javacommserver/user/write/keepalive/{userid}
    // Client schedule: Every 40-60 seconds (Server defaults to 60s timeout checkout)
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 40), (timer) async {
      if (myUserId != null) {
        try {
          final url = Uri.parse('${ApiConstants.restBaseUrl}/user/write/keepalive/$myUserId');
          // No body required by server, but PUT usually expects one. JChat sends empty string.
          final response = await http.put(
             url, 
             headers: {'Content-Type': 'text/plain'},
             body: ''
          );
          
          if (response.statusCode == 200 && response.body == 'true') {
             print('KeepAlive (REST) Success for $myUserId');
          } else {
             print('KeepAlive (REST) Failed: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          print('KeepAlive (REST) Error: $e');
        }
      }
    });
  }

  @override
  Stream<List<UserOnline>> get onlineUsers => _onlineUsersController.stream;

  @override
  List<UserOnline> get lastUsers => _lastFilteredUsers;

  @override
  Stream<PrivateMessage> get incomingPrivateMessages => _privateMessageController.stream;

  @override
  Stream<CallPrivateChat> get incomingPrivateChatRequests => _privateChatRequestController.stream;

  @override
  Stream<CallPrivateChat> get callPrivateChatResponses => _callPrivateChatResponseController.stream;

  @override
  Stream<CallRemoteUser> get incomingRemoteUserCalls => _callRemoteUserController.stream;

  void _handleMessage(Message message) {
    // GlobalDebug.add('Repo: Msg ${message.runtimeType} Cmd: ${message.command}');
    if (message is UserOnlineList) {
       GlobalDebug.add('Repo: Handling UserOnlineList');
       print('Repository: Handling UserOnlineList');
       _lastRawUsers = message.userOnline ?? [];
       GlobalDebug.add('Repo: Raw users count: ${_lastRawUsers.length}');
       
       // Filter out self using the logged-in User ID (myUserId).
       // Do NOT use message.dataset['USERID'] as that might be the user who triggered the update (e.g. the new login).
       final selfId = myUserId;
       
       print('Repository: Filtering for selfId: $selfId');
       
       _lastFilteredUsers = _lastRawUsers.where((u) => u.userid != selfId).toList();
       GlobalDebug.add('Repo: Filtered Users: ${_lastFilteredUsers.length} (SelfID: $selfId)');
       
       print('Repository: Adding ${_lastFilteredUsers.length} users to controller (Total raw: ${_lastRawUsers.length})');
       _onlineUsersController.add(_lastFilteredUsers); 
    } else if (message is PrivateMessage) {
       print('Repository: Received PrivateMessage');
       _privateMessageController.add(message);
    } else if (message is CallPrivateChat) {
       if (message.header == Header.REQUEST) {
         print('Repository: Incoming Call Request');
         _privateChatRequestController.add(message);
       } else if (message.header == Header.CONFIRM || message.header == Header.RESPONSE) {
          print('Repository: Received Call Response/Confirm (Local=${message.localSessionId}, Remote=${message.remoteSessionId})');
          _callPrivateChatResponseController.add(message);
       }
    } else if (message is LeavePrivateChat) {
       print('Repository: Received LEAVEPRIVATECHAT. Gone Session: ${message.goneSessionId}');
       _leavePrivateChatController.add(message);
    } else if (message is CallRemoteUser) {
       print('Repository: Received CALLREMOTEUSER. RemoteNick: ${message.remoteNickname} (Caller)');
       _callRemoteUserController.add(message);
    }
  }

  @override
  void requestOnlineUsers() {
    final msg = UserOnlineList(
      header: Header.REQUEST,
      command: Command.USERONLINELIST,
      dataset: {'USERID': myUserId ?? ''},
    );
    webSocketService.sendMessage(msg);
  }

  @override
  void callPrivateChat(String recipientUid, String recipientNickname) {
    if (mySessionId == null) {
      print('Cannot start chat: Session ID is null');
      return;
    }
    
    // JChat does NOT generate a UUID here. It sends NULL for LOCAL_SESSIONID.
    // The server or the confirm mechanism likely handles this.
    
    // RESTORED: Use CALLPRIVATECHAT with Client-Side UUID.
    // This worked previously according to user.
    
    final sessionId = const Uuid().v4();
    
    final msg = CallPrivateChat(
      header: Header.REQUEST,
      command: Command.CALLPRIVATECHAT,
      dataset: {
        'SENDER_UID': myUserId ?? '',
        'RECIPIENT_UID': recipientUid,
        'LOCAL_NICKNAME': myNickname ?? '',
        'LOCAL_SESSIONID': sessionId, // Generated ID
        'REMOTE_NICKNAME': recipientNickname,
        'REMOTE_SESSIONID': null, 
      },
    );
    webSocketService.sendMessage(msg);
  }

  @override
  Future<void> sendPrivateMessage(String recipientUid, String message, {String? localSessionId, String? remoteSessionId}) async {
     final msg = PrivateMessage(
       header: Header.REQUEST,
       command: Command.PRIVATEMESSAGE,
       dataset: {
          'SENDER_UID': myUserId ?? '',
          'MESSAGE': message,
          'DATETIME': DateTime.now().millisecondsSinceEpoch,
          'CHATUSER': {
             'USERID': myUserId ?? '',
             'NICKNAME': myNickname ?? '',
             'FOREGROUND_COLOR': 0, 
             'BACKGROUND_COLOR': 0, 
          },
          // JChat checks for this ID to match the session.
          'LOCAL_SESSIONID': localSessionId ?? '',
          'REMOTE_SESSIONID': remoteSessionId ?? '', // Mandatory. Must match Peer's Session ID.
       }
     );
     webSocketService.sendMessage(msg);
  }

  @override
  void sendMessage(PrivateMessage message) {
    webSocketService.sendMessage(message);
  }

  @override
  String acceptPrivateChat(CallPrivateChat request) {
     final localChatId = const Uuid().v4();
  
     final msg = CallPrivateChat(
      header: Header.CONFIRM,
      command: Command.CALLPRIVATECHAT,
      dataset: {
        'SENDER_UID': myUserId ?? '',
        'RECIPIENT_UID': request.senderUid,
        'LOCAL_NICKNAME': myNickname ?? '',
        'REMOTE_NICKNAME': request.localNickname,
        'LOCAL_SESSIONID': localChatId, // Send NEW Chat Session ID
        'REMOTE_SESSIONID': request.localSessionId,
      }
    );
    webSocketService.sendMessage(msg);
    return localChatId;
  }

  @override
  String acceptCallRemoteUser(CallRemoteUser request) {
     // Use the IDs provided by the server in the Request.
     // LocalSessionId = My (Flutter) WebSocket ID (as known by Server)
     // RemoteSessionId = Peer (JChat) WebSocket ID
     
     final mySessionId = request.localSessionId ?? '';
     final peerSessionId = request.remoteSessionId ?? '';
  
     final msg = CallRemoteUser(
      header: Header.CONFIRM,
      command: Command.CALLREMOTEUSER,
      dataset: {
        'LOCAL_NICKNAME': myNickname ?? '', 
        'LOCAL_SESSIONID': peerSessionId, // Set Local to Peer (Caller) to route response to them
        'REMOTE_NICKNAME': request.localNickname, 
        'REMOTE_SESSIONID': mySessionId, // Set Remote to Me (Callee)
      }
    );
    
    print('Repository: Sending CALLREMOTEUSER CONFIRM: ${msg.toJson()}');
    webSocketService.sendMessage(msg);
    return mySessionId;
  }

  @override
  Future<void> sendLeavePrivateChat(String goneSessionId) async {
      final message = LeavePrivateChat(
        header: Header.REQUEST,
        command: Command.LEAVEPRIVATECHAT,
        dataset: {
           'GONE_SESSIONID': goneSessionId
        }
      );
      
      print('Repository: Sending LEAVEPRIVATECHAT: ${message.toJson()}');
      webSocketService.sendMessage(message);
  }

  void dispose() {
      _keepAliveTimer?.cancel();
      _callRemoteUserController.close();
  }
}
