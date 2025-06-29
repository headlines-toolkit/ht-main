import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart' show Country, Source, SourceType;

part 'sources_filter_event.dart';
part 'sources_filter_state.dart';

class SourcesFilterBloc extends Bloc<SourcesFilterEvent, SourcesFilterState> {
  SourcesFilterBloc({
    required HtDataRepository<Source> sourcesRepository,
    required HtDataRepository<Country> countriesRepository,
  }) : _sourcesRepository = sourcesRepository,
       _countriesRepository = countriesRepository,
       super(const SourcesFilterState()) {
    on<LoadSourceFilterData>(_onLoadSourceFilterData);
    on<CountryCapsuleToggled>(_onCountryCapsuleToggled);
    on<AllSourceTypesCapsuleToggled>(_onAllSourceTypesCapsuleToggled);
    on<SourceTypeCapsuleToggled>(_onSourceTypeCapsuleToggled);
    on<SourceCheckboxToggled>(_onSourceCheckboxToggled);
    on<ClearSourceFiltersRequested>(_onClearSourceFiltersRequested);
    // Removed _FetchFilteredSourcesRequested event listener
  }

  final HtDataRepository<Source> _sourcesRepository;
  final HtDataRepository<Country> _countriesRepository;

  Future<void> _onLoadSourceFilterData(
    LoadSourceFilterData event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(dataLoadingStatus: SourceFilterDataLoadingStatus.loading),
    );
    try {
      final availableCountries = await _countriesRepository.readAll();
      final initialSelectedSourceIds = event.initialSelectedSources
          .map((s) => s.id)
          .toSet();

      // Use the passed-in initial capsule selections directly
      final initialSelectedCountryIsoCodes =
          event.initialSelectedCountryIsoCodes;
      final initialSelectedSourceTypes = event.initialSelectedSourceTypes;

      final allSourcesResponse = await _sourcesRepository.readAll();
      final allAvailableSources = allSourcesResponse.items;

      // Initially, display all sources. Capsules are visually set but don't filter the list yet.
      // Filtering will occur if a capsule is manually toggled.
      // However, if initial capsule filters ARE provided, we should respect them for the initial display.
      final displayableSources = _getFilteredSources(
        allSources: allAvailableSources,
        selectedCountries: initialSelectedCountryIsoCodes,
        selectedTypes: initialSelectedSourceTypes,
      );

      emit(
        state.copyWith(
          availableCountries: availableCountries.items,
          allAvailableSources: allAvailableSources,
          displayableSources: displayableSources,
          finallySelectedSourceIds: initialSelectedSourceIds,
          selectedCountryIsoCodes: initialSelectedCountryIsoCodes,
          selectedSourceTypes: initialSelectedSourceTypes,
          dataLoadingStatus: SourceFilterDataLoadingStatus.success,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          dataLoadingStatus: SourceFilterDataLoadingStatus.failure,
          errorMessage: 'Failed to load filter criteria.',
        ),
      );
    }
  }

  Future<void> _onCountryCapsuleToggled(
    CountryCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) async {
    final currentSelected = Set<String>.from(state.selectedCountryIsoCodes);
    if (event.countryIsoCode.isEmpty) {
      // "All Countries" toggled
      // If "All" is tapped and it's already effectively "All" (empty set), or if it's tapped to select "All"
      // we clear the set. If specific items are selected and "All" is tapped, it also clears.
      // Essentially, tapping "All" always results in an empty set, meaning no country filter.
      currentSelected.clear();
    } else {
      // Specific country toggled
      if (currentSelected.contains(event.countryIsoCode)) {
        currentSelected.remove(event.countryIsoCode);
      } else {
        currentSelected.add(event.countryIsoCode);
      }
    }
    final newDisplayableSources = _getFilteredSources(
      allSources: state.allAvailableSources,
      selectedCountries: currentSelected,
      selectedTypes: state.selectedSourceTypes,
    );
    emit(
      state.copyWith(
        selectedCountryIsoCodes: currentSelected,
        displayableSources: newDisplayableSources,
      ),
    );
  }

  void _onAllSourceTypesCapsuleToggled(
    AllSourceTypesCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) {
    final newDisplayableSources = _getFilteredSources(
      allSources: state.allAvailableSources,
      selectedCountries: state.selectedCountryIsoCodes,
      selectedTypes: {},
    );
    emit(
      state.copyWith(
        selectedSourceTypes: {},
        displayableSources: newDisplayableSources,
      ),
    );
  }

  void _onSourceTypeCapsuleToggled(
    SourceTypeCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) {
    final currentSelected = Set<SourceType>.from(state.selectedSourceTypes);
    if (currentSelected.contains(event.sourceType)) {
      currentSelected.remove(event.sourceType);
    } else {
      currentSelected.add(event.sourceType);
    }
    final newDisplayableSources = _getFilteredSources(
      allSources: state.allAvailableSources,
      selectedCountries: state.selectedCountryIsoCodes,
      selectedTypes: currentSelected,
    );
    emit(
      state.copyWith(
        selectedSourceTypes: currentSelected,
        displayableSources: newDisplayableSources,
      ),
    );
  }

  void _onSourceCheckboxToggled(
    SourceCheckboxToggled event,
    Emitter<SourcesFilterState> emit,
  ) {
    final currentSelected = Set<String>.from(state.finallySelectedSourceIds);
    if (event.isSelected) {
      currentSelected.add(event.sourceId);
    } else {
      currentSelected.remove(event.sourceId);
    }
    emit(state.copyWith(finallySelectedSourceIds: currentSelected));
  }

  Future<void> _onClearSourceFiltersRequested(
    ClearSourceFiltersRequested event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCountryIsoCodes: {},
        selectedSourceTypes: {},
        finallySelectedSourceIds: {},
        displayableSources: List.from(state.allAvailableSources),
        dataLoadingStatus: SourceFilterDataLoadingStatus.success,
        clearErrorMessage: true,
      ),
    );
  }

  // Helper method to filter sources based on selected countries and types
  List<Source> _getFilteredSources({
    required List<Source> allSources,
    required Set<String> selectedCountries,
    required Set<SourceType> selectedTypes,
  }) {
    if (selectedCountries.isEmpty && selectedTypes.isEmpty) {
      return List.from(allSources);
    }

    return allSources.where((source) {
      final matchesCountry =
          selectedCountries.isEmpty ||
          (source.headquarters != null &&
              selectedCountries.contains(source.headquarters!.isoCode));
      final matchesType =
          selectedTypes.isEmpty ||
          (source.sourceType != null &&
              selectedTypes.contains(source.sourceType));
      return matchesCountry && matchesType;
    }).toList();
  }
}
