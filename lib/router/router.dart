import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart'; // Auth Repository
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/account/view/account_page.dart';
import 'package:ht_main/account/view/manage_followed_items/categories/add_category_to_follow_page.dart'; // New
import 'package:ht_main/account/view/manage_followed_items/categories/followed_categories_list_page.dart'; // New
// import 'package:ht_main/account/view/manage_followed_items/countries/add_country_to_follow_page.dart'; // Removed
// import 'package:ht_main/account/view/manage_followed_items/countries/followed_countries_list_page.dart'; // Removed
import 'package:ht_main/account/view/manage_followed_items/manage_followed_items_page.dart'; // New
import 'package:ht_main/account/view/manage_followed_items/sources/add_source_to_follow_page.dart'; // New
import 'package:ht_main/account/view/manage_followed_items/sources/followed_sources_list_page.dart'; // New
import 'package:ht_main/account/view/saved_headlines_page.dart'; // Import SavedHeadlinesPage
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/app/view/app_shell.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/authentication/view/authentication_page.dart';
import 'package:ht_main/authentication/view/email_code_verification_page.dart';
import 'package:ht_main/authentication/view/request_code_page.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Added
import 'package:ht_main/headline-details/bloc/headline_details_bloc.dart'; // Re-added
import 'package:ht_main/headline-details/bloc/similar_headlines_bloc.dart'; // Import SimilarHeadlinesBloc
import 'package:ht_main/headline-details/view/headline_details_page.dart';
import 'package:ht_main/headlines-feed/bloc/categories_filter_bloc.dart'; // Import new BLoC
// import 'package:ht_main/headlines-feed/bloc/countries_filter_bloc.dart'; // Import new BLoC - REMOVED
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/bloc/sources_filter_bloc.dart'; // Import new BLoC
import 'package:ht_main/headlines-feed/view/category_filter_page.dart';
// import 'package:ht_main/headlines-feed/view/country_filter_page.dart'; // REMOVED
import 'package:ht_main/headlines-feed/view/headlines_feed_page.dart';
import 'package:ht_main/headlines-feed/view/headlines_filter_page.dart';
import 'package:ht_main/headlines-feed/view/source_filter_page.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/headlines-search/view/headlines_search_page.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart'; // Added
import 'package:ht_main/settings/view/appearance_settings_page.dart'; // Added
import 'package:ht_main/settings/view/feed_settings_page.dart'; // Added
import 'package:ht_main/settings/view/font_settings_page.dart'; // Added for new page
import 'package:ht_main/settings/view/language_settings_page.dart'; // Added for new page
import 'package:ht_main/settings/view/notification_settings_page.dart'; // Added
import 'package:ht_main/settings/view/settings_page.dart'; // Added
import 'package:ht_main/settings/view/theme_settings_page.dart'; // Added for new page
import 'package:ht_shared/ht_shared.dart'; // Shared models, FromJson, ToJson, etc.

