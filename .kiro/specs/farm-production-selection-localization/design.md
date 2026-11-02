# Design Document: Farm Production Selection Localization

## Introduction

This document describes the architecture and component-level design for full multilingual localization of the KhetChacha Farm Production Selection Screen across 13 languages: English (en), Hindi (hi), Punjabi (pa), Gujarati (gu), Marathi (mr), Tamil (ta), Telugu (te), Kannada (kn), Malayalam (ml), Bengali (bn), Odia (or), Assamese (as), and Urdu (ur).

Today the screen fully supports only English, Gujarati, and Hindi. All other languages fall back to English text and English crop names. The design extends three existing data/logic layers — `CropMasterDatabase` / `CropCategoryMeta`, `AppLocalizations`, and `CropAudioService` — and refactors the `FarmProductionSelectionPage` to remove hardcoded ternary chains in favor of the localization provider.

The codebase is a Flutter (Dart) application. All code examples in this document are written in Dart.

## Overview

The Farm Production Selection Screen lets a farmer pick the crops grown on their farm during onboarding and editing. The screen today renders correctly only in English, Gujarati, and Hindi; in the other 10 target languages the UI strings fall back to English and the crop names show as English.

This feature closes that gap across 13 languages:

`en, hi, pa, gu, mr, ta, te, kn, ml, bn, or, as, ur`

These 13 (`Supported_Language_Codes`) are a subset of the 23 codes already declared in `LanguageData.allLanguages` and `AppLocalizations.supportedLocales`. No new locales are added to those lists; this feature only ensures the crop-selection surface is fully translated for these 13.

The change is in-place and conservative: it extends three existing data/logic layers (`CropMasterDatabase` / `CropCategoryMeta`, `AppLocalizations`, `CropAudioService`) and refactors `FarmProductionSelectionPage` to remove hardcoded ternary chains. No new files, classes, or packages are introduced, and the existing onboarding selection rule ("never preselect any crop") is preserved.

## Goals and Non-Goals

### Goals

- Every one of the 300 crops carries a `LocalizedCropName` for all 13 languages.
- Every one of the 12 categories carries a localized title for all 13 languages.
- All UI strings rendered on the crop selection screen (title, subtitle, search hint, empty state, validation, helper, selected count, clear all, continue, voice-search dialog, identification help sheet, "I don't know the crop name" link) are sourced from `AppLocalizations` with translations for all 13 languages.
- Crop cards and selected chips display the native name as primary and the English canonical name as a small secondary label for non-English languages.
- `CropAudioService.resolveLocale` returns a BCP-47 locale for all 13 codes and falls back to English when a TTS voice is unavailable.

### Non-Goals

- Adding new locales to `LanguageData.allLanguages` or `AppLocalizations.supportedLocales`.
- Localizing screens other than the Farm Production Selection Screen.
- Translating the dashboard, farmer details, or OTP strings (already partially done; out of scope here).
- Changing the data model shape (still `Map<String, LocalizedCropName>`); only adding entries and fields.
- Replacing the static, compiled `CropMasterDatabase` with a runtime/remote data source.

## Architecture

The localization stack has four existing layers. This feature extends each in place without introducing new layers or abstractions:

1. **Data layer** — `CropMasterEntry` (model), `CropCategoryMeta` (category metadata), and `CropMasterDatabase` (the 300-crop static catalog). We extend the `names` map and the category title fields.
2. **String provider layer** — `AppLocalizations` (offline translation map keyed by language code). We add new keys and fill translations for the 13 languages.
3. **Audio layer** — `CropAudioService` (Text-to-Speech). We extend `resolveLocale` to cover bn/or/as/ur.
4. **Presentation layer** — `FarmProductionSelectionPage`. We replace inline `langCode == 'gu' ? ... : (langCode == 'hi' ? ... : ...)` ternary chains with `AppLocalizations` getter calls.

No new files, classes, or packages are introduced. The design is intentionally conservative to keep the diff reviewable and to preserve the existing onboarding selection rule ("never preselect any crop").

