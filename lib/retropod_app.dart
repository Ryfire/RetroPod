import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/services/audio_files_service.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/l10n/generated/app_localizations.dart';

class RetropodApp extends ConsumerStatefulWidget {
  const RetropodApp({super.key});

  @override
  ConsumerState<RetropodApp> createState() => _RetropodAppState();
}

class _RetropodAppState extends ConsumerState<RetropodApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Sync the library against the media store so files added or removed
      // while the app was backgrounded are reflected without a restart.
      // The notifier no-ops when the library is not initialized yet.
      unawaited(
        ref.read(audioFilesServiceProvider.notifier).refreshOnAppResume(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageLocaleCode = ref.watch(
      settingsPreferencesControllerProvider.select(
        (value) => value.languageLocaleCode,
      ),
    );
    final appTheme = ref.watch(
      settingsPreferencesControllerProvider.select((value) => value.appTheme),
    );
    final router = ref.watch(routerProvider);
    return CupertinoApp.router(
      onGenerateTitle: (context) => context.localization.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: Locale(languageLocaleCode),
      theme: appTheme.toCupertinoTheme(),
    );
  }
}