/// Creates and configures the GoRouter instance for the application.
///
/// Requires an [authStatusNotifier] to trigger route re-evaluation when
/// authentication state changes.
GoRouter createRouter({
  required ValueNotifier<AppStatus> authStatusNotifier,
  required HtAuthRepository htAuthenticationRepository,
  required HtDataRepository<Headline> htHeadlinesRepository,
  required HtDataRepository<Category> htCategoriesRepository,
  required HtDataRepository<Country> htCountriesRepository,
  required HtDataRepository<Source> htSourcesRepository,
  required HtDataRepository<UserAppSettings> htUserAppSettingsRepository,
  required HtDataRepository<UserContentPreferences>
  htUserContentPreferencesRepository,
  required HtDataRepository<AppConfig> htAppConfigRepository,
}) {
  // Instantiate AccountBloc once to be shared
  final accountBloc = AccountBloc(
    authenticationRepository: htAuthenticationRepository,
    userContentPreferencesRepository: htUserContentPreferencesRepository,
  );

  return GoRouter(
    refreshListenable: authStatusNotifier,
    initialLocation: Routes.feed,
    debugLogDiagnostics: true, // Enable verbose logging for debugging redirects
    // --- Redirect Logic ---
    redirect: (BuildContext context, GoRouterState state) {
      // --- Get Current State ---
      // Safely read the AppBloc state. refreshListenable ensures this runs
      // within a valid context after AppBloc state changes.
      final appStatus = context.read<AppBloc>().state.status;
      // The matched route pattern (e.g., '/authentication/email-sign-in').
      final currentLocation = state.matchedLocation;
      // The full URI including query parameters (e.g., '/authentication?context=linking').
      final currentUri = state.uri;

      // --- Debug Logging ---
      // Log current state for easier debugging of redirect behavior.
      print(
        'GoRouter Redirect Check:\n'
        '  Current Location (Matched): $currentLocation\n'
        '  Current URI (Full): $currentUri\n'
        '  AppStatus: $appStatus',
      );

      // --- Define Key Paths ---
      // Base paths for major sections.
      const authenticationPath = Routes.authentication; // '/authentication'
      const feedPath = Routes.feed; // Updated path constant
      // Specific authentication sub-routes crucial for the email code verification flow.
      const requestCodePath =
          '$authenticationPath/${Routes.requestCode}'; // '/authentication/request-code'
      const verifyCodePath =
          '$authenticationPath/${Routes.verifyCode}'; // '/authentication/verify-code'

      // --- Helper Booleans ---
      // Check if the navigation target is within the authentication section.
      final isGoingToAuth = currentLocation.startsWith(authenticationPath);
      // Check if the navigation target is within the feed section.
      final isGoingToFeed = currentLocation.startsWith(
        feedPath,
      ); // Updated path constant
      // Check if the navigation target is the *exact* base authentication path.
      final isGoingToBaseAuthPath = currentLocation == authenticationPath;
      // Check if the 'context=linking' query parameter is present in the URI.
      final isLinkingContext =
          currentUri.queryParameters['context'] == 'linking';
      // Removed isGoingToSplash check

      // --- Redirect Logic based on AppStatus ---

      // --- Case 0: Initial Loading State ---
      // While the app is initializing (status is initial), don't redirect.
      // Let the initial navigation attempt proceed. The refreshListenable
      // will trigger a redirect check again once the status is known.
      if (appStatus == AppStatus.initial) {
        print(
          '  Redirect Decision: AppStatus is INITIAL. Allowing navigation.',
        );
        return null; // Do not redirect during initial phase
      }

      // --- Case 1: Unauthenticated User (After Initial Load) ---
      // If the user is unauthenticated...
      if (appStatus == AppStatus.unauthenticated) {
        print('  Redirect Decision: User is UNauthenticated (post-initial).');
        // If the user is NOT already going to an authentication path...
        if (!isGoingToAuth) {
          // ...redirect them to the main authentication page to sign in or sign up.
          print('    Action: Redirecting to $authenticationPath');
          return authenticationPath;
        }
        // Otherwise, allow them to stay on the authentication path they are navigating to.
        print('    Action: Allowing navigation within authentication section.');
        return null; // Allow access
      }
      // --- Case 2: Anonymous User ---
      else if (appStatus == AppStatus.anonymous) {
        print('  Redirect Decision: User is ANONYMOUS.');

        // Define search and account paths for clarity
        const searchPath = Routes.search; // '/search'
        const accountPath = Routes.account; // '/account'

        // Helper booleans for search and account sections
        final isGoingToSearch = currentLocation.startsWith(searchPath);
        final isGoingToAccount = currentLocation.startsWith(accountPath);

        // **Sub-Case 2.1: Navigating to the BASE Authentication Path (`/authentication`)**
        if (isGoingToBaseAuthPath) {
          // Allow access ONLY if they are explicitly starting the linking flow
          // (indicated by the 'context=linking' query parameter).
          if (isLinkingContext) {
            print(
              '    Action: Allowing navigation to BASE auth for account linking.',
            );
            return null; // Allow access
          } else {
            // Prevent anonymous users from accessing the initial sign-in screen again.
            // Redirect them to the main content (feed).
            print(
              '    Action: Preventing access to initial sign-in, redirecting to $feedPath', // Updated path constant
            );
            return feedPath; // Redirect to feed
          }
        }
        // **Sub-Case 2.2: Navigating to Specific Email Code Verification Sub-Routes**
        // Explicitly allow access to the necessary pages for the email code verification process,
        // even if the 'context=linking' parameter is lost during navigation between these pages.
        else if (currentLocation == requestCodePath ||
            currentLocation.startsWith(verifyCodePath)) {
          // Use startsWith for parameterized path
          print(
            '    Action: Allowing navigation to email code verification sub-route ($currentLocation).',
          );
          return null; // Allow access
        }
        // **Sub-Case 2.3: Navigating Within the Main App Sections (Feed, Search, Account) or Details Pages**
        // Allow anonymous users to access the main content sections, their sub-routes, and details pages.
        else if (isGoingToFeed ||
            isGoingToSearch ||
            isGoingToAccount ||
            currentLocation == Routes.categoryDetails ||
            currentLocation == Routes.sourceDetails ||
            currentLocation.startsWith(
              Routes.globalArticleDetails.split('/:id').first,
            ) || // Allow global article details
            currentLocation.startsWith(
              '${Routes.feed}/${Routes.articleDetailsName.split('/:id').first}',
            ) ||
            currentLocation.startsWith(
              '${Routes.search}/${Routes.searchArticleDetailsName.split('/:id').first}',
            ) ||
            currentLocation.startsWith(
              '${Routes.account}/${Routes.accountSavedHeadlines}/${Routes.accountArticleDetailsName.split('/:id').first}',
            )) {
          print(
            '    Action: Allowing navigation to main app section or details page ($currentLocation).',
          );
          return null; // Allow access
        }
        // **Sub-Case 2.4: Fallback for Unexpected Paths**
        // If an anonymous user tries to navigate anywhere else unexpected,
        // redirect them to the main content feed as a safe default.
        else {
          print(
            '    Action: Unexpected path ($currentLocation), redirecting to $feedPath',
          );
          return feedPath; // Redirect to feed
        }
      }
      // --- Case 3: Authenticated User ---
      else if (appStatus == AppStatus.authenticated) {
        print('  Redirect Decision: User is AUTHENTICATED.');
        // If an authenticated user tries to access any part of the authentication flow...
        if (isGoingToAuth) {
          // ...redirect them away to the main content feed. They don't need to authenticate again.
          print(
            '    Action: Preventing access to authentication section, redirecting to $feedPath', // Updated path constant
          );
          return feedPath; // Redirect to feed
        }
        // Otherwise, allow authenticated users to access any other part of the app (feed, account, settings, etc.).
        print(
          '    Action: Allowing navigation to non-auth section ($currentLocation).',
        );
        return null; // Allow access
      }
      // --- Case 4: Fallback (Should not be reached with initial handling) ---
      // This case is less likely now with explicit initial handling.
      // If somehow the status is unknown after the initial phase, allow navigation.
      else {
        print(
          '  Redirect Decision: AppStatus is UNEXPECTED ($appStatus). Allowing navigation (fallback).',
        );
        return null; // Allow access as a safe default
      }

      // --- Default: No Redirect (Should not be reached if logic is exhaustive) ---
      // If none of the above conditions triggered an explicit redirect, allow navigation.
      // This line should theoretically not be reached if the logic above is exhaustive.
      // print('  Redirect Decision: No specific redirect condition met. Allowing navigation.');
      // return null; // Allow access (already covered by the final return null below)
    },
    // --- Authentication Routes ---
    routes: [
      GoRoute(
        path: Routes.authentication,
        name: Routes.authenticationName,
        builder: (BuildContext context, GoRouterState state) {
          final l10n = context.l10n;
          // Determine context from query parameter
          final isLinkingContext =
              state.uri.queryParameters['context'] == 'linking';

          // Define content based on context
          final String headline;
          final String subHeadline;
          final bool showAnonymousButton;

          if (isLinkingContext) {
            headline = l10n.authenticationLinkingHeadline;
            subHeadline = l10n.authenticationLinkingSubheadline;
            showAnonymousButton = false; // Don't show anon button when linking
          } else {
            headline = l10n.authenticationSignInHeadline;
            subHeadline = l10n.authenticationSignInSubheadline;
            showAnonymousButton = true; // Show anon button for initial sign-in
          }

          return BlocProvider(
            create:
                (context) => AuthenticationBloc(
                  authenticationRepository: context.read<HtAuthRepository>(),
                ),
            child: AuthenticationPage(
              headline: headline,
              subHeadline: subHeadline,
              showAnonymousButton: showAnonymousButton,
              isLinkingContext: isLinkingContext,
            ),
          );
        },
        routes: [
          GoRoute(
            path: Routes.requestCode, // Use new path
            name: Routes.requestCodeName, // Use new name
            builder: (context, state) {
              // Extract the linking context flag from 'extra', default to false.
              final isLinking = (state.extra as bool?) ?? false;
              return RequestCodePage(isLinkingContext: isLinking);
            },
          ),
          GoRoute(
            path:
                '${Routes.verifyCode}/:email', // Use new path with email parameter
            name: Routes.verifyCodeName, // Use new name
            builder: (context, state) {
              final email = state.pathParameters['email']!; // Extract email
              return EmailCodeVerificationPage(
                email: email,
              ); // Use renamed page
            },
          ),
        ],
      ),
      // --- Entity Details Routes (Top Level) ---
      GoRoute(
        path: Routes.categoryDetails,
        name: Routes.categoryDetailsName,
        builder: (context, state) {
          final args = state.extra as EntityDetailsPageArguments?;
          if (args == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Missing category details arguments'),
              ),
            );
          }
          return BlocProvider.value(
            value: accountBloc,
            child: EntityDetailsPage(args: args),
          );
        },
      ),
      GoRoute(
        path: Routes.sourceDetails,
        name: Routes.sourceDetailsName,
        builder: (context, state) {
          final args = state.extra as EntityDetailsPageArguments?;
          if (args == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Missing source details arguments'),
              ),
            );
          }
          return BlocProvider.value(
            value: accountBloc,
            child: EntityDetailsPage(args: args),
          );
        },
      ),
      // --- Global Article Details Route (Top Level) ---
      // This GoRoute provides a top-level, globally accessible way to view the
      // HeadlineDetailsPage.
      //
      // Purpose:
      // It is specifically designed for navigating to article details from contexts
      // that are *outside* the main StatefulShellRoute's branches (e.g., from
      // EntityDetailsPage, which is itself a top-level route, or potentially
      // from other future top-level pages or deep links).
      //
      // Why it's necessary:
      // Attempting to push a route that is deeply nested within a specific shell
      // branch (like '/feed/article/:id') from a BuildContext outside of that
      // shell can lead to navigator context issues and assertion failures.
      // This global route avoids such problems by providing a clean, direct path
      // to the HeadlineDetailsPage.
      //
      // How it differs:
      // This route is distinct from the article detail routes nested within the
      // StatefulShellRoute branches (e.g., Routes.articleDetailsName under /feed,
      // Routes.searchArticleDetailsName under /search). Those nested routes are
      // intended for navigation *within* their respective shell branches,
      // preserving the shell's UI (like the bottom navigation bar).
      // This global route, being top-level, will typically cover the entire screen.
      GoRoute(
        path: Routes.globalArticleDetails, // Use new path: '/article/:id'
        name: Routes.globalArticleDetailsName, // Use new name
        builder: (context, state) {
          final headlineFromExtra = state.extra as Headline?;
          final headlineIdFromPath = state.pathParameters['id'];

          // Ensure accountBloc is available if needed by HeadlineDetailsPage
          // or its descendants for actions like saving.
          // If AccountBloc is already provided higher up (e.g., in AppShell or App),
          // this specific BlocProvider.value might not be strictly necessary here,
          // but it's safer to ensure it's available for this top-level route.
          // We are using the `accountBloc` instance created at the top of `createRouter`.
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountBloc),
              BlocProvider(
                create:
                    (context) => HeadlineDetailsBloc(
                      headlinesRepository:
                          context.read<HtDataRepository<Headline>>(),
                    ),
              ),
              BlocProvider(
                create:
                    (context) => SimilarHeadlinesBloc(
                      headlinesRepository:
                          context.read<HtDataRepository<Headline>>(),
                    ),
              ),
            ],
            child: HeadlineDetailsPage(
              initialHeadline: headlineFromExtra,
              headlineId: headlineFromExtra?.id ?? headlineIdFromPath,
            ),
          );
        },
      ),
      // --- Main App Shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Return the shell widget which contains the AdaptiveScaffold
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountBloc), // Use the shared instance
              BlocProvider(
                create:
                    (context) => HeadlinesFeedBloc(
                      headlinesRepository:
                          context.read<HtDataRepository<Headline>>(),
                    )..add(const HeadlinesFeedFetchRequested()),
              ),
              BlocProvider(
                create:
                    (context) => HeadlinesSearchBloc(
                      headlinesRepository:
                          context.read<HtDataRepository<Headline>>(),
                      categoryRepository:
                          context.read<HtDataRepository<Category>>(),
                      sourceRepository:
                          context.read<HtDataRepository<Source>>(),
                      // countryRepository: // Removed
                      //     context.read<HtDataRepository<Country>>(), // Removed
                    ),
              ),
              // Removed separate AccountBloc creation here
            ],
            child: AppShell(navigationShell: navigationShell),
          );
        },
        branches: [
          // --- Branch 1: Feed ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed, // '/feed'
                name: Routes.feedName,
                builder: (context, state) => const HeadlinesFeedPage(),
                routes: [
                  // Sub-route for article details
                  GoRoute(
                    path: 'article/:id', // Relative path
                    name: Routes.articleDetailsName,
                    builder: (context, state) {
                      final headlineFromExtra = state.extra as Headline?;
                      final headlineIdFromPath = state.pathParameters['id'];

                      return MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: accountBloc), // Added
                          BlocProvider(
                            create:
                                (context) => HeadlineDetailsBloc(
                                  headlinesRepository:
                                      context
                                          .read<HtDataRepository<Headline>>(),
                                ),
                          ),
                          BlocProvider(
                            create:
                                (context) => SimilarHeadlinesBloc(
                                  headlinesRepository:
                                      context
                                          .read<HtDataRepository<Headline>>(),
                                ),
                          ),
                        ],
                        child: HeadlineDetailsPage(
                          initialHeadline: headlineFromExtra,
                          // Ensure headlineId is non-null if initialHeadline is null
                          headlineId:
                              headlineFromExtra?.id ?? headlineIdFromPath,
                        ),
                      );
                    },
                  ),
                  // Sub-route for notifications (placeholder) - MOVED HERE
                  GoRoute(
                    path: Routes.notifications, // Relative path 'notifications'
                    name: Routes.notificationsName,
                    builder: (context, state) {
                      // TODO(fulleni): Replace with actual NotificationsPage
                      return const Placeholder(
                        child: Center(child: Text('NOTIFICATIONS PAGE')),
                      );
                    },
                  ),

                  // --- Filter Routes (Nested under Feed) ---
                  GoRoute(
                    path: Routes.feedFilter, // Relative path: 'filter'
                    name: Routes.feedFilterName,
                    // Use MaterialPage with fullscreenDialog for modal presentation
                    pageBuilder: (context, state) {
                      // Access the HeadlinesFeedBloc from the context
                      BlocProvider.of<HeadlinesFeedBloc>(context);
                      return const MaterialPage(
                        fullscreenDialog: true,
                        child: HeadlinesFilterPage(), // Pass the BLoC instance
                      );
                    },
                    routes: [
                      // Sub-route for category selection
                      GoRoute(
                        path:
                            Routes
                                .feedFilterCategories, // Relative path: 'categories'
                        name: Routes.feedFilterCategoriesName,
                        // Wrap with BlocProvider
                        builder:
                            (context, state) => BlocProvider(
                              create:
                                  (context) => CategoriesFilterBloc(
                                    categoriesRepository:
                                        context
                                            .read<HtDataRepository<Category>>(),
                                  ),
                              child: const CategoryFilterPage(),
                            ),
                      ),
                      // Sub-route for source selection
                      GoRoute(
                        path:
                            Routes
                                .feedFilterSources, // Relative path: 'sources'
                        name: Routes.feedFilterSourcesName,
                        // Wrap with BlocProvider
                        builder:
                            (context, state) => BlocProvider(
                              create:
                                  (context) => SourcesFilterBloc(
                                    sourcesRepository:
                                        context
                                            .read<HtDataRepository<Source>>(),
                                    countriesRepository: // Added missing repository
                                        context
                                            .read<HtDataRepository<Country>>(),
                                  ),
                              // Pass initialSelectedSources, country ISO codes, and source types from state.extra
                              child: Builder(
                                builder: (context) {
                                  final extraData =
                                      state.extra as Map<String, dynamic>? ??
                                      const {};
                                  final initialSources =
                                      extraData[keySelectedSources]
                                          as List<Source>? ??
                                      const [];
                                  final initialCountryIsoCodes =
                                      extraData[keySelectedCountryIsoCodes]
                                          as Set<String>? ??
                                      const {};
                                  final initialSourceTypes =
                                      extraData[keySelectedSourceTypes]
                                          as Set<SourceType>? ??
                                      const {};

                                  return SourceFilterPage(
                                    initialSelectedSources: initialSources,
                                    initialSelectedCountryIsoCodes:
                                        initialCountryIsoCodes,
                                    initialSelectedSourceTypes:
                                        initialSourceTypes,
                                  );
                                },
                              ),
                            ),
                      ),
                      // Sub-route for country selection REMOVED
                    ],
                  ),
                ],
              ),
            ],
          ),
          // --- Branch 2: Search ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search, // '/search'
                name: Routes.searchName,
                builder: (context, state) => const HeadlinesSearchPage(),
                routes: [
                  // Sub-route for article details from search
                  GoRoute(
                    path: 'article/:id', // Relative path
                    name: Routes.searchArticleDetailsName, // New route name
                    builder: (context, state) {
                      final headlineFromExtra = state.extra as Headline?;
                      final headlineIdFromPath = state.pathParameters['id'];
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: accountBloc), // Added
                          BlocProvider(
                            create:
                                (context) => HeadlineDetailsBloc(
                                  headlinesRepository:
                                      context
                                          .read<HtDataRepository<Headline>>(),
                                ),
                          ),
                          BlocProvider(
                            create:
                                (context) => SimilarHeadlinesBloc(
                                  headlinesRepository:
                                      context
                                          .read<HtDataRepository<Headline>>(),
                                ),
                          ),
                        ],
                        child: HeadlineDetailsPage(
                          initialHeadline: headlineFromExtra,
                          headlineId:
                              headlineFromExtra?.id ?? headlineIdFromPath,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // --- Branch 3: Account ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account, // '/account'
                name: Routes.accountName,
                builder: (context, state) => const AccountPage(),
                routes: [
                  // ShellRoute for settings to provide SettingsBloc to children
                  ShellRoute(
                    builder: (
                      BuildContext context,
                      GoRouterState state,
                      Widget child,
                    ) {
                      // This builder provides SettingsBloc to all routes within this ShellRoute.
                      // 'child' will be SettingsPage, AppearanceSettingsPage, etc.
                      final appBloc = context.read<AppBloc>();
                      final userId = appBloc.state.user?.id;

                      return BlocProvider<SettingsBloc>(
                        create: (context) {
                          final settingsBloc = SettingsBloc(
                            userAppSettingsRepository:
                                context
                                    .read<HtDataRepository<UserAppSettings>>(),
                          );
                          // Only load settings if a userId is available
                          if (userId != null) {
                            settingsBloc.add(
                              SettingsLoadRequested(userId: userId),
                            );
                          } else {
                            // Handle case where user is unexpectedly null.
                            print(
                              'ShellRoute/SettingsBloc: User ID is null when creating SettingsBloc. Settings will not be loaded.',
                            );
                          }
                          return settingsBloc;
                        },
                        child:
                            child, // child is the actual page widget (SettingsPage, AppearanceSettingsPage, etc.)
                      );
                    },
                    routes: [
                      GoRoute(
                        path:
                            Routes
                                .settings, // Relative path 'settings' from /account
                        name: Routes.settingsName,
                        builder: (context, state) => const SettingsPage(),
                        // --- Settings Sub-Routes ---
                        routes: [
                          GoRoute(
                            path:
                                Routes
                                    .settingsAppearance, // 'appearance' relative to /account/settings
                            name: Routes.settingsAppearanceName,
                            builder:
                                (context, state) =>
                                    const AppearanceSettingsPage(),
                            routes: [
                              // Children of AppearanceSettingsPage
                              GoRoute(
                                path:
                                    Routes
                                        .settingsAppearanceTheme, // 'theme' relative to /account/settings/appearance
                                name: Routes.settingsAppearanceThemeName,
                                builder:
                                    (context, state) =>
                                        const ThemeSettingsPage(),
                              ),
                              GoRoute(
                                path:
                                    Routes
                                        .settingsAppearanceFont, // 'font' relative to /account/settings/appearance
                                name: Routes.settingsAppearanceFontName,
                                builder:
                                    (context, state) =>
                                        const FontSettingsPage(),
                              ),
                            ],
                          ),
                          GoRoute(
                            path:
                                Routes
                                    .settingsFeed, // 'feed' relative to /account/settings
                            name: Routes.settingsFeedName,
                            builder:
                                (context, state) => const FeedSettingsPage(),
                          ),
                          GoRoute(
                            path:
                                Routes
                                    .settingsNotifications, // 'notifications' relative to /account/settings
                            name: Routes.settingsNotificationsName,
                            builder:
                                (context, state) =>
                                    const NotificationSettingsPage(),
                          ),
                          GoRoute(
                            path:
                                Routes
                                    .settingsLanguage, // 'language' relative to /account/settings
                            name: Routes.settingsLanguageName,
                            builder:
                                (context, state) =>
                                    const LanguageSettingsPage(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // New routes for Account sub-pages
                  GoRoute(
                    path: Routes.manageFollowedItems, // Updated path
                    name: Routes.manageFollowedItemsName, // Updated name
                    builder:
                        (context, state) =>
                            const ManageFollowedItemsPage(), // Use the new page
                    routes: [
                      GoRoute(
                        path: Routes.followedCategoriesList,
                        name: Routes.followedCategoriesListName,
                        builder:
                            (context, state) =>
                                const FollowedCategoriesListPage(),
                        routes: [
                          GoRoute(
                            path: Routes.addCategoryToFollow,
                            name: Routes.addCategoryToFollowName,
                            builder:
                                (context, state) =>
                                    const AddCategoryToFollowPage(),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: Routes.followedSourcesList,
                        name: Routes.followedSourcesListName,
                        builder:
                            (context, state) => const FollowedSourcesListPage(),
                        routes: [
                          GoRoute(
                            path: Routes.addSourceToFollow,
                            name: Routes.addSourceToFollowName,
                            builder:
                                (context, state) =>
                                    const AddSourceToFollowPage(),
                          ),
                        ],
                      ),
                      // GoRoute for followedCountriesList removed
                    ],
                  ),
                  GoRoute(
                    path: Routes.accountSavedHeadlines,
                    name: Routes.accountSavedHeadlinesName,
                    builder: (context, state) {
                      return const SavedHeadlinesPage(); // Use the actual page
                    },
                    routes: [
                      GoRoute(
                        path: Routes.accountArticleDetails, // 'article/:id'
                        name: Routes.accountArticleDetailsName,
                        builder: (context, state) {
                          final headlineFromExtra = state.extra as Headline?;
                          final headlineIdFromPath = state.pathParameters['id'];
                          return MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: accountBloc), // Added
                              BlocProvider(
                                create:
                                    (context) => HeadlineDetailsBloc(
                                      headlinesRepository:
                                          context
                                              .read<
                                                HtDataRepository<Headline>
                                              >(),
                                    ),
                              ),
                              BlocProvider(
                                create:
                                    (context) => SimilarHeadlinesBloc(
                                      headlinesRepository:
                                          context
                                              .read<
                                                HtDataRepository<Headline>
                                              >(),
                                    ),
                              ),
                            ],
                            child: HeadlineDetailsPage(
                              initialHeadline: headlineFromExtra,
                              headlineId:
                                  headlineFromExtra?.id ?? headlineIdFromPath,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// Placeholder pages were moved to their respective files:
// - lib/headlines-feed/view/headlines_filter_page.dart
// - lib/headlines-feed/view/category_filter_page.dart
// - lib/headlines-feed/view/source_filter_page.dart
// - lib/headlines-feed/view/country_filter_page.dart
