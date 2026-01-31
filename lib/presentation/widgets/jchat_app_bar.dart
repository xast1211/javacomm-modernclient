
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme/theme_cubit.dart';
import '../../core/theme/app_theme.dart'; // Ensure AppThemeType is available if not exported by cubit
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/user_list_bloc.dart';

class JChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showRefresh;

  const JChatAppBar({
    super.key, 
    required this.title,
    this.showRefresh = false,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to get nickname from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    String? myNickname;
    if (authState is SignInSuccess) {
      myNickname = authState.nickname;
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title),
          if (myNickname != null)
            Text(
              myNickname,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
          // Theme Menu
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return PopupMenuButton<AppThemeType>(
                icon: const Icon(Icons.style),
                tooltip: 'Farbschema', // Localize later if needed
                onSelected: (AppThemeType result) {
                  context.read<ThemeCubit>().changeTheme(result);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<AppThemeType>>[
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.mokka,
                    checked: themeState.type == AppThemeType.mokka,
                    child: const Text('Mokka'),
                  ),
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.vanille,
                    checked: themeState.type == AppThemeType.vanille,
                    child: const Text('Vanille'),
                  ),
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.joghurt,
                    checked: themeState.type == AppThemeType.joghurt,
                    child: const Text('Joghurt'),
                  ),
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.blaubeere,
                    checked: themeState.type == AppThemeType.blaubeere,
                    child: const Text('Blaubeere'),
                  ),
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.erdbeere,
                    checked: themeState.type == AppThemeType.erdbeere,
                    child: const Text('Erdbeere'),
                  ),
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.zitrone,
                    checked: themeState.type == AppThemeType.zitrone,
                    child: const Text('Zitrone'),
                  ),
                  const PopupMenuDivider(),
                  CheckedPopupMenuItem<AppThemeType>(
                    value: AppThemeType.system,
                    checked: themeState.type == AppThemeType.system,
                    child: const Text('System Standard'),
                  ),
                ],
              );
            },
          ),
          
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),

          // Refresh (Only if requested, e.g. on HomePage)
          if (showRefresh)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<UserListBloc>().add(LoadUserList()),
            ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
