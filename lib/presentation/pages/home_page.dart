import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/user_list_bloc.dart';
import '../../core/debug/global_debug.dart';
import '../../data/models/protocol/call_remote_user.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Request users on load
    context.read<UserListBloc>().add(LoadUserList());

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (previous, current) {
         // Only trigger listener if status CHANGED or critical data arrived
         return previous.status != current.status;
      },
      listener: (context, state) {
        if (state.status == ChatConnectionStatus.connected && state.localChatSessionId != null) {
             print('HomePage: Session Established. Navigating to Chat.');
             context.push('/chat', extra: {
               'uid': state.recipientUid,
               'nick': state.recipientNickname
             });
        } else if (state.status == ChatConnectionStatus.incomingRequest && state.pendingCallRequest != null) {
             print('HomePage: Showing Incoming Call Dialog');
             _showIncomingCallDialog(context, state.pendingCallRequest!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Online Users'),
          actions: [
             IconButton(
               icon: const Icon(Icons.refresh),
               onPressed: () => context.read<UserListBloc>().add(LoadUserList()),
             ),
          ],
        ),
        body: BlocBuilder<UserListBloc, UserListState>(
          builder: (context, state) {
            return Column(
               children: [
                 Expanded(
                   child: _buildList(state, context),
                 ),
                 Container(
                   height: 150,
                   color: Colors.black87,
                   child: ValueListenableBuilder<String>(
                     valueListenable: GlobalDebug.log,
                     builder: (ctx, val, _) => SingleChildScrollView(
                       reverse: true,
                       child: Text(val, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                     ),
                   )
                 )
               ]
            );
          },
        ),
      ),
    );
  }

  void _showIncomingCallDialog(BuildContext context, CallRemoteUser request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
         return AlertDialog(
            title: const Text("Incoming Chat Request"),
            content: Text("Incoming call from ${request.localNickname} (${request.senderUid})"),
            actions: [
               TextButton(
                  onPressed: () {
                     Navigator.of(ctx).pop(); // Close dialog
                     context.read<ChatBloc>().add(RejectIncomingCall());
                  },
                  child: const Text("Reject"),
               ),
               TextButton(
                  onPressed: () {
                     Navigator.of(ctx).pop(); // Close dialog
                     context.read<ChatBloc>().add(AcceptIncomingCall());
                  },
                  child: const Text("Accept"),
               ),
            ],
         );
      }
    );
  }

  Widget _buildList(UserListState state, BuildContext context) {
           if (state is UserListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserListError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is UserListLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('No users online.'));
            }
            return ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.nickname.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(user.nickname),
                  subtitle: Text(user.userid),
                  trailing: const Icon(Icons.chat),
                  onTap: () {
                     // Check existing chat?
                     context.read<ChatBloc>().add(
                        ChatStarted(
                           recipientUid: user.userid, 
                           recipientNickname: user.nickname
                        )
                     );
                     
                     // Navigate immediately? Or wait for connection?
                     // Wait for connection (handled by listener up top).
                     // But we show a loading indicator?
                     
                     // For now, push immediately so we see the chat screen waiting.
                     context.push('/chat', extra: {
                       'uid': user.userid,
                       'nick': user.nickname,
                     });
                  },
                );
              },
            );
          }
          return const Center(child: Text('Welcome!'));
  }
}
