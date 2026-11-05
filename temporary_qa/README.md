# KhetChacha Temporary Agricultural Q&A Dataset (Demo-1)

## Overview
This directory contains a strictly constrained 32-record temporary agricultural Q&A dataset designed for laptop and offline demonstrations.
Both text queries and microphone Speech-to-Text (STT) queries query this exact dataset using `TemporaryAgricultureQAService`.

## Dataset Specification
- **Version**: `demo-1`
- **Total Records**: Exactly 32
- **Language Distribution**:
  - Gujarati (`gu`): 7
  - Hindi (`hi`): 7
  - English (`en`): 6
  - Punjabi (`pa`): 3
  - Marathi (`mr`): 3
  - Telugu (`te`): 3
  - Bengali (`bn`): 3
  - **Total**: 32 records (strictly NO 33rd question)

## Matching Behavior
1. **Normalization**: Unicode NFC normalization, case folding (for Latin scripts), whitespace/punctuation stripping.
2. **Language Awareness**: First prioritizes the user's active/selected language.
3. **Exact & Constrained Matching**: High confidence match against the 32 questions.
4. **Fallback**: If the query is outside these 32 records or low confidence, gracefully falls back to the live permanent AI backend.
5. **TTS Audio**: Supported through `AiChatTtsService` mapped to the corresponding language locale.

