import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/protocol/chat_models.dart';
import '../../data/models/protocol/call_remote_user.dart';
import '../../data/models/protocol/enums.dart';
import '../../data/models/protocol/message.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class SendMessage extends ChatEvent {
  final String message;
  const SendMessage(this.message);
}

class ReceiveMessage extends ChatEvent {
  final PrivateMessage message;
  const ReceiveMessage(this.message);
}

class CallResponseReceived extends ChatEvent {
  final CallPrivateChat message;
  const CallResponseReceived(this.message);
}

class ChatStarted extends ChatEvent {
  final String recipientUid;
  final String recipientNickname;
  const ChatStarted({required this.recipientUid, required this.recipientNickname});
}

class ReceiveCallRequest extends ChatEvent {
  final CallPrivateChat message;
  const ReceiveCallRequest(this.message);
}

// Internal event when we receive a CALLREMOTEUSER request
class ReceiveCallRemoteUser extends ChatEvent {
  final CallRemoteUser message;
  const ReceiveCallRemoteUser(this.message);
}

class PrivateChatLeft extends ChatEvent {
  final LeavePrivateChat message;
  const PrivateChatLeft(this.message);
}

class LeaveChat extends ChatEvent {
  const LeaveChat();
}

// New: Manual Decision Events
class AcceptIncomingCall extends ChatEvent {}
class RejectIncomingCall extends ChatEvent {}

enum ChatConnectionStatus { initial, connected, disconnected, incomingRequest }

// States
class ChatState extends Equatable {
  final ChatConnectionStatus status;
  final List<PrivateMessage> messages;
  final String? recipientUid;
  final String? recipientNickname;
  final String? remoteSessionId;
  final String? localChatSessionId;
  final CallRemoteUser? pendingCallRequest; // Stored for manual accept
  
  const ChatState({
      this.status = ChatConnectionStatus.initial,
      this.messages = const [], 
      this.recipientUid,
      this.recipientNickname,
      this.remoteSessionId,
      this.localChatSessionId,
      this.pendingCallRequest,
  });
  
  ChatState copyWith({
    ChatConnectionStatus? status,
    List<PrivateMessage>? messages,
    String? recipientUid,
    String? recipientNickname,
    String? remoteSessionId,
    String? localChatSessionId,
    CallRemoteUser? pendingCallRequest,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      recipientUid: recipientUid ?? this.recipientUid,
      recipientNickname: recipientNickname ?? this.recipientNickname,
      remoteSessionId: remoteSessionId ?? this.remoteSessionId,
      localChatSessionId: localChatSessionId ?? this.localChatSessionId,
      pendingCallRequest: pendingCallRequest ?? this.pendingCallRequest, // Keep if null passed? No, explicit null clears it.
    );
  }

  @override
  List<Object?> get props => [status, messages, recipientUid, recipientNickname, remoteSessionId, localChatSessionId, pendingCallRequest];
}

