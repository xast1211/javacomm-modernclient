
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme/theme_cubit.dart';
import '../../core/theme/language_cubit.dart';
import '../../core/theme/app_theme.dart'; // Ensure AppThemeType is available if not exported by cubit
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart'; // Add import
import '../bloc/user_list_bloc.dart';

class JChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showRefresh;
  final bool useProfileAsTitle;

  const JChatAppBar({
    super.key, 
    required this.title,
    this.showRefresh = false,
    this.useProfileAsTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to get nickname from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    String? myNickname;
    if (authState is SignInSuccess) {
      myNickname = authState.nickname;
    }

    Widget titleWidget;
    bool centerTitle;

    PreferredSizeWidget? bottomWidget;

    if (useProfileAsTitle) {
      centerTitle = true; // Use center to ensure standard layout, but we might force left for nick
      final l10n = AppLocalizations.of(context)!;
      final nickText = '${myNickname ?? title} ${l10n.loggedInStatus}';
      final centerText = l10n.appTitle; // "1:1 Privatgespräch"

      // Title is just the nickname, standard style
      titleWidget = Text(
        nickText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
        ),
      );
      centerTitle = false; // Keep nickname to the left

      // Bottom widget for "1:1 Privatgespräch"
      bottomWidget = PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 6.0),
          alignment: Alignment.center,
          child: Text(
            centerText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

    } else {
      centerTitle = true;
      final l10n = AppLocalizations.of(context)!;
      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Chatpartner: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (myNickname != null)
            Text(
               'Ich: $myNickname',
               style: Theme.of(context).textTheme.labelMedium?.copyWith(
                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
               ),
            ),
        ],
      );
    }

    return AppBar(
      title: titleWidget,
      centerTitle: centerTitle,
      bottom: bottomWidget,
      actions: [
          // Theme Menu
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return PopupMenuButton<AppThemeType>(
                icon: const Icon(Icons.style),
                tooltip: AppLocalizations.of(context)!.themeTooltip,
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
                ],
              );
            },
          ),
          
          // Language Menu
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                tooltip: AppLocalizations.of(context)!.languageTooltip,
                onSelected: (Locale result) {
                  context.read<LanguageCubit>().changeLanguage(result);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                  CheckedPopupMenuItem<Locale>(
                    value: const Locale('de'),
                    checked: locale.languageCode == 'de',
                    child: Text(AppLocalizations.of(context)!.languageDeutsch),
                  ),
                  CheckedPopupMenuItem<Locale>(
                    value: const Locale('en'),
                    checked: locale.languageCode == 'en',
                    child: Text(AppLocalizations.of(context)!.languageEnglish),
                  ),
                  CheckedPopupMenuItem<Locale>(
                    value: const Locale('es'),
                    checked: locale.languageCode == 'es',
                    child: Text(AppLocalizations.of(context)!.languageEspanol),
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

          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppLocalizations.of(context)!.logoutButton,
            onPressed: () {
               context.read<AuthBloc>().add(const LogoutRequested());
            },
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
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (useProfileAsTitle ? 30.0 : 0.0));
}
