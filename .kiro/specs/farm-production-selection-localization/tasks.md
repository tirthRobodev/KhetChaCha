# Implementation Plan: Farm Production Selection Localization

## Overview

This plan localizes the KhetChacha Farm Production Selection Screen across 13 languages (en, hi, pa, gu, mr, ta, te, kn, ml, bn, or, as, ur). The work extends three existing data/logic layers in place — `CropCategoryMeta` / `CropMasterEntry` (model), `CropMasterDatabase` (data), `AppLocalizations` (strings) — refactors `CropAudioService.resolveLocale` for four missing codes, and replaces all hardcoded ternary string chains in `FarmProductionSelectionPage` with `AppLocalizations` getter calls. No new files, classes, or packages are introduced.

The implementation proceeds bottom-up: model fields first, then the large data-population pass (category titles + 300 crops × 10 new languages), then the string provider and audio service, and finally the page refactor that wires everything together. Property-based tests for the seven correctness properties are placed close to the implementations they validate so errors are caught early.

## Tasks

- [ ] 1. Extend CropCategoryMeta and CropMasterEntry model
  - [ ] 1.1 Add 10 nullable title fields and update getTitle() to a 13-code switch
    - In `lib/models/crop_master_entry.dart`, add nullable `String?` fields to `CropCategoryMeta`: `titlePa`, `titleMr`, `titleTa`, `titleTe`, `titleKn`, `titleMl`, `titleBn`, `titleOr`, `titleAs`, `titleUr` (all optional in the constructor)
    - Replace the existing two-branch `if` chain in `getTitle` with a `switch (langCode.toLowerCase())` that returns the matching title for each of the 13 codes (`gu`, `hi`, `pa`, `mr`, `ta`, `te`, `kn`, `ml`, `bn`, `or`, `as`, `ur`), coalescing each new field with `?? titleEn`, and defaulting unknown/`en` codes to `titleEn`
    - Keep `titleEn`, `titleGu`, `titleHi` and `iconEmoji`/`startNumber`/`endNumber` as required constructor params so existing call sites stay valid
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 1.2 Refine getSecondaryLabel() for English-primary semantics
    - In `lib/models/crop_master_entry.dart`, replace the `getSecondaryLabel` body: when the active language is English return an empty string (`''`); otherwise return `canonicalNameEn`
    - Remove the old logic that returned Gujarati/Hindi as a secondary when English was active, since English is now the primary label in English mode and needs no secondary
    - The UI already renders an empty secondary `Text` gracefully, so no UI change is needed for the empty-string case
    - _Requirements: 4.2, 4.3_

- [ ] 2. Populate category titles in CropMasterDatabase
  - [ ] 2.1 Populate all 12 category definitions with 10 new localized titles
    - In `lib/localization/crop_master_database.dart`, for each of the 12 `CropCategoryMeta` entries in `categories` (including "All (Popular)"), populate the 10 new `titleXx` fields with the native category name for that language (e.g. "Vegetables" → `titleTa: 'காய்கறிகள்'`)
    - Use the most widely understood regional term as the title; existing `titleEn`/`titleGu`/`titleHi` values are preserved unchanged
    - Verify the file still compiles after the field additions from task 1.1
    - _Requirements: 2.1_
  - [ ]* 2.2 Write property test for category title completeness and resolution
    - **Property 4: Category title completeness and resolution**
    - **Validates: Requirements 2.1, 2.2, 2.3**
    - In `test/crop_localization_test.dart`, write a property test that for any category in `CropMasterDatabase.categories` and any of the 13 supported language codes, `getTitle(langCode)` returns a non-empty string; when a title exists for that language it returns that title, and for any code without a title it returns `titleEn`
    - Tag the test: `**Feature: farm-production-selection-localization, Property 4: Category title completeness and resolution**`
    - Run at least 100 iterations picking a random category index and a random language code from `Supported_Language_Codes`