// Bloc
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  String? _currentRecipientUid;

  ChatBloc({required this.chatRepository}) : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<SendMessage>(_onSendMessage);
    on<CallResponseReceived>(_onCallResponseReceived);
    on<ReceiveMessage>(_onReceiveMessage);
    on<ReceiveCallRequest>(_onReceiveCallRequest); 
    on<ReceiveCallRemoteUser>(_onReceiveCallRemoteUser);
    on<AcceptIncomingCall>(_onAcceptIncomingCall);
    on<RejectIncomingCall>(_onRejectIncomingCall);
    on<PrivateChatLeft>(_onPrivateChatLeft);
    on<LeaveChat>(_onLeaveChat);

    chatRepository.incomingRemoteUserCalls.listen((message) {
         add(ReceiveCallRemoteUser(message));
    });

    chatRepository.incomingPrivateMessages.listen((message) {
      // Validate by Session ID (Primary) OR User ID (Fallback)
      // JChat messages arrive with LOCAL_SESSIONID = JChat's ID.
      // We stored JChat's ID in state.remoteSessionId.
      
      final matchesSession = state.status == ChatConnectionStatus.connected && 
                             state.remoteSessionId != null && 
                             state.remoteSessionId!.isNotEmpty &&
                             message.localSessionId == state.remoteSessionId;
                             
      final matchesUid = _currentRecipientUid != null && 
                         message.senderUid.isNotEmpty && 
                         message.senderUid == _currentRecipientUid;

      if (matchesSession || matchesUid) { 
          // Filter out our own messages (echoes)
          if (message.senderUid == chatRepository.myUserId) {
             print('ChatBloc: Ignored Echo from Self');
             return;
          }
          
          // If we matched by Session but UID was unknown/mismatch, update it now
          if (matchesSession && _currentRecipientUid != message.senderUid && message.senderUid.isNotEmpty) {
               print('ChatBloc: Updating Recipient UID from Message: ${message.senderUid}');
               _currentRecipientUid = message.senderUid;
               // We might want to emit a state update here to fix UI, but ReceiveMessage handler will add message mostly.
          }
          
          add(ReceiveMessage(message));
      } else if (message.senderUid == chatRepository.myUserId) {
          print('ChatBloc: Ignored Echo from Self (Global Check)');
      } else {
          print('ChatBloc: Ignored (Mismatch). Expected Session: ${state.remoteSessionId}, Msg Session: ${message.localSessionId}. Expected UID: $_currentRecipientUid, Msg UID: ${message.senderUid}');
      }
    });

    chatRepository.callPrivateChatResponses.listen((message) {
        add(CallResponseReceived(message));
    });
    
    // Listen for incoming call REQUESTS (Legacy/Other)
    chatRepository.incomingPrivateChatRequests.listen((message) {
         add(ReceiveCallRequest(message));
    });

    chatRepository.leavePrivateChatStream.listen((message) {
         add(PrivateChatLeft(message));
    });
  }

  void _onPrivateChatLeft(PrivateChatLeft event, Emitter<ChatState> emit) {
      print('ChatBloc: _onPrivateChatLeft. Gone: ${event.message.goneSessionId}, Current Remote: ${state.remoteSessionId}');
      
      if (state.remoteSessionId != null && event.message.goneSessionId == state.remoteSessionId) {
          print('ChatBloc: Connected Peer Left. Closing Chat.');
          emit(state.copyWith(status: ChatConnectionStatus.disconnected));
      }
  }

  void _onLeaveChat(LeaveChat event, Emitter<ChatState> emit) {
      if (state.status == ChatConnectionStatus.connected) {
           print('ChatBloc: Sending Manual Leave for Session: ${state.localChatSessionId}');
           // We must send the PEER'S session ID so the server routes the message to them.
           // The server will overwrite the payload's GONE_SESSIONID with OUR session ID,
           // which JChat will then match against its RemoteSessionId (Us).
           chatRepository.sendLeavePrivateChat(state.remoteSessionId ?? '');
           emit(state.copyWith(
              status: ChatConnectionStatus.disconnected,
              messages: [],
              remoteSessionId: '',
              localChatSessionId: '',
           ));
      }
  }

  void _onChatStarted(ChatStarted event, Emitter<ChatState> emit) {
    if (_currentRecipientUid == event.recipientUid && 
        state.remoteSessionId != null && 
        state.remoteSessionId!.isNotEmpty) {
        print('ChatBloc: ChatStarted for existing session. Skipping handshake.');
        return;
    }
  
    _currentRecipientUid = event.recipientUid;
    
    emit(state.copyWith(
        recipientUid: event.recipientUid,
        recipientNickname: event.recipientNickname,
        messages: [],
        remoteSessionId: null, // Reset
    ));

    chatRepository.callPrivateChat(event.recipientUid, event.recipientNickname); 
  }

  // --- Handling Incoming Calls ---

  void _onReceiveCallRemoteUser(ReceiveCallRemoteUser event, Emitter<ChatState> emit) {
       print('ChatBloc: Received CALLREMOTEUSER Header: ${event.message.header}. Nick: ${event.message.localNickname}');

       if (event.message.header == Header.CONFIRM) {
            // Outgoing Call Accepted by Peer
            // Based on Server Logic (DatabaseService.callRemoteUser) & JChat (JChat.java accept):
            // CONFIRM Message:
            // LOCAL_SESSIONID = My (Caller) Session ID
            // REMOTE_SESSIONID = Peer (Recipient) Session ID
            
            final myChatSessionId = event.message.localSessionId ?? ''; 
            final peerSessionId = event.message.remoteSessionId ?? '';
            
            print('ChatBloc: Outgoing Call Accepted. MyID: $myChatSessionId, PeerID: $peerSessionId');

            if (peerSessionId.isNotEmpty) {
                emit(state.copyWith(
                    status: ChatConnectionStatus.connected,
                    remoteSessionId: peerSessionId, // Send messages to THIS ID
                    localChatSessionId: myChatSessionId, // My ID
                    messages: [],
                    recipientUid: event.message.senderUid.isNotEmpty ? event.message.senderUid : _currentRecipientUid,
                    recipientNickname: event.message.localNickname
                ));
            }
            return;
       }

       // INCOMING REQUEST (Header.REQUEST)
       print('ChatBloc: Received Incoming Call Request from ${event.message.localNickname}');
       
       // Store info but DO NOT Accept yet. Wait for User.
       // Set Recipient Info so UI can show "Call from Bob"
       
       final callerUid = event.message.senderUid.isNotEmpty ? event.message.senderUid : 'UNKNOWN'; 
       final callerNick = event.message.localNickname; 
 
       _currentRecipientUid = callerUid;
 
       emit(state.copyWith(
          status: ChatConnectionStatus.incomingRequest, // Trigger UI Dialog
          recipientUid: callerUid,
          recipientNickname: callerNick,
          pendingCallRequest: event.message, // Store the request object
       ));
  }

  void _onAcceptIncomingCall(AcceptIncomingCall event, Emitter<ChatState> emit) {
      if (state.pendingCallRequest == null) return;
      
      print('ChatBloc: User Accepted Call.');
      
      final request = state.pendingCallRequest!;
      
      // Accept and send CONFIRM
      // Repository returns Our Session ID
      final localChatId = chatRepository.acceptCallRemoteUser(request);
      
      // Extract Peer Session ID (Remote)
      // Request Mapping: Local=My, Remote=Peer
      final remoteChatId = request.remoteSessionId ?? '';

      print('ChatBloc: Established Session. Local: $localChatId, Remote: $remoteChatId');

      emit(state.copyWith(
          status: ChatConnectionStatus.connected,
          remoteSessionId: remoteChatId, // JChat ID
          localChatSessionId: localChatId, // My ID
          messages: [],
          pendingCallRequest: null, // Clear pending
      ));
  }

  void _onRejectIncomingCall(RejectIncomingCall event, Emitter<ChatState> emit) {
       print('ChatBloc: User Rejected Call.');
       // Just reset state
       emit(state.copyWith(
           status: ChatConnectionStatus.initial,
           pendingCallRequest: null,
           recipientUid: null,
           recipientNickname: null
       ));
       _currentRecipientUid = null;
  }

  // -----------------------------

  void _onCallResponseReceived(CallResponseReceived event, Emitter<ChatState> emit) {
      // Server converts CALLREMOTEUSER(Confirm) -> CALLPRIVATECHAT(Confirm).
      // Mapping:
      // LocalSessionId = Caller (Flutter) WebSocket ID
      // RemoteSessionId = Recipient (JChat) WebSocket ID
      
      final myChatSessionId = event.message.localSessionId ?? ''; 
      final peerSessionId = event.message.remoteSessionId ?? ''; 
      
      print('ChatBloc: Received Call Response. Peer: $peerSessionId, My: $myChatSessionId');
      
      if (peerSessionId.isNotEmpty) {
           emit(state.copyWith(
             status: ChatConnectionStatus.connected, // Ensure status is updated
             remoteSessionId: peerSessionId, // Send to JChat
             localChatSessionId: myChatSessionId, // My ID
           ));
      }
  }

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) {
    if (_currentRecipientUid == null) return;
    
    // OPTIMISTIC UPDATE
    final myMsg = PrivateMessage(
        header: Header.REQUEST, 
        command: Command.PRIVATEMESSAGE,
        dataset: {
          'SENDER_UID': chatRepository.myUserId ?? 'ME', 
          'MESSAGE': event.message,
          'DATETIME': DateTime.now().millisecondsSinceEpoch
        }
    );
    
    emit(state.copyWith(messages: List.from(state.messages)..add(myMsg)));
    
    print('ChatBloc: Sending msg to ${state.remoteSessionId}');

    chatRepository.sendPrivateMessage(
        _currentRecipientUid!, 
        event.message,
        remoteSessionId: state.remoteSessionId, 
        localSessionId: state.localChatSessionId
    );
  }
  
  void _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) {
      // Filter out Receipts (Response/Confirm) to prevent duplicates/system messages appearing
      if (event.message.header == Header.RESPONSE || event.message.header == Header.CONFIRM) {
          return;
      }
      
      emit(state.copyWith(messages: List.from(state.messages)..add(event.message)));

      // Send Confirmation (RESPONSE) back to sender so they know we got it.
      if (event.message.header == Header.REQUEST) {
        final newDataset = Map<String, dynamic>.from(event.message.dataset);
        newDataset['SENDER_UID'] = chatRepository.myUserId; // Mark us as sender of receipt

        final confirmation = event.message.copyWith(
          header: Header.RESPONSE,
          dataset: newDataset,
        );
        // print('ChatBloc: Sending Receipt to ${event.message.localSessionId}');
        chatRepository.sendMessage(confirmation);
      }
  }

  void _onReceiveCallRequest(ReceiveCallRequest event, Emitter<ChatState> emit) {
      // Legacy / CALLPRIVATECHAT handling
      print('ChatBloc: Handling Legacy CALLPRIVATECHAT Request from ${event.message.localNickname}');
      
      // We can reuse the Manual Accept logic here if we map it to CallRemoteUser 
      // OR just implement it separately. 
      // For now, auto-accept this one (since user asked about "Incoming Call" usually meaning RemoteUser).
      // Or block it. Let's auto-accept for backward compat or just log.
      
      final peerUid = event.message.senderUid;
      final peerNickname = event.message.localNickname;
      final peerChatSessionId = event.message.localSessionId;

       _currentRecipientUid = peerUid;

      final localChatId = chatRepository.acceptPrivateChat(event.message);
      
      emit(state.copyWith(
          status: ChatConnectionStatus.connected,
          recipientUid: peerUid,
          recipientNickname: peerNickname,
          messages: [],
          remoteSessionId: peerChatSessionId, 
          localChatSessionId: localChatId,
      ));
  }
}