```
┌─────────────────────────────────────────────────────────────┐
│            FarmProductionSelectionPage (StatefulWidget)      │
│                                                               │
│  build() reads:                                                │
│   - loc = AppLocalizations.of(context)    ◄── string provider │
│   - langCode = LanguageService.currentLanguage.code           │
│   - CropMasterDatabase.categories[*].getTitle(langCode)        │
│   - crop.getLocalizedName(langCode)                           │
│   - crop.getSecondaryLabel(langCode)                          │
│   - CropAudioService.instance.speakCrop(crop, langCode)       │
└───────────────┬───────────────────────────┬───────────────────┘
                │                            │
                ▼                            ▼
┌──────────────────────────┐   ┌──────────────────────────────┐
│  CropMasterDatabase       │   │  AppLocalizations             │
│  - categories[12]         │   │  - _localizedValues[lang]     │
│    CropCategoryMeta       │   │    {key: translation}         │
│      + titlePa/Mr/Ta/...  │   │  - _t(key) → fallback to en   │
│  - masterCrops[300]       │   └──────────────────────────────┘
│    CropMasterEntry        │
│      names[lang] ◄ 13     │   ┌──────────────────────────────┐
│      LocalizedCropName    │   │  CropAudioService             │
│        name/aliases/trans │   │  - resolveLocale(langCode)    │
└──────────────────────────┘   │    → BCP-47 (13 codes + en)  │
                                │  - speakCrop fallback en-IN  │
                                └──────────────────────────────┘
```

## Components and Interfaces

### Component 1: CropCategoryMeta (Extended)

**File:** `lib/models/crop_master_entry.dart`

`CropCategoryMeta` currently holds `titleEn`, `titleGu`, `titleHi` and resolves via a two-branch `getTitle`. We add ten new optional title fields for the remaining target languages and extend `getTitle` to consult them.

```dart
class CropCategoryMeta {
  final String id;
  final String titleEn;
  final String titleGu;
  final String titleHi;
  // NEW: titles for the remaining 10 target languages.
  // Nullable so the existing "All (Popular)" and category entries can omit
  // a language without a compile error; getTitle falls back to English.
  final String? titlePa;
  final String? titleMr;
  final String? titleTa;
  final String? titleTe;
  final String? titleKn;
  final String? titleMl;
  final String? titleBn;
  final String? titleOr;
  final String? titleAs;
  final String? titleUr;
  final String iconEmoji;
  final int startNumber;
  final int endNumber;

  const CropCategoryMeta({
    required this.id,
    required this.titleEn,
    required this.titleGu,
    required this.titleHi,
    this.titlePa,
    this.titleMr,
    this.titleTa,
    this.titleTe,
    this.titleKn,
    this.titleMl,
    this.titleBn,
    this.titleOr,
    this.titleAs,
    this.titleUr,
    required this.iconEmoji,
    required this.startNumber,
    required this.endNumber,
  });

  /// Returns the localized title for [langCode], falling back to English
  /// when no translation exists for that language.
  String getTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return titleGu;
      case 'hi':
        return titleHi;
      case 'pa':
        return titlePa ?? titleEn;
      case 'mr':
        return titleMr ?? titleEn;
      case 'ta':
        return titleTa ?? titleEn;
      case 'te':
        return titleTe ?? titleEn;
      case 'kn':
        return titleKn ?? titleEn;
      case 'ml':
        return titleMl ?? titleEn;
      case 'bn':
        return titleBn ?? titleEn;
      case 'or':
        return titleOr ?? titleEn;
      case 'as':
        return titleAs ?? titleEn;
      case 'ur':
        return titleUr ?? titleEn;
      default:
        return titleEn;
    }
  }
}
```

**Design decisions:**

- New fields are nullable (`String?`) rather than required. This keeps the constructor backward compatible for any existing `CropCategoryMeta` instances outside the 12-category list (there are none today, but this protects against regressions) and makes the fallback rule explicit at the field level.
- `getTitle` uses a `switch` instead of the existing `if` chain. The switch is exhaustive over the 13 codes and routes unknown/default codes (including `en`) to `titleEn`, satisfying the English-fallback requirement (Req 2.3).
- All 12 category definitions in `CropMasterDatabase.categories` are updated to populate every new title field with a native translation. The "All (Popular)" category is included.

### Component 2: CropMasterEntry (Extended Names Map)

