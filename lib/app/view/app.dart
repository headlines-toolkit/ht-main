//
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart'; // For dynamic links
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_kv_storage_service/ht_kv_storage_service.dart'; // Import storage service
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart'; // Import AuthBloc
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/router.dart';

class App extends StatelessWidget {
  const App({
    required HtHeadlinesRepository htHeadlinesRepository,
    required HtAuthenticationRepository htAuthenticationRepository,
    required HtKVStorageService kvStorageService,
    super.key,
  }) : _htHeadlinesRepository = htHeadlinesRepository,
       _htAuthenticationRepository = htAuthenticationRepository,
       _kvStorageService = kvStorageService;

  final HtHeadlinesRepository _htHeadlinesRepository;
  final HtAuthenticationRepository _htAuthenticationRepository;
  final HtKVStorageService _kvStorageService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _htHeadlinesRepository),
        RepositoryProvider.value(value: _htAuthenticationRepository),
        RepositoryProvider.value(value: _kvStorageService),
      ],
      // Use MultiBlocProvider to provide both AppBloc and AuthenticationBloc
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => AppBloc(
                  authenticationRepository:
                      context.read<HtAuthenticationRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => AuthenticationBloc(
                  authenticationRepository:
                      context.read<HtAuthenticationRepository>(),
                ),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Store the router and the status notifier
  late final GoRouter _router;
  late final ValueNotifier<AppStatus> _statusNotifier;
  StreamSubscription<PendingDynamicLinkData>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    // Get the AppBloc instance from the BlocProvider above
    final appBloc = context.read<AppBloc>();

    // Create the ValueNotifier, initialized with the current status
    _statusNotifier = ValueNotifier<AppStatus>(appBloc.state.status);

    // Create the router instance, passing the ValueNotifier as the listenable
    _router = createRouter(authStatusNotifier: _statusNotifier);

    // --- Initialize Deep Link Handling ---
    _initDynamicLinks();
    // ------------------------------------
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _statusNotifier.dispose();
    super.dispose();
  }

  /// Initializes Firebase Dynamic Links listeners.
  Future<void> _initDynamicLinks() async {
    // Handle links received while the app is running
    _linkSubscription = FirebaseDynamicLinks.instance.onLink.listen(
      (pendingDynamicLinkData) {
        // Handle link data
        _handleDynamicLink(pendingDynamicLinkData.link);
      },
      onError: (Object error) {
        // Handle errors (e.g., log them)
        debugPrint('Dynamic Link Listener Error: $error');
      },
    );

    // Handle initial link that opened the app
    try {
      final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        await _handleDynamicLink(initialLink.link);
      }
    } catch (e) {
      debugPrint('Error getting initial dynamic link: $e');
      // Handle potential errors during initial link retrieval
    }
  }

  /// Processes a received dynamic link URI.
  Future<void> _handleDynamicLink(Uri deepLink) async {
    // Read BLoC and Repo before the first await.
    // The mounted check should ideally happen *before* accessing context.
    if (!mounted) return;
    final authRepo = context.read<HtAuthenticationRepository>();
    // Store the BLoC instance in a local variable BEFORE the await
    final authBloc = context.read<AuthenticationBloc>();
    final linkString = deepLink.toString();

    debugPrint('Handling dynamic link: $linkString'); // Log received link

    try {
      // The async gap happens here
      final isSignInLink = await authRepo.isSignInWithEmailLink(
        emailLink: linkString,
      );
      debugPrint('Is sign-in link: $isSignInLink'); // Log validation result

      // Check mounted again *after* the await before using BLoC/state
      if (!mounted) return;

      if (isSignInLink) {
        // Use the local variable 'authBloc' instead of context.read again
        authBloc.add(
          AuthenticationSignInWithLinkAttempted(emailLink: linkString),
        );
        debugPrint(
          'Dispatched AuthenticationSignInWithLinkAttempted',
        ); // Log dispatch
      } else {
        // Handle other types of deep links if necessary
        debugPrint(
          'Received deep link is not an email sign-in link: $linkString',
        );
      }
    } catch (e, st) {
      // Catch potential errors during validation/dispatch
      debugPrint('Error handling dynamic link: $e\n$st');
      // Optionally show a generic error message to the user via
      // a SnackBar or Dialog:
      //
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error processing link: $e')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the part of the tree that needs to react to AppBloc state changes
    // (specifically for updating the ValueNotifier) with a BlocListener.
    // The BlocBuilder remains for theme changes.
    return BlocListener<AppBloc, AppState>(
      // Only listen when the status actually changes
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        // Update the ValueNotifier when the AppBloc status changes.
        // This triggers the GoRouter's refreshListenable.
        _statusNotifier.value = state.status;
      },
      child: BlocBuilder<AppBloc, AppState>(
        buildWhen:
            (previous, current) => previous.themeMode != current.themeMode,
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: lightTheme(),
            darkTheme: darkTheme(),
            routerConfig: _router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}

ThemeData lightTheme() {
  return FlexThemeData.light(
    scheme: FlexScheme.material,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}

ThemeData darkTheme() {
  return FlexThemeData.dark(
    scheme: FlexScheme.material,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}