- [ ] 3. Populate crop name translations in CropMasterDatabase
  - [ ] 3.1 Add 10 language translations to crops 1–75 (Cereals, Pulses, Oilseeds, Commercial Fibre)
    - In `lib/localization/crop_master_database.dart`, for every `CropMasterEntry` with `itemNumber` 1–75, add `LocalizedCropName` entries for `pa`, `mr`, `ta`, `te`, `kn`, `ml`, `bn`, `or`, `as`, `ur` to the `names` map (existing `en`/`gu`/`hi` entries are preserved)
    - Each entry's `name` is the primary regional term; regional synonyms go in `aliases`; reuse existing shared transliterations (e.g. `gehu`, `kanak`) in `transliterations` so search behavior stays consistent
    - _Requirements: 1.1_
  - [ ] 3.2 Add 10 language translations to crops 76–180 (Vegetables, Fruits)
    - In `lib/localization/crop_master_database.dart`, for every `CropMasterEntry` with `itemNumber` 76–180, add `LocalizedCropName` entries for the 10 new languages following the same name/aliases/transliterations conventions as 3.1
    - _Requirements: 1.1_
  - [ ] 3.3 Add 10 language translations to crops 181–300 (Spices, Medicinal, Flowers, Fodder, Plantation)
    - In `lib/localization/crop_master_database.dart`, for every `CropMasterEntry` with `itemNumber` 181–300, add `LocalizedCropName` entries for the 10 new languages following the same conventions as 3.1
    - After this step every crop in `masterCrops` has a `names` entry for all 13 supported language codes
    - _Requirements: 1.1_
  - [ ]* 3.4 Write property test for crop name data completeness
    - **Property 1: Crop name data completeness**
    - **Validates: Requirements 1.1**
    - In `test/crop_localization_test.dart`, write a property test that for any crop in `CropMasterDatabase.masterCrops` and any of the 13 supported language codes, the crop's `names` map contains an entry for that code with a non-empty `name`
    - Tag the test: `**Feature: farm-production-selection-localization, Property 1: Crop name data completeness**`
    - Run at least 100 iterations picking a random crop index and a random language code
  - [ ]* 3.5 Write property test for search matches all localized forms
    - **Property 3: Search matches all localized forms**
    - **Validates: Requirements 1.3**
    - In `test/crop_localization_test.dart`, write a property test that for any crop, any of the 13 supported language codes present in its `names` map, and any string equal to that language entry's `name`, one of its `aliases`, or one of its `transliterations`, `matchesQuery` returns `true`
    - Tag the test: `**Feature: farm-production-selection-localization, Property 3: Search matches all localized forms**`
    - Run at least 100 iterations; pick a random crop, a random language code from its `names` keys, and a random form (name/alias/transliteration)
  - [ ]* 3.6 Write property test for crop name fallback to English
    - **Property 2: Crop name fallback to English**
    - **Validates: Requirements 1.2, 5.2**
    - In `test/crop_localization_test.dart`, write a property test that for any crop and any language code not present in the crop's `names` map (use unsupported codes like `brx`, `sa`, `xx`), `getLocalizedName(langCode)` returns the crop's `canonicalNameEn`
    - Tag the test: `**Feature: farm-production-selection-localization, Property 2: Crop name fallback to English**`
    - Run at least 100 iterations picking a random crop and a random unsupported language code
  - [ ]* 3.7 Write property test for primary and secondary name resolution
    - **Property 6: Primary and secondary name resolution**
    - **Validates: Requirements 4.1, 4.2, 4.3, 5.1**
    - In `test/crop_localization_test.dart`, write a property test that for any crop: when the active language is English, `getLocalizedName('en')` returns `canonicalNameEn` and `getSecondaryLabel('en')` returns an empty string; for any non-English supported language code, `getLocalizedName(langCode)` returns the native localized name and `getSecondaryLabel(langCode)` returns `canonicalNameEn`
    - Tag the test: `**Feature: farm-production-selection-localization, Property 6: Primary and secondary name resolution**`
    - Run at least 100 iterations picking a random crop and a random language code