**File:** `lib/models/crop_master_entry.dart`

`CropMasterEntry.names` is already `Map<String, LocalizedCropName>`. The data model needs no structural change. The `getLocalizedName`, `getSecondaryLabel`, and `matchesQuery` methods already iterate over `names` generically, so once the map is populated for all 13 codes they work without modification.

**getSecondaryLabel** currently has special English-mode behavior (returns Gujarati or Hindi as the secondary label when active language is English). This conflicts with Requirement 4.2, which states that for non-English active languages the secondary label is the English canonical name. We refine the method:

```dart
/// Returns the secondary reference label shown beneath the primary name.
///
/// - English active language: no secondary label is needed, returns ''.
/// - Non-English active language: returns the English canonical name.
String getSecondaryLabel(String activeLangCode) {
  if (activeLangCode.toLowerCase() == 'en') {
    return '';
  }
  return canonicalNameEn;
}
```

**Rationale:** Requirement 4.2 says the secondary label is the English canonical name for non-English languages. The previous logic returned Gujarati/Hindi as a secondary when English was active, which contradicts the requirement that English is the *primary* (not secondary) label in English mode (Req 4.3). With English as primary, no secondary label is needed, so we return an empty string. The UI already handles an empty secondary label gracefully (it renders an empty `Text`).

`getLocalizedName` and `matchesQuery` are unchanged — they already operate generically over the `names` map. With all 13 entries present, search automatically matches across all 13 languages (Req 1.3) and the localized name resolves for any active language (Req 1.2, 4.1).

### Component 3: CropMasterDatabase (300 Crops × 13 Languages)

**File:** `lib/localization/crop_master_database.dart`

This is the largest data-extension task. Each of the 300 `CropMasterEntry` instances in `masterCrops` currently has `names` entries for `en`, `gu`, and `hi`. We add `LocalizedCropName` entries for `pa`, `mr`, `ta`, `te`, `kn`, `ml`, `bn`, `or`, `as`, and `ur` to every entry.

```dart
CropMasterEntry(
  cropId: 'CROP_001',
  itemNumber: 1,
  canonicalNameEn: 'Wheat',
  // ... unchanged fields ...
  names: {
    'en': LocalizedCropName(name: 'Wheat', aliases: [...], transliterations: [...]),
    'gu': LocalizedCropName(name: 'ઘઉં',   aliases: [...], transliterations: [...]),
    'hi': LocalizedCropName(name: 'गेहूं',  aliases: [...], transliterations: [...]),
    // NEW: 10 additional languages
    'pa': LocalizedCropName(name: 'ਕਣਕ',    aliases: [...], transliterations: [...]),
    'mr': LocalizedCropName(name: 'गहू',     aliases: [...], transliterations: [...]),
    'ta': LocalizedCropName(name: 'கோதுமை', aliases: [...], transliterations: [...]),
    'te': LocalizedCropName(name: 'గోధుమ',   aliases: [...], transliterations: [...]),
    'kn': LocalizedCropName(name: 'ಗೋಧಿ',    aliases: [...], transliterations: [...]),
    'ml': LocalizedCropName(name: 'ഗോതമ്പ്', aliases: [...], transliterations: [...]),
    'bn': LocalizedCropName(name: 'গম',     aliases: [...], transliterations: [...]),
    'or': LocalizedCropName(name: 'ଗହଁ',    aliases: [...], transliterations: [...]),
    'as': LocalizedCropName(name: 'গম',     aliases: [...], transliterations: [...]),
    'ur': LocalizedCropName(name: 'گندم',   aliases: [...], transliterations: [...]),
  },
  // ...
),
```

**Translation sourcing & consistency rules:**

- Each crop's native `name` is the primary regional term for that language. Where a single crop has multiple regional names, the most widely understood term is chosen as `name` and the rest go into `aliases`.
- `aliases` carry regional synonyms (the existing Gujarati/Hindi aliases are preserved; new-language aliases are added where regional variants exist).
- `transliterations` are Roman-script forms that help the search match typed queries. The existing transliterations (largely shared across languages, e.g. `gehu`, `kanak`) are reused for the new languages since they represent the same phonetic terms. This keeps `searchKeywords` and `matchesQuery` behavior consistent.
- `imageAltText` is extended only for languages where a translated description adds value. Alt text already falls back to English via `getAltText`, so this is a non-blocking enhancement; the requirement does not mandate alt text for all 13 languages.

