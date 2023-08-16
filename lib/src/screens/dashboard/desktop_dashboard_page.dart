import 'dart:async';
import 'package:foss_wallet/entities/preferences_key.dart';
import 'package:foss_wallet/generated/i18n.dart';
import 'package:foss_wallet/routes.dart';
import 'package:foss_wallet/src/screens/release_notes/release_notes_screen.dart';
import 'package:foss_wallet/src/screens/yat_emoji_id.dart';
import 'package:foss_wallet/src/widgets/alert_with_one_action.dart';
import 'package:foss_wallet/utils/show_pop_up.dart';
import 'package:foss_wallet/utils/version_comparator.dart';
import 'package:flutter/material.dart';
import 'package:foss_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:foss_wallet/src/screens/dashboard/widgets/balance_page.dart';
import 'package:foss_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:mobx/mobx.dart';
import 'package:foss_wallet/main.dart';
import 'package:foss_wallet/router.dart' as Router;
import 'package:shared_preferences/shared_preferences.dart';

class DesktopDashboardPage extends StatelessWidget {
  DesktopDashboardPage({
    required this.balancePage,
    required this.dashboardViewModel,
    required this.addressListViewModel,
    required this.desktopKey,
  });

  final BalancePage balancePage;
  final DashboardViewModel dashboardViewModel;
  final WalletAddressListViewModel addressListViewModel;
  final GlobalKey<NavigatorState> desktopKey;

  bool _isEffectsInstalled = false;
  StreamSubscription<bool>? _onInactiveSub;

  @override
  Widget build(BuildContext context) {
    _setEffects(context);

    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 400,
            child: balancePage,
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Navigator(
                key: desktopKey,
                initialRoute: Routes.desktop_actions,
                onGenerateRoute: (settings) => Router.createRoute(settings),
                onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
                  return [
                    navigator.widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!
                  ];
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setEffects(BuildContext context) async {
    if (_isEffectsInstalled) {
      return;
    }
    _isEffectsInstalled = true;

    autorun((_) async {
      if (!dashboardViewModel.isOutdatedElectrumWallet) {
        return;
      }

      await Future<void>.delayed(Duration(seconds: 1));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.of(context).pre_seed_title,
                alertContent: S.of(context).outdated_electrum_wallet_description,
                buttonText: S.of(context).understand,
                buttonAction: () => Navigator.of(context).pop());
          });
    });

    var needToPresentYat = false;
    var isInactive = false;

    _onInactiveSub = rootKey.currentState!.isInactive.listen((inactive) {
      isInactive = inactive;

      if (needToPresentYat) {
        Future<void>.delayed(Duration(milliseconds: 500)).then((_) {
          showPopUp<void>(
              context: navigatorKey.currentContext!,
              builder: (_) => YatEmojiId(dashboardViewModel.yatStore.emoji));
          needToPresentYat = false;
        });
      }
    });

    dashboardViewModel.yatStore.emojiIncommingStream.listen((String emoji) {
      if (!_isEffectsInstalled || emoji.isEmpty) {
        return;
      }

      needToPresentYat = true;
    });

    final sharedPrefs = await SharedPreferences.getInstance();
    final currentAppVersion =
        VersionComparator.getExtendedVersionNumber(dashboardViewModel.settingsStore.appVersion);
    final lastSeenAppVersion = sharedPrefs.getInt(PreferencesKey.lastSeenAppVersion);
    final isNewInstall = sharedPrefs.getBool(PreferencesKey.isNewInstall);

    if (currentAppVersion != lastSeenAppVersion && !isNewInstall!) {
      await Future<void>.delayed(Duration(seconds: 1));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return ReleaseNotesScreen(
                title: 'Version ${dashboardViewModel.settingsStore.appVersion}');
          });
      sharedPrefs.setInt(PreferencesKey.lastSeenAppVersion, currentAppVersion);
    } else if (isNewInstall!) {
      sharedPrefs.setInt(PreferencesKey.lastSeenAppVersion, currentAppVersion);
    }
  }
}
