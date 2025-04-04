import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_categories_client/ht_categories_client.dart';
import 'package:ht_countries_client/ht_countries_client.dart';
import 'package:ht_headlines_client/ht_headlines_client.dart'; // Import for Headline and Exceptions
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_sources_client/ht_sources_client.dart';

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// A Bloc that manages the headlines feed.
///
/// It handles fetching and refreshing headlines data using the
/// [HtHeadlinesRepository].
/// {@endtemplate}
class HeadlinesFeedBloc extends Bloc<HeadlinesFeedEvent, HeadlinesFeedState> {
  /// {@macro headlines_feed_bloc}
  HeadlinesFeedBloc({required HtHeadlinesRepository headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(HeadlinesFeedLoading()) {
    on<HeadlinesFeedFetchRequested>(
      _onHeadlinesFeedFetchRequested,
      transformer: sequential(),
    );
    on<HeadlinesFeedRefreshRequested>(
      _onHeadlinesFeedRefreshRequested,
      transformer: restartable(),
    );
    on<HeadlinesFeedFilterChanged>(_onHeadlinesFeedFilterChanged);
  }

  final HtHeadlinesRepository _headlinesRepository;

  static const _headlinesFetchLimit = 10;

  Future<void> _onHeadlinesFeedFilterChanged(
    HeadlinesFeedFilterChanged event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading());
    try {
      // Use list-based filters from the event
      final response = await _headlinesRepository.getHeadlines(
        limit: _headlinesFetchLimit,
        categories: event.categories,
        sources: event.sources,
        eventCountries: event.eventCountries,
      );
      final newFilter =
          (state is HeadlinesFeedLoaded)
              ? (state as HeadlinesFeedLoaded).filter.copyWith(
                // Update copyWith call
                categories: event.categories,
                sources: event.sources,
                eventCountries: event.eventCountries,
              )
              : HeadlineFilter(
                // Update constructor call
                categories: event.categories,
                sources: event.sources,
                eventCountries: event.eventCountries,
              );
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter: newFilter,
        ),
      );
    } on HeadlinesFetchException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (_) {
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }

  /// Handles [HeadlinesFeedFetchRequested] events.
  ///
  /// Fetches headlines from the repository and emits
  /// [HeadlinesFeedLoading], and either [HeadlinesFeedLoaded] or
  /// [HeadlinesFeedError] states.
  Future<void> _onHeadlinesFeedFetchRequested(
    HeadlinesFeedFetchRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    if (state is HeadlinesFeedLoaded &&
        (state as HeadlinesFeedLoaded).hasMore) {
      final currentState = state as HeadlinesFeedLoaded;
      emit(HeadlinesFeedLoadingSilently());
      try {
        // Use list-based filters from the current state's filter
        final response = await _headlinesRepository.getHeadlines(
          limit: _headlinesFetchLimit,
          startAfterId: currentState.cursor,
          categories: currentState.filter.categories,
          sources: currentState.filter.sources,
          eventCountries: currentState.filter.eventCountries,
        );
        emit(
          HeadlinesFeedLoaded(
            headlines: currentState.headlines + response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
            filter: currentState.filter,
          ),
        );
      } on HeadlinesFetchException catch (e) {
        emit(HeadlinesFeedError(message: e.message));
      } catch (_) {
        emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
      }
    } else {
      emit(HeadlinesFeedLoading());
      try {
        // Use list-based filters from the current state's filter (if loaded)
        final response = await _headlinesRepository.getHeadlines(
          limit: _headlinesFetchLimit,
          categories:
              state is HeadlinesFeedLoaded
                  ? (state as HeadlinesFeedLoaded).filter.categories
                  : null,
          sources:
              state is HeadlinesFeedLoaded
                  ? (state as HeadlinesFeedLoaded).filter.sources
                  : null,
          eventCountries:
              state is HeadlinesFeedLoaded
                  ? (state as HeadlinesFeedLoaded).filter.eventCountries
                  : null,
        );
        emit(
          HeadlinesFeedLoaded(
            headlines: response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
            filter:
                state is HeadlinesFeedLoaded
                    ? (state as HeadlinesFeedLoaded).filter
                    : const HeadlineFilter(),
          ),
        );
      } on HeadlinesFetchException catch (e) {
        emit(HeadlinesFeedError(message: e.message));
      } catch (_) {
        emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
      }
    }
  }

  /// Handles [HeadlinesFeedRefreshRequested] events.
  ///
  /// Fetches headlines from the repository and emits
  /// [HeadlinesFeedLoading], and either [HeadlinesFeedLoaded] or
  /// [HeadlinesFeedError] states.
  ///
  /// Uses `restartable` transformer to ensure that only the latest
  /// refresh request is processed.
  Future<void> _onHeadlinesFeedRefreshRequested(
    HeadlinesFeedRefreshRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading());
    try {
      // Use list-based filters from the current state's filter (if loaded)
      final response = await _headlinesRepository.getHeadlines(
        limit: 20, // Consider using _headlinesFetchLimit here too?
        categories:
            state is HeadlinesFeedLoaded
                ? (state as HeadlinesFeedLoaded).filter.categories
                : null,
        sources:
            state is HeadlinesFeedLoaded
                ? (state as HeadlinesFeedLoaded).filter.sources
                : null,
        eventCountries:
            state is HeadlinesFeedLoaded
                ? (state as HeadlinesFeedLoaded).filter.eventCountries
                : null,
      );
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter:
              state is HeadlinesFeedLoaded
                  ? (state as HeadlinesFeedLoaded).filter
                  : const HeadlineFilter(),
        ),
      );
    } on HeadlinesFetchException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (_) {
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }
}