**Category titles:** Each of the 12 `CropCategoryMeta` entries in `categories` is updated to populate all ten new `titleXx` fields with the native category name (e.g. "Vegetables" → `titleTa: 'காய்கறிகள்'`).

### Component 4: AppLocalizations (New UI String Keys)

**File:** `lib/localization/app_localizations.dart`

The screen currently hardcodes several strings inside ternary chains. We extract these into keyed translations and add getters. The existing farm-production keys (`selectFarmProductionTitle`, `selectFarmProductionSubtitle`, `searchCropsHint`, `selectedCount`, `clearAll`, `selectAtLeastOneHint`, `continueToDashboard`, `moreProducts`, and the `category*` keys) already exist for `en`, `gu`, and `hi`. We add new keys for the strings that are still hardcoded and fill all 13 languages for every farm-production key.

**New keys and getters:**

```dart
// Voice Search dialog
String get voiceSearchTitle => _t('voiceSearchTitle');
String get voiceSearchInstruction => _t('voiceSearchInstruction');
String get voiceSearchSampleCrops => _t('voiceSearchSampleCrops');

// Crop Identification Help sheet
String get identificationHelpTitle => _t('identificationHelpTitle');
String get identificationHelpGuidance => _t('identificationHelpGuidance');
String get identificationHelpKharifTitle => _t('identificationHelpKharifTitle');
String get identificationHelpKharifSubtitle => _t('identificationHelpKharifSubtitle');
String get identificationHelpRabiTitle => _t('identificationHelpRabiTitle');
String get identificationHelpRabiSubtitle => _t('identificationHelpRabiSubtitle');
String get identificationHelpExpertTitle => _t('identificationHelpExpertTitle');
String get identificationHelpExpertSubtitle => _t('identificationHelpExpertSubtitle');
String get identificationHelpExpertSnackbar => _t('identificationHelpExpertSnackbar');

// "I don't know the crop name" link
String get dontKnowCropName => _t('dontKnowCropName');

// Empty search state
String get noCropsFoundMsg => _t('noCropsFoundMsg');

// Validation snackbar (crop selection required) — distinct from the generic
// selectAtLeastOneHint; this is the longer snackbar message.
String get selectCropValidationMsg => _t('selectCropValidationMsg');
```

The `_t` method already provides English fallback: when a key is absent for the active language it returns `_localizedValues['en']![key] ?? key`. This satisfies Requirement 3.5 without further code changes. To satisfy Requirement 3.2 (a translated value in every supported language), each of the 13 language maps is populated with a non-empty value for every farm-production key — including the existing keys that today only have `en`/`gu`/`hi`.

**Sample crop names in the voice search dialog** are currently hardcoded as `'Wheat (ઘઉં)'` style mixed strings. We replace these with localized sample strings via a keyed value (`voiceSearchSampleCrops`) so the chips render in the active language. The chip's tap behavior splits on the first space to derive a search term; we preserve that contract by keeping the transliterated/English token first in each sample string.

### Component 5: FarmProductionSelectionPage (Refactor)

**File:** `lib/screens/farm_production_selection_page.dart`

The page already reads `loc = AppLocalizations.of(context)` and `langCode` in `build()`. Several widget subtrees still use inline ternaries. We replace each with the corresponding `loc` getter. The changes are mechanical and localized to the string-producing expressions:

