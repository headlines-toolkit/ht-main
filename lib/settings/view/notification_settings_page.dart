import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
// import 'package:ht_main/router/routes.dart'; // For future navigation

/// {@template notification_settings_page}
/// A page for configuring notification settings.
/// {@endtemplate}
class NotificationSettingsPage extends StatelessWidget {
  /// {@macro notification_settings_page}
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // SettingsBloc is provided by the parent route.
    return const _NotificationSettingsView();
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    // Ensure we have loaded state before building controls
    if (state.status != SettingsStatus.success) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsNotificationsTitle)), // Reuse title
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool notificationsEnabled = state.notificationSettings.enabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsNotificationsTitle), // Reuse title
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- Enable/Disable Notifications ---
          SwitchListTile(
            title: Text(l10n.settingsNotificationsEnableLabel), // Add l10n key
            value: notificationsEnabled,
            onChanged: (bool value) {
              settingsBloc.add(SettingsNotificationsEnabledChanged(value));
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          const Divider(),

          // --- Detailed Notification Settings (Conditional) ---
          // Only show these if notifications are enabled
          if (notificationsEnabled) ...[
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l10n.settingsNotificationsCategoriesLabel), // Add l10n key
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO(cline): Implement navigation to category selection page
                // Example: context.goNamed(Routes.settingsNotificationCategoriesName);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category selection TBD')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.source_outlined),
              title: Text(l10n.settingsNotificationsSourcesLabel), // Add l10n key
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO(cline): Implement navigation to source selection page
                // Example: context.goNamed(Routes.settingsNotificationSourcesName);
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Source selection TBD')),
                );
             },
            ),
            ListTile(
              leading: const Icon(Icons.public_outlined),
              title: Text(l10n.settingsNotificationsCountriesLabel), // Add l10n key
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO(cline): Implement navigation to country selection page
                // Example: context.goNamed(Routes.settingsNotificationCountriesName);
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Country selection TBD')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