- [ ] 4. Checkpoint - Ensure data layer tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Extend AppLocalizations with new keys and full 13-language coverage
  - [ ] 5.1 Add new UI string keys and getters
    - In `lib/localization/app_localizations.dart`, add getters for the new farm-production keys: `voiceSearchTitle`, `voiceSearchInstruction`, `voiceSearchSampleCrops`, `identificationHelpTitle`, `identificationHelpGuidance`, `identificationHelpKharifTitle`, `identificationHelpKharifSubtitle`, `identificationHelpRabiTitle`, `identificationHelpRabiSubtitle`, `identificationHelpExpertTitle`, `identificationHelpExpertSubtitle`, `identificationHelpExpertSnackbar`, `dontKnowCropName`, `noCropsFoundMsg`, `selectCropValidationMsg`
    - Each getter returns `_t('<key>')`; the existing `_t` English-fallback mechanism already satisfies the missing-translation requirement
    - _Requirements: 3.1, 3.2, 3.5_
  - [ ] 5.2 Fill all 13 language maps for every farm-production key
    - In `lib/localization/app_localizations.dart`, add a non-empty translated value for every farm-production key (the existing ~9 keys plus the new keys from 5.1) in all 13 language maps (`en`, `hi`, `pa`, `gu`, `mr`, `ta`, `te`, `kn`, `ml`, `bn`, `or`, `as`, `ur`)
    - For the `voiceSearchSampleCrops` value, keep the transliterated/English token first in each sample string so the existing chip tap behavior (split on first space) keeps working
    - _Requirements: 3.2, 3.5_
  - [ ]* 5.3 Write property test for UI string localization completeness and fallback
    - **Property 5: UI string localization completeness and fallback**
    - **Validates: Requirements 3.2, 3.5**
    - In `test/crop_localization_test.dart`, write a property test that for any farm-production UI string key and any of the 13 supported language codes, `AppLocalizations` returns a non-empty value; when the active language lacks the key it returns the English value
    - Tag the test: `**Feature: farm-production-selection-localization, Property 5: UI string localization completeness and fallback**`
    - Run at least 100 iterations over the key set and language codes

- [ ] 6. Extend CropAudioService resolveLocale for four missing codes
  - [ ] 6.1 Add bn, or, as, ur BCP-47 locales to resolveLocale()
    - In `lib/services/crop_audio_service.dart`, add `case 'bn': return 'bn-IN'`, `case 'or': return 'or-IN'`, `case 'as': return 'as-IN'`, and `case 'ur': return 'ur-IN'` to the `resolveLocale` switch so all 13 supported codes resolve
    - The existing `speakCrop` try/catch already falls back to `en-IN` when the regional voice is unavailable, satisfying the fallback requirement without further changes
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ]* 6.2 Write property test for TTS locale resolution
    - **Property 7: TTS locale resolution**
    - **Validates: Requirements 6.1**
    - In `test/crop_localization_test.dart`, write a test that for each of the 13 supported language codes, `CropAudioService.instance.resolveLocale(langCode)` returns a non-empty BCP-47 locale string containing a hyphen, and that English resolves to `en-IN`
    - Tag the test: `**Feature: farm-production-selection-localization, Property 7: TTS locale resolution**`
    - Cover all 13 codes explicitly (one assertion per code)
  - [ ]* 6.3 Write integration test for TTS setLanguage and fallback
    - In `test/crop_audio_service_test.dart`, mock `FlutterTts` so `setLanguage` records its argument; trigger `speakCrop` with a regional locale and assert the recorded locale equals `resolveLocale(langCode)`
    - For the fallback case, make `setLanguage` throw for a regional locale and assert it is subsequently called with `en-IN`
    - _Requirements: 6.2, 6.3_