| Current inline expression | Replaced with |
|---|---|
| `langCode == 'gu' ? 'બોલીને પાક શોધો' : (langCode == 'hi' ? 'बोलकर फसल खोजें' : 'Voice Crop Search')` | `loc.voiceSearchTitle` |
| `langCode == 'gu' ? 'તમારા પાકનું નામ બોલો...' : (langCode == 'hi' ? 'अपनी फसल...' : 'Say your crop name...')` | `loc.voiceSearchInstruction` |
| Hardcoded `['Wheat (ઘઉં)', ...]` sample chips | `loc.voiceSearchSampleCrops` (split into list) |
| `langCode == 'gu' ? 'બંધ કરો' : 'Close'` | `loc.closeButton` (already exists) |
| `langCode == 'gu' ? 'પાક પસંદ કરવામાં મદદ' : (langCode == 'hi' ? 'फसल चुनने में सहायता' : 'Crop Identification Help')` | `loc.identificationHelpTitle` |
| Help sheet guidance text ternary | `loc.identificationHelpGuidance` |
| Kharif/Rabi/Expert `title` and `subtitle` ternaries | `loc.identificationHelpKharifTitle`, etc. |
| Expert snackbar hardcoded string | `loc.identificationHelpExpertSnackbar` |
| `langCode == 'gu' ? 'મને પાકનું નામ ખબર નથી' : (langCode == 'hi' ? 'मुझे फसल का नाम नहीं पता' : "I don't know the crop name")` | `loc.dontKnowCropName` |
| Title ternary (`'તમે તમારા ખેતરમાં...' / 'आप अपने खेत...' / loc.selectFarmProductionTitle`) | `loc.selectFarmProductionTitle` |
| Subtitle ternary | `loc.selectFarmProductionSubtitle` |
| Search hint ternary | `loc.searchCropsHint` |
| `langCode == 'gu' ? 'કોઈ પાક મળ્યો નથી' : 'No crops found matching your search'` | `loc.noCropsFoundMsg` |
| Selected-count ternary | `loc.selectedCount(selectedCount)` |
| Clear-all ternary | `loc.clearAll` |
| Helper note ternary | `loc.selectAtLeastOneHint` |
| Validation snackbar ternary | `loc.selectCropValidationMsg` |

The category tab label already calls `cat.getTitle(langCode)`, which now resolves for all 13 languages via the extended `CropCategoryMeta`. Crop card primary/secondary labels already call `crop.getLocalizedName(langCode)` and `crop.getSecondaryLabel(langCode)`, which now return native/English correctly for all 13 languages. The selected-crop chips already call `c.getLocalizedName(langCode)`, so they localize automatically (Req 5.1) and fall back to English when a name is absent (Req 5.2, via the existing `getLocalizedName` fallback).

**Selection rule preserved:** The refactor only touches string expressions. The `_selectedCropIds` logic, `_onContinueToDashboard` validation, and the "never preselect" rule in `initState` are untouched.

### Component 6: CropAudioService (Extended resolveLocale)

**File:** `lib/services/crop_audio_service.dart`

`resolveLocale` currently returns BCP-47 codes for 9 languages and defaults to `en-IN`. We add the four missing codes (`bn`, `or`, `as`, `ur`) so all 13 supported codes resolve:

```dart
String resolveLocale(String langCode) {
  switch (langCode.toLowerCase()) {
    case 'gu':
      return 'gu-IN';
    case 'hi':
      return 'hi-IN';
    case 'mr':
      return 'mr-IN';
    case 'pa':
      return 'pa-IN';
    case 'ta':
      return 'ta-IN';
    case 'te':
      return 'te-IN';
    case 'kn':
      return 'kn-IN';
    case 'ml':
      return 'ml-IN';
    case 'bn':
      return 'bn-IN';
    case 'or':
      return 'or-IN';
    case 'as':
      return 'as-IN';
    case 'ur':
      return 'ur-IN';
    case 'en':
    default:
      return 'en-IN';
  }
}
```

The existing `speakCrop` fallback already wraps `setLanguage(targetLocale)` in a try/catch that falls back to `setLanguage('en-IN')` when the regional voice is unavailable. This satisfies Requirement 6.3 without additional code. With `resolveLocale` now covering all 13 codes, Requirement 6.1 is met and `speakCrop` sets the correct locale for each (Req 6.2).

## Data Models

### LocalizedCropName (unchanged)

```dart
class LocalizedCropName {
  final String name;
  final List<String> aliases;
  final List<String> transliterations;
  // constructor, toJson, fromJson unchanged
}
```

No structural change. Each crop simply has more entries in its `names` map.

### CropMasterEntry.names map (extended cardinality)

