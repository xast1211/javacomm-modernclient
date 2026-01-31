import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/user_list_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/debug/global_debug.dart';
import '../../data/models/protocol/call_remote_user.dart';
import '../../core/theme/theme_cubit.dart';

import '../widgets/jchat_app_bar.dart';

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
        appBar: JChatAppBar(
          title: AppLocalizations.of(context)!.onlineUsersTitle,
          showRefresh: false,
        ),
        body: BlocBuilder<UserListBloc, UserListState>(
          builder: (context, state) {
            return Column(
               children: [
                 Expanded(
                   child: _buildList(state, context),
                 ),
                 // Container(
                 //   height: 150,
                 //   color: Colors.black87,
                 //   child: ValueListenableBuilder<String>(
                 //     valueListenable: GlobalDebug.log,
                 //     builder: (ctx, val, _) => SingleChildScrollView(
                 //       reverse: true,
                 //       child: Text(val, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                 //     ),
                 //   )
                 // )
               ]
            );
          },
        ),
      ),
    );
  }

  void _showIncomingCallDialog(BuildContext context, CallRemoteUser request) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
         return AlertDialog(
            title: Text(l10n.incomingChatRequestTitle),
            content: Text(l10n.incomingCallFrom.replaceAll('{nickname}', request.localNickname).replaceAll('{userid}', request.senderUid)),
            actions: [
               TextButton(
                  onPressed: () {
                     Navigator.of(ctx).pop(); // Close dialog
                     context.read<ChatBloc>().add(RejectIncomingCall());
                  },
                  child: Text(l10n.rejectButton),
               ),
               TextButton(
                  onPressed: () {
                     Navigator.of(ctx).pop(); // Close dialog
                     context.read<ChatBloc>().add(AcceptIncomingCall());
                  },
                  child: Text(l10n.acceptButton),
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
            final l10n = AppLocalizations.of(context)!;
            return Center(child: Text(l10n.errorPrefix.replaceAll('{message}', state.message)));
          } else if (state is UserListLoaded) {
            if (state.users.isEmpty) {
              return Center(child: Text(AppLocalizations.of(context)!.noUsersOnline));
            }
            return ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return ListTile(
                  // leading: CircleAvatar(
                  //   child: Text(user.nickname.substring(0, 1).toUpperCase()),
                  // ),
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
                     // context.push('/chat', extra: {
                     //   'uid': user.userid,
                     //   'nick': user.nickname,
                     // });
                  },
                );
              },
            );
          }
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.welcomeMessage));
  }
}
