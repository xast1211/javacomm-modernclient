
import 'package:uuid/uuid.dart';

import 'enums.dart';
import 'message.dart';
import 'chat_models.dart';
import 'call_remote_user.dart';
import 'usrlogin.dart';
import 'update_user.dart';

/// Central factory for creating WebSocket request messages.
/// Ensures consistent use of Headers, Commands, and Parameter keys.
class ProtocolRequestFactory {
  
  // --- AUTHENTICATION ---

  static UsrLogin createLoginRequest({
    required String agent,
    required String encryptedIdentity,
  }) {
    return UsrLogin(
      header: Header.REQUEST,
      command: Command.USRLOGIN, // Enums.dart must have this
      dataset: {
        'AGENT': agent,
        'IDENTITY': encryptedIdentity,
      },
    );
  }

  static UpdateUser createUpdateUserRequest({
    required String encryptedIdentity,
    String? nickname,
    int? foregroundColor,
    int? backgroundColor,
    String? language,
  }) {
    return UpdateUser(
      dataset: UpdateUserDataset(
        identity: encryptedIdentity,
        nickname: nickname,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        language: language,
      ),
      header: Header.REQUEST,
      command: Command.UPDATEUSER,
    );
  }

  // --- CHAT & ONLINE STATUS ---

  // --- MESSAGING ---

  static PrivateMessage createPrivateMessageRequest({
    required String senderUid,
    required String messageContent,
    required int timestamp,
    required String remoteSessionId,
    String? localSessionId,
    // ChatUser details for the dataset
    required String senderNickname,
    int? senderFgColor,
    int? senderBgColor,
  }) {
    return PrivateMessage(
      header: Header.REQUEST,
      command: Command.PRIVATEMESSAGE,
      dataset: {
        'SENDER_UID': senderUid,
        'MESSAGE': messageContent,
        'DATETIME': timestamp,
        'CHATUSER': {
           'USERID': senderUid,
           'NICKNAME': senderNickname,
           'FOREGROUND_COLOR': senderFgColor ?? 0xFF000000,
           'BACKGROUND_COLOR': senderBgColor ?? 0xFFFFFFFF,
        },
        'LOCAL_SESSIONID': localSessionId ?? '',
        'REMOTE_SESSIONID': remoteSessionId,
      }
    );
  }
  
  static PrivateMessage createMessageReceipt({
    required PrivateMessage originalMessage,
    required String currentUserId,
  }) {
      final newDataset = Map<String, dynamic>.from(originalMessage.dataset);
      newDataset['SENDER_UID'] = currentUserId; 

      return originalMessage.copyWith(
        header: Header.RESPONSE, // Receipt
        dataset: newDataset,
      );
  }

  // --- CALLING (Handshake) ---

  /// Initiates a private chat (Legacy/JChat style often uses CallPrivateChat)
  /// But we found `CALLPRIVATECHAT` is used.
  /// Note: The original implementation generated a UUID for localSessionId here.
  static CallPrivateChat createCallPrivateChatRequest({
    required String senderUid,
    required String senderNickname,
    required String recipientUid,
    required String recipientNickname,
  }) {
    final sessionId = const Uuid().v4();
    
    return CallPrivateChat(
      header: Header.REQUEST,
      command: Command.CALLPRIVATECHAT,
      dataset: {
        'SENDER_UID': senderUid,
        'RECIPIENT_UID': recipientUid,
        'LOCAL_NICKNAME': senderNickname,
        'LOCAL_SESSIONID': sessionId, 
        'REMOTE_NICKNAME': recipientNickname,
        'REMOTE_SESSIONID': null, 
      },
    );
  }

  /// Accepts an incoming CallPrivateChat request
  static CallPrivateChat createCallPrivateChatConfirm({
    required String senderUid, // My ID
    required String senderNickname, // My Nick
    required String recipientUid, // Caller ID
    required String recipientNickname, // Caller Nick
    required String remoteSessionId, // Caller's Session ID
  }) {
     final localChatId = const Uuid().v4();

     return CallPrivateChat(
      header: Header.CONFIRM,
      command: Command.CALLPRIVATECHAT,
      dataset: {
        'SENDER_UID': senderUid,
        'RECIPIENT_UID': recipientUid,
        'LOCAL_NICKNAME': senderNickname,
        'REMOTE_NICKNAME': recipientNickname,
        'LOCAL_SESSIONID': localChatId, 
        'REMOTE_SESSIONID': remoteSessionId,
      }
    );
  }

  // --- REMOTE USER CALLS (Newer Protocol?) ---
  
  static CallRemoteUser createCallRemoteUserConfirm({
     required String myNickname,
     required String mySessionId, // My WebSocket Session ID (Local)
     required String peerNickname, 
     required String peerSessionId, // Peer's WebSocket Session ID (Remote)
  }) {
    // Logic from ChatRepositoryImpl.acceptCallRemoteUser:
    // 'LOCAL_SESSIONID': peerSessionId, // Set Local to Peer (Caller) to route response to them
    // 'REMOTE_SESSIONID': mySessionId, // Set Remote to Me (Callee)
    
     return CallRemoteUser(
      header: Header.CONFIRM,
      command: Command.CALLREMOTEUSER,
      dataset: {
        'LOCAL_NICKNAME': myNickname, 
        'LOCAL_SESSIONID': peerSessionId, 
        'REMOTE_NICKNAME': peerNickname, 
        'REMOTE_SESSIONID': mySessionId, 
      }
    );
  }

  static CallRemoteUser createCallRemoteUserReject({
     required String myNickname,
     required String mySessionId,
     required String peerNickname,
     required String peerSessionId,
  }) {
     // Rejection also swaps IDs to route back to caller
     return CallRemoteUser(
      header: Header.RESPONSE, // RESPONSE = Reject
      command: Command.CALLREMOTEUSER,
      dataset: {
        'LOCAL_NICKNAME': myNickname, 
        'LOCAL_SESSIONID': peerSessionId, 
        'REMOTE_NICKNAME': peerNickname, 
        'REMOTE_SESSIONID': mySessionId, 
      }
    );
  }

  static LeavePrivateChat createLeavePrivateChatRequest({
    required String goneSessionId,
  }) {
      return LeavePrivateChat(
        header: Header.REQUEST,
        command: Command.LEAVEPRIVATECHAT,
        dataset: {
           'GONE_SESSIONID': goneSessionId
        }
      );
  }
}
