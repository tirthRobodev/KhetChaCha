# Requirements Document

## Introduction

This feature delivers complete multilingual localization of the KhetChacha Farm Production Selection Screen, the onboarding and edit screen where Indian farmers select the crops they grow. Today the screen fully supports only English, Gujarati, and Hindi; all other languages fall back to English text and English crop names. The goal is to localize crop names, category tabs, screen UI strings, selected-crop chips, and Text-to-Speech language selection across 13 languages — English (en), Hindi (hi), Punjabi (pa), Gujarati (gu), Marathi (mr), Tamil (ta), Telugu (te), Kannada (kn), Malayalam (ml), Bengali (bn), Odia (or), Assamese (as), and Urdu (ur) — so that a farmer who cannot read English can recognize, search, select, and hear crops entirely in their native language. English remains available as a small secondary reference label beneath each native crop name.

## Glossary

- **KhetChacha**: The farming advisory application being localized.
- **Farm_Production_Selection_Screen**: The onboarding and edit screen where a farmer selects the crops grown on their farm.
- **CropMasterDatabase**: The static catalog of 300 crops across 11 categories plus the "All (Popular)" category.
- **CropMasterEntry**: The data model representing a single crop, holding a map of localized names keyed by language code.
- **LocalizedCropName**: A localized crop name together with its regional aliases and Roman transliterations for one language.
- **CropCategoryMeta**: The metadata for one crop category, including its localized title, icon emoji, and crop-number range.
- **AppLocalizations**: The offline translation provider that returns UI strings keyed by the active locale language code.
- **CropAudioService**: The Text-to-Speech service that speaks a crop name aloud in the active language.
- **LanguageService**: The persisted application language preference provider.
- **Supported_Language_Codes**: The set of 13 language codes requiring localization: en, hi, pa, gu, mr, ta, te, kn, ml, bn, or, as, ur.
- **Primary_Name**: The crop name displayed prominently in the farmer's selected native language.
- **Secondary_Label**: The small English reference label shown beneath the Primary_Name.
- **TTS_Locale**: The BCP-47 locale code passed to the Text-to-Speech engine for a given language.

## Requirements

### Requirement 1: Crop Name Localization Data

**User Story:** As a farmer who cannot read English, I want every crop name shown in my own language, so that I can recognize and select the crops I grow.

#### Acceptance Criteria

1. THE CropMasterDatabase SHALL store a LocalizedCropName for each of the 300 crops in every Supported_Language_Code.
2. WHERE a crop has no LocalizedCropName for the active language, THE CropMasterEntry SHALL return the English canonical name as the displayed name.
3. WHEN a farmer searches crops, THE CropMasterEntry SHALL match the query against the name, aliases, and transliterations of all 13 Supported_Language_Codes.

### Requirement 2: Crop Category Tab Localization

**User Story:** As a farmer, I want category tabs labeled in my language, so that I can browse crop categories I understand.

#### Acceptance Criteria

1. THE CropCategoryMeta SHALL provide a localized title for each of the 12 categories in every Supported_Language_Code.
2. WHEN the Farm_Production_Selection_Screen renders a category tab, THE CropCategoryMeta SHALL return the title matching the active language code.
3. WHERE the active language code has no category title, THE CropCategoryMeta SHALL return the English title.

### Requirement 3: Screen UI String Localization

**User Story:** As a farmer, I want all text on the crop selection screen in my language, so that I can use the screen without confusion.

#### Acceptance Criteria

1. THE Farm_Production_Selection_Screen SHALL source the screen title, subtitle, search hint, empty-state message, validation message, helper note, selected count, clear-all button, continue button, and the "I don't know the crop name" link from AppLocalizations.
2. THE AppLocalizations SHALL provide a translated value for each UI string used by the Farm_Production_Selection_Screen in every Supported_Language_Code.
3. WHEN the farmer opens the voice search dialog, THE Farm_Production_Selection_Screen SHALL display the dialog title, instruction text, sample crop names, and close button from AppLocalizations.
4. WHEN the farmer opens the crop identification help sheet, THE Farm_Production_Selection_Screen SHALL display the sheet title, guidance text, and the three assistance options from AppLocalizations.
5. WHERE a translation key is missing for the active language, THE AppLocalizations SHALL return the English value.

### Requirement 4: Native Primary Name with English Secondary Label

**User Story:** As a farmer who cannot read English, I want the crop's native name as the primary label and English as a small secondary label, so that I can recognize crops in my language while keeping an English reference.

#### Acceptance Criteria

1. WHEN the active language is a non-English Supported_Language_Code, THE CropMasterEntry SHALL return the native localized name as the Primary_Name.
2. WHEN the active language is a non-English Supported_Language_Code, THE CropMasterEntry SHALL return the English canonical name as the Secondary_Label.
3. WHILE the active language is English, THE CropMasterEntry SHALL return the English canonical name as the Primary_Name.

### Requirement 5: Selected Crop Chip Localization

**User Story:** As a farmer, I want the chips showing my selected crops to display in my native language, so that I can review my selections accurately.

#### Acceptance Criteria

1. WHEN the Farm_Production_Selection_Screen renders a selected crop chip, THE chip SHALL display the crop's localized name for the active language.
2. WHERE a selected crop has no native name for the active language, THE chip SHALL display the English canonical name.

### Requirement 6: Audio TTS Language Resolution

**User Story:** As a farmer who cannot read, I want the app to speak crop names in my language, so that I can hear the correct pronunciation.

#### Acceptance Criteria

1. THE CropAudioService SHALL resolve a TTS_Locale for each of the 13 Supported_Language_Codes.
2. WHEN the farmer taps the audio button on a crop, THE CropAudioService SHALL set the TTS engine language to the TTS_Locale matching the active language code.
3. WHERE the TTS engine has no installed voice for the requested TTS_Locale, THE CropAudioService SHALL fall back to the English TTS_Locale.
