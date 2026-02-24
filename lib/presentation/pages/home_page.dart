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
             _showIncomingCallDialog(context, state.pendingCallRequest!, state.recipientNickname ?? '');
        }
      },
      child: Scaffold(
        appBar: JChatAppBar(
          title: AppLocalizations.of(context)!.onlineUsersTitle,
          showRefresh: false,
          useProfileAsTitle: true,
        ),
        body: BlocBuilder<UserListBloc, UserListState>(
          builder: (context, state) {
            return Column(
               children: [
                 Expanded(
                   child: _buildList(state, context),
                 ),
               ]
            );
          },
        ),
      ),
    );
  }

  void _showIncomingCallDialog(BuildContext context, CallRemoteUser request, String resolvedCallerName) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
          final callerName = resolvedCallerName.isNotEmpty ? resolvedCallerName : request.localNickname;
          return AlertDialog(
             title: Text(l10n.incomingChatRequestTitle),
             content: Text(l10n.incomingCallFrom(callerName, request.senderUid)),
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
                
                return BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, chatState) {
                    Widget trailingWidget;
                    
                    print('HomePage UI: User ${user.nickname}, outgoingRequestUid=${chatState.outgoingRequestUid}, status=${chatState.outgoingRequestStatus}');
                    
                    if (chatState.outgoingRequestUid == user.userid) {
                       final l10n = AppLocalizations.of(context)!;
                       switch (chatState.outgoingRequestStatus) {
                          case OutgoingRequestStatus.pending:
                            trailingWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.chatRequestPending, style: const TextStyle(color: Colors.grey)),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  tooltip: l10n.cancelButtonText,
                                  onPressed: () => context.read<ChatBloc>().add(CancelOutgoingRequest()),
                                )
                              ],
                            );
                            break;
                          case OutgoingRequestStatus.rejected:
                            trailingWidget = Text(l10n.chatRequestDeclined, style: const TextStyle(color: Colors.red));
                            break;
                          case OutgoingRequestStatus.busy:
                            // Check Agent: Show only for Browser/SmartPhone.
                            // The protocol expects strings like "Browser", "Desktop", "Android", "Web"
                            final agentStr = user.agent?.toString() ?? '';
                            if (agentStr.contains('Browser') || agentStr.contains('Android') || agentStr.contains('iOS') || agentStr.contains('SmartPhone') || agentStr.contains('Web')) {
                                trailingWidget = Text(l10n.chatRequestBusy, style: const TextStyle(color: Colors.orange));
                            } else {
                                trailingWidget = const SizedBox.shrink(); // Fallback if agent doesn't support busy indicator in this way
                            }
                            break;
                          default:
                            trailingWidget = IconButton(
                               icon: const Icon(Icons.chat),
                               onPressed: () {
                                  context.read<ChatBloc>().add(
                                     ChatStarted(
                                        recipientUid: user.userid, 
                                        recipientNickname: user.nickname
                                     )
                                  );
                               }
                            );
                       }
                    } else {
                        trailingWidget = IconButton(
                           icon: const Icon(Icons.chat),
                           onPressed: () {
                              context.read<ChatBloc>().add(
                                 ChatStarted(
                                    recipientUid: user.userid, 
                                    recipientNickname: user.nickname
                                 )
                              );
                           }
                        );
                    }

                    return ListTile(
                      title: Text(user.nickname),
                      trailing: trailingWidget,
                      onTap: () {
                         if (chatState.outgoingRequestUid == user.userid && 
                            (chatState.outgoingRequestStatus == OutgoingRequestStatus.pending || 
                             chatState.outgoingRequestStatus == OutgoingRequestStatus.busy)) {
                            // Do nothing if already pending or busy
                            return;
                         }
                         
                         context.read<ChatBloc>().add(
                            ChatStarted(
                               recipientUid: user.userid, 
                               recipientNickname: user.nickname
                            )
                         );
                      },
                    );
                  }
                );
              },
            );
          }
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.welcomeMessage));
  }
}
