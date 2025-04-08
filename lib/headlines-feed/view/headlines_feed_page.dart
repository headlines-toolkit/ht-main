//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Import Category
// Import Country
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';
// Import Source

/// {@template headlines_feed_page}
/// The main page displaying the feed of news headlines.
///
/// Provides the [HeadlinesFeedBloc] and renders the [_HeadlinesFeedView]
/// which handles the UI based on the BLoC state.
/// {@endtemplate}
class HeadlinesFeedPage extends StatelessWidget {
  /// {@macro headlines_feed_page}
  const HeadlinesFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => HeadlinesFeedBloc(
            headlinesRepository: context.read<HtHeadlinesRepository>(),
          )..add(const HeadlinesFeedFetchRequested()),
      child: const _HeadlinesFeedView(),
    );
  }
}

/// {@template headlines_feed_view}
/// The core view widget for the headlines feed.
///
/// Handles displaying the list of headlines, loading states, error states,
/// pagination (infinity scroll), and pull-to-refresh functionality. It also
/// includes the AppBar with actions for notifications and filtering.
/// {@endtemplate}
class _HeadlinesFeedView extends StatefulWidget {
  /// {@macro headlines_feed_view}
  const _HeadlinesFeedView();

  @override
  State<_HeadlinesFeedView> createState() => _HeadlinesFeedViewState();
}

/// State for the [_HeadlinesFeedView]. Manages the [ScrollController] for
/// pagination and listens to scroll events.
class _HeadlinesFeedViewState extends State<_HeadlinesFeedView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add listener to trigger pagination when scrolling near the bottom.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Remove listener and dispose the controller to prevent memory leaks.
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Callback function for scroll events.
  ///
  /// Checks if the user has scrolled near the bottom of the list and if there
  /// are more headlines to fetch. If so, dispatches a
  /// [HeadlinesFeedFetchRequested] event to the BLoC.
  void _onScroll() {
    final state = context.read<HeadlinesFeedBloc>().state;
    if (_isBottom && state is HeadlinesFeedLoaded) {
      if (state.hasMore) {
        // Request the next page of headlines
        context.read<HeadlinesFeedBloc>().add(
          HeadlinesFeedFetchRequested(cursor: state.cursor), // Pass cursor
        );
      }
    }
  }

  /// Checks if the current scroll position is near the bottom of the list.
  ///
  /// Returns `true` if the scroll offset is within 98% of the maximum scroll
  /// extent, `false` otherwise.
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger slightly before reaching the absolute end for smoother loading.
    return currentScroll >= (maxScroll * 0.98);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedAppBarTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.notificationsTooltip, // Add tooltip for accessibility
            onPressed: () {
              context.goNamed(
                Routes.notificationsName,
              ); // Ensure correct route name
            },
          ),
          BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
            builder: (context, state) {
              var isFilterApplied = false;
              if (state is HeadlinesFeedLoaded) {
                // Check if any filter list is non-null and not empty
                isFilterApplied =
                    (state.filter.categories?.isNotEmpty ?? false) ||
                    (state.filter.sources?.isNotEmpty ?? false) ||
                    (state.filter.eventCountries?.isNotEmpty ?? false);
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: l10n.headlinesFeedFilterTooltip,
                    onPressed: () {
                      // Navigate to the filter page route
                      context.goNamed(Routes.feedFilterName);
                    },
                  ),
                  if (isFilterApplied)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
        buildWhen:
            (previous, current) => current is! HeadlinesFeedLoadingSilently,
        builder: (context, state) {
          switch (state) {
            case HeadlinesFeedLoading():
              // Display full-screen loading indicator
              return LoadingStateWidget(
                icon: Icons.newspaper, // Use a relevant icon
                headline: l10n.headlinesFeedLoadingHeadline,
                subheadline: l10n.headlinesFeedLoadingSubheadline,
              );

            case HeadlinesFeedLoadingSilently():
              // This state is handled by buildWhen, should not be reached here.
              // Return an empty container as a fallback.
              return const SizedBox.shrink();

            case HeadlinesFeedLoaded():
              // Display the list of headlines with pull-to-refresh
              return RefreshIndicator(
                onRefresh: () async {
                  // Dispatch refresh event to the BLoC
                  context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedRefreshRequested(),
                  );
                  // Note: BLoC handles emitting loading state during refresh
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom:
                        AppSpacing.xxl, // Ensure space below last item/loader
                  ),
                  itemCount:
                      state.hasMore
                          ? state.headlines.length +
                              1 // +1 for loading indicator
                          : state.headlines.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(
                        height: AppSpacing.lg,
                      ), // Consistent spacing
                  itemBuilder: (context, index) {
                    // Check if it's the loading indicator item
                    if (index >= state.headlines.length) {
                      // Show loading indicator at the bottom if more items exist
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    // Otherwise, build the headline item
                    final headline = state.headlines[index];
                    return HeadlineItemWidget(headline: headline);
                  },
                ),
              );

            case HeadlinesFeedError():
              // Display error message with a retry button
              return FailureStateWidget(
                message: state.message,
                onRetry: () {
                  // Dispatch refresh event on retry
                  context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedRefreshRequested(),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
