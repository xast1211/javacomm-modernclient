import '../../data/models/protocol/chat_models.dart';
import '../../data/models/protocol/call_remote_user.dart';

abstract class ChatRepository {
  Stream<List<UserOnline>> get onlineUsers;
  List<UserOnline> get lastUsers;
  Stream<PrivateMessage> get incomingPrivateMessages;
  Stream<CallPrivateChat> get incomingPrivateChatRequests;
  Stream<CallRemoteUser> get incomingRemoteUserCalls;
  Stream<CallPrivateChat> get callPrivateChatResponses;
  Stream<LeavePrivateChat> get leavePrivateChatStream;
  
  String? get myUserId;
  String? get mySessionId;

  void requestOnlineUsers();
  void callPrivateChat(String recipientUid, String recipientNickname);
  Future<void> sendPrivateMessage(String recipientUid, String message, {String? remoteSessionId, String? localSessionId});
  Future<void> sendLeavePrivateChat(String goneSessionId);
  String acceptPrivateChat(CallPrivateChat request);
  String acceptCallRemoteUser(CallRemoteUser request);
  void initializeUser(String userId, String nickname, {String? sessionId, int? foregroundColor, int? backgroundColor});
  void sendMessage(PrivateMessage message);
}
