import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

import '../widgets/jchat_app_bar.dart';

class ChatPage extends StatefulWidget {
  final String recipientUid;
  final String recipientNickname;

  const ChatPage({
    super.key, 
    required this.recipientUid,
    required this.recipientNickname,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatStarted(
      recipientUid: widget.recipientUid,
      recipientNickname: widget.recipientNickname
    ));
    // Request focus slightly after build to ensure keyboard shows
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
     if (_textController.text.isNotEmpty) {
       context.read<ChatBloc>().add(SendMessage(_textController.text));
       _textController.clear();
       _focusNode.requestFocus(); // Keep focus after sending
     }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
         context.read<ChatBloc>().add(const LeaveChat());
         return true;
      },
      child: Scaffold(
      appBar: JChatAppBar(
        title: widget.recipientNickname,
        showRefresh: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocListener<ChatBloc, ChatState>(
              listener: (context, state) {
                print('ChatPage: State changed. Status: ${state.status}, Recipient: ${state.recipientUid}, RemoteSession: ${state.remoteSessionId}');
                
                if (state.status == ChatConnectionStatus.disconnected) {
                  print('ChatPage: Status is DISCONNECTED. Closing chat.');
                  final l10n = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.chatClosedMessage)),
                  );
                  
                  if (context.mounted) {
                      // Try standard Navigator first
                     if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                     } else {
                        context.go('/home');
                     }
                  }
                }
              },
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                return ListView.builder(
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    final isMe = msg.senderUid == 'ME' || msg.senderUid == context.read<ChatBloc>().chatRepository.myUserId;
                    
                    final colorScheme = Theme.of(context).colorScheme;
                    Color? containerColor;
                    Color? textColor;
                    
                    if (isMe) {
                       // My Colors (from AuthBloc via ChatRepo or direct)
                       // Since we updated ChatRepo, we can rely on it, OR just lookup AuthBloc
                       final authState = context.read<AuthBloc>().state;
                       if (authState is SignInSuccess) {
                          if (authState.backgroundColor != null) containerColor = Color(authState.backgroundColor!);
                          if (authState.foregroundColor != null) textColor = Color(authState.foregroundColor!);
                       }
                       // Fallback
                       containerColor ??= colorScheme.primaryContainer;
                       textColor ??= colorScheme.onPrimaryContainer;
                    } else {
                       // Peer Colors (from Message)
                       if (msg.senderBackgroundColor != null) containerColor = Color(msg.senderBackgroundColor!);
                       if (msg.senderForegroundColor != null) textColor = Color(msg.senderForegroundColor!);
                       
                       // Fallback
                       containerColor ??= colorScheme.secondaryContainer;
                       textColor ??= colorScheme.onSecondaryContainer;
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)), // Subtle border
                        ),
                        child: Text(
                           msg.messageContent,
                           style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(hintText: AppLocalizations.of(context)!.typeMessageHint),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    ));
  }
}