| Before | After |
|---|---|
| 3 entries: `en`, `gu`, `hi` | 13 entries: `en`, `hi`, `pa`, `gu`, `mr`, `ta`, `te`, `kn`, `ml`, `bn`, `or`, `as`, `ur` |

### CropCategoryMeta title fields (extended)

| Before | After |
|---|---|
| 3 title fields: `titleEn`, `titleGu`, `titleHi` | 13 title fields: above + `titlePa`, `titleMr`, `titleTa`, `titleTe`, `titleKn`, `titleMl`, `titleBn`, `titleOr`, `titleAs`, `titleUr` |

### AppLocalizations keys (extended)

The farm-production key set grows from the existing ~9 keys to ~22 keys (adding the voice-search, identification-help, don't-know, no-crops-found, and validation keys listed in Component 4). Every key is populated in all 13 language maps.

## Interfaces

The interface surface is unchanged in signature; only implementations and data are extended.

### Public API surface (no signature changes)

- `CropCategoryMeta.getTitle(String langCode) → String` — signature unchanged; now resolves 13 codes.
- `CropMasterEntry.getLocalizedName(String langCode) → String` — unchanged; works for 13 codes via the populated map.
- `CropMasterEntry.getSecondaryLabel(String activeLangCode) → String` — signature unchanged; semantics refined (returns `''` for English, `canonicalNameEn` otherwise).
- `CropMasterEntry.matchesQuery(String query) → bool` — unchanged; iterates all populated names.
- `CropAudioService.resolveLocale(String langCode) → String` — unchanged; now covers 13 codes.
- `AppLocalizations` getters — existing getters unchanged; new getters added (see Component 4).

No caller signatures change. `FarmProductionSelectionPage` calls the same methods; it simply stops branching on `langCode` for strings.

## Error Handling

### Missing crop name (Req 1.2, 5.2)

`getLocalizedName` already returns `canonicalNameEn` when `names` lacks the active language key. With all 13 entries populated this path is only hit for codes outside the 13 (e.g. `brx`, `sa`). The fallback remains as a safety net.

### Missing category title (Req 2.3)

`getTitle` returns `titleEn` for any unrecognized code and for any of the 10 new fields that are `null`. Since all 12 categories populate all 13 fields, `null` only occurs if a future category is added without filling every field.

### Missing UI translation (Req 3.5)

`_t(key)` returns the English value when the key is absent from the active language map, and returns the key itself only if it is absent from English too. With every farm-production key present in all 13 language maps, the English fallback is a last resort.

### TTS voice unavailable (Req 6.3)

`speakCrop` wraps `setLanguage(targetLocale)` in try/catch and calls `setLanguage('en-IN')` on failure. `MissingPluginException` (headless/test environments) is caught separately and transitions the service to `idle` gracefully. No uncaught exceptions reach the UI.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

The following properties were derived from the acceptance criteria prework and redundancy-reflection analysis. Properties 1–7 are universal quantifications suitable for property-based testing of the pure data/logic layers. UI-interaction and external-service criteria (Req 3.1, 3.3, 3.4, 5.1, 6.2, 6.3) are covered by example-based and integration tests rather than properties, as noted in the testing strategy.

### Property 1: Crop name data completeness

*For any* crop in `CropMasterDatabase.masterCrops` and *for any* of the 13 `Supported_Language_Codes`, the crop's `names` map SHALL contain an entry for that language code with a non-empty `name`.

**Validates: Requirements 1.1**

### Property 2: Crop name fallback to English

*For any* crop in `CropMasterDatabase.masterCrops` and *for any* language code not present in the crop's `names` map, `getLocalizedName(langCode)` SHALL return the crop's `canonicalNameEn`.

**Validates: Requirements 1.2, 5.2**

### Property 3: Search matches all localized forms

*For any* crop in `CropMasterDatabase.masterCrops`, *for any* of the 13 `Supported_Language_Codes` present in the crop's `names` map, and *for any* string equal to that language entry's `name`, one of its `aliases`, or one of its `transliterations`, `matchesQuery` SHALL return `true`.

**Validates: Requirements 1.3**

### Property 4: Category title completeness and resolution

*For any* category in `CropMasterDatabase.categories` and *for any* of the 13 `Supported_Language_Codes`, `getTitle(langCode)` SHALL return a non-empty string; when the category has a title for that language it SHALL return that title, and *for any* language code without a title it SHALL return `titleEn`.

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 5: UI string localization completeness and fallback

*For any* UI string key used by the Farm Production Selection Screen and *for any* of the 13 `Supported_Language_Codes`, `AppLocalizations` SHALL return a non-empty value; when the active language lacks the key it SHALL return the English value.

**Validates: Requirements 3.2, 3.5**

### Property 6: Primary and secondary name resolution

*For any* crop in `CropMasterDatabase.masterCrops`: when the active language is English, `getLocalizedName('en')` SHALL return `canonicalNameEn` and `getSecondaryLabel('en')` SHALL return an empty string; *for any* non-English `Supported_Language_Code`, `getLocalizedName(langCode)` SHALL return the native localized name and `getSecondaryLabel(langCode)` SHALL return `canonicalNameEn`.

**Validates: Requirements 4.1, 4.2, 4.3, 5.1**

### Property 7: TTS locale resolution

*For any* of the 13 `Supported_Language_Codes`, `CropAudioService.resolveLocale(langCode)` SHALL return a non-empty BCP-47 locale string containing a hyphen, and English SHALL resolve to `en-IN`.

**Validates: Requirements 6.1**

## Testing Strategy

### Property-based tests (pure logic/data layers)

The properties above target in-memory, deterministic code with large input spaces (300 crops × 13 languages, 12 categories × 13 languages, ~22 keys × 13 languages). These are cost-effective to run at 100+ iterations each. Generators:

- **Crop generator:** pick a random `CropMasterEntry` from `masterCrops` by index.
- **Language code generator:** pick from the fixed `Supported_Language_Codes` list.
- **Localized-form generator:** from a chosen crop+language, pick `name`, a random `aliases` element, or a random `transliterations` element.
- **Unsupported-language generator:** pick a code outside the 13 (e.g. `brx`, `sa`, `xx`) to exercise fallback paths.
- **Category generator:** pick a random `CropCategoryMeta` from `categories` by index.

Minimum 100 iterations per property test. Each test tags its design property: `**Feature: farm-production-selection-localization, Property N: <text>**`.

### Example-based / integration tests (UI and external-service layers)

These criteria do not vary meaningfully with input or depend on external services, so they use 1–3 representative examples rather than property tests:

- **Req 3.1, 3.3, 3.4 (UI string sourcing):** Widget tests that build `FarmProductionSelectionPage` with a given locale, open the voice-search dialog and the identification-help sheet, and assert the rendered `Text` widgets match `AppLocalizations` getters for that locale (example locales: `ta`, `bn`).
- **Req 5.1 (selected chip rendering):** Widget test that selects a crop and asserts the chip's `Text` equals `crop.getLocalizedName(langCode)`.
- **Req 6.2, 6.3 (TTS integration):** Mock `FlutterTts` so `setLanguage` records its argument; trigger `speakCrop` with a regional locale and assert the recorded locale equals `resolveLocale(langCode)`. For the fallback case, make `setLanguage` throw for a regional locale and assert it is subsequently called with `en-IN`.

### Smoke test

- A single test asserts the app still builds and the crop-selection screen renders without exceptions for one English and one non-English locale (e.g. `ur`), guarding against regressions introduced by the data extension.

## Testing Strategy Summary

| Requirement | Test type | Count |
|---|---|---|
| 1.1 | Property (Property 1) | 100+ iterations |
| 1.2, 5.2 | Property (Property 2) | 100+ iterations |
| 1.3 | Property (Property 3) | 100+ iterations |
| 2.1, 2.2, 2.3 | Property (Property 4) | 100+ iterations |
| 3.1 | Example widget test | 1–2 |
| 3.2, 3.5 | Property (Property 5) | 100+ iterations |
| 3.3 | Example widget test | 1–2 |
| 3.4 | Example widget test | 1–2 |
| 4.1, 4.2, 4.3, 5.1 | Property (Property 6) | 100+ iterations |
| 6.1 | Property (Property 7) | 13 cases (one per code) |
| 6.2, 6.3 | Integration test (mocked TTS) | 1–2 |
