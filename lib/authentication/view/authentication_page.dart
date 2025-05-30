//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template authentication_page}
/// Displays authentication options (Google, Email, Anonymous) based on context.
///
/// This page can be used for both initial sign-in and for connecting an
/// existing anonymous account.
/// {@endtemplate}
class AuthenticationPage extends StatelessWidget {
  /// {@macro authentication_page}
  const AuthenticationPage({
    required this.headline,
    required this.subHeadline,
    required this.showAnonymousButton,
    required this.isLinkingContext,
    super.key,
  });

  /// The main title displayed on the page.
  final String headline;

  /// The descriptive text displayed below the headline.
  final String subHeadline;

  /// Whether to show the "Continue Anonymously" button.
  final bool showAnonymousButton;

  /// Whether this page is being shown in the account linking context.
  final bool isLinkingContext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Conditionally add the leading close button only in linking context
        leading:
            isLinkingContext
                ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip:
                      MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip, // Accessibility
                  onPressed: () {
                    // Navigate back to the account page when close is pressed
                    context.goNamed(Routes.accountName);
                  },
                )
                : null, // No leading button if not linking (relies on system back if pushed)
      ),
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          // Listener remains crucial for feedback (errors)
          listener: (context, state) {
            if (state is AuthenticationFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      // Provide a more user-friendly error message if possible
                      state.errorMessage, // Or map specific errors
                    ),
                    backgroundColor: colorScheme.error,
                  ),
                );
            }
            // Success states (Google/Anonymous) are typically handled by
            // the AppBloc listening to repository changes and triggering redirects.
            // Email link success is handled in the dedicated email flow pages.
          },
          builder: (context, state) {
            final isLoading =
                state is AuthenticationLoading; // Simplified loading check

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLarge),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center vertically
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Hardcoded Icon ---
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xl,
                        ), // Spacing below icon
                        child: Icon(
                          Icons.security, // Hardcode the icon
                          size:
                              (Theme.of(context).iconTheme.size ??
                                  AppSpacing.xl) *
                              3.0,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.lg,
                      ), // Space between icon and headline
                      // --- Headline and Subheadline ---
                      Text(
                        headline,
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subHeadline,
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // --- Email Sign-In Button ---
                      ElevatedButton(
                        // Consider an email icon
                        // icon: const Icon(Icons.email_outlined),
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  // Navigate to the dedicated email sign-in page,
                                  // passing the linking context via 'extra'.
                                  context.goNamed(
                                    Routes.requestCodeName,
                                    extra: isLinkingContext,
                                  );
                                },
                        // Consider an email icon
                        // icon: const Icon(Icons.email_outlined),
                        child: Text(l10n.authenticationEmailSignInButton),
                      ),

                      // --- Anonymous Sign-In Button (Conditional) ---
                      if (showAnonymousButton) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () => context.read<AuthenticationBloc>().add(
                                    const AuthenticationAnonymousSignInRequested(),
                                  ),
                          child: Text(l10n.authenticationAnonymousSignInButton),
                        ),
                      ],

                      // --- Loading Indicator (Optional, for general loading state) ---
                      // If needed, show a general loading indicator when state is AuthenticationLoading
                      if (isLoading &&
                          state is! AuthenticationRequestCodeLoading) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