- [ ] 7. Refactor FarmProductionSelectionPage to use AppLocalizations getters
  - [ ] 7.1 Replace all hardcoded ternary string expressions with loc.xxx getters
    - In `lib/screens/farm_production_selection_page.dart`, replace every inline `langCode == 'gu' ? ... : (langCode == 'hi' ? ... : ...)` ternary chain with the corresponding `AppLocalizations` getter call: screen title/subtitle → `loc.selectFarmProductionTitle`/`loc.selectFarmProductionSubtitle`; search hint → `loc.searchCropsHint`; empty state → `loc.noCropsFoundMsg`; selected count → `loc.selectedCount(count)`; clear all → `loc.clearAll`; helper note → `loc.selectAtLeastOneHint`; validation snackbar → `loc.selectCropValidationMsg`; "I don't know the crop name" link → `loc.dontKnowCropName`
    - Replace voice-search dialog strings: title → `loc.voiceSearchTitle`, instruction → `loc.voiceSearchInstruction`, sample chips → `loc.voiceSearchSampleCrops` (split into list), close button → `loc.closeButton`
    - Replace identification-help sheet strings: title → `loc.identificationHelpTitle`, guidance → `loc.identificationHelpGuidance`, Kharif/Rabi/Expert titles and subtitles → `loc.identificationHelpKharifTitle` etc., expert snackbar → `loc.identificationHelpExpertSnackbar`
    - Do not touch `_selectedCropIds` logic, `_onContinueToDashboard` validation, or the "never preselect" rule in `initState`; only string-producing expressions change
    - Category tab labels already call `cat.getTitle(langCode)` and crop cards/chips already call `crop.getLocalizedName(langCode)` / `crop.getSecondaryLabel(langCode)`, so they localize automatically once the data from tasks 1–3 is in place
    - _Requirements: 3.1, 3.3, 3.4, 5.1, 5.2_
  - [ ]* 7.2 Write widget tests for UI string sourcing
    - In `test/farm_production_selection_test.dart`, write widget tests that build `FarmProductionSelectionPage` with a given locale (example locales: `ta`, `bn`), open the voice-search dialog and the identification-help sheet, and assert the rendered `Text` widgets match `AppLocalizations` getters for that locale
    - _Requirements: 3.1, 3.3, 3.4_
  - [ ]* 7.3 Write widget test for selected crop chip rendering
    - In `test/farm_production_selection_test.dart`, write a widget test that selects a crop and asserts the chip's `Text` equals `crop.getLocalizedName(langCode)` for the active locale, and falls back to the English canonical name when no native name exists
    - _Requirements: 5.1, 5.2_
  - [ ]* 7.4 Write smoke test for screen rendering
    - In `test/farm_production_selection_test.dart`, write a single smoke test asserting the app still builds and the crop-selection screen renders without exceptions for one English and one non-English locale (e.g. `ur`), guarding against regressions introduced by the data extension
    - _Requirements: 1.1, 2.1, 3.2_

- [ ] 8. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- The implementation is conservative and in-place: no new files, classes, or packages are introduced beyond the test files
- Property tests validate universal correctness properties over the large input space (300 crops × 13 languages, 12 categories × 13 languages, ~22 keys × 13 languages); widget and integration tests cover UI and external-service criteria that do not vary meaningfully with input
- The crop data population (tasks 3.1–3.3) is split by category ranges so each step is reviewable and the file is edited sequentially
- All property tests live in `test/crop_localization_test.dart`; widget tests live in `test/farm_production_selection_test.dart`; the TTS integration test lives in `test/crop_audio_service_test.dart`

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "3.1", "5.1", "6.1"] },
    { "id": 1, "tasks": ["1.2", "2.1", "5.2", "6.2", "6.3"] },
    { "id": 2, "tasks": ["2.2", "3.2"] },
    { "id": 3, "tasks": ["3.3", "5.3"] },
    { "id": 4, "tasks": ["3.4", "7.1"] },
    { "id": 5, "tasks": ["3.5", "7.2"] },
    { "id": 6, "tasks": ["3.6", "7.3"] },
    { "id": 7, "tasks": ["3.7", "7.4"] }
  ]
}
```
