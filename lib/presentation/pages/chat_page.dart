import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/chat_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatStarted(
      recipientUid: widget.recipientUid,
      recipientNickname: widget.recipientNickname
    ));
  }

  void _sendMessage() {
     if (_textController.text.isNotEmpty) {
       context.read<ChatBloc>().add(SendMessage(_textController.text));
       _textController.clear();
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
      appBar: AppBar(title: Text(widget.recipientNickname)),
      body: Column(
        children: [
          Expanded(
            child: BlocListener<ChatBloc, ChatState>(
              listener: (context, state) {
                print('ChatPage: State changed. Status: ${state.status}, Recipient: ${state.recipientUid}, RemoteSession: ${state.remoteSessionId}');
                
                if (state.status == ChatConnectionStatus.disconnected) {
                  print('ChatPage: Status is DISCONNECTED. Closing chat.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat closed (Peer left or connection lost)')),
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
                    final containerColor = isMe ? colorScheme.primaryContainer : colorScheme.secondaryContainer;
                    final textColor = isMe ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer;

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
                        ),
                        child: Text(
                           msg.messageContent,
                           style: TextStyle(color: textColor),
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
                    decoration: const InputDecoration(hintText: 'Type a message'),
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
