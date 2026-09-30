# Maatribhasha (मातृभाषा) — AI-Powered Vernacular Pedagogy & Real-Time Classroom Translation

> **Problem Statement PS 26042**: AI-Powered Vernacular Pedagogy and Real-Time Translation for Mother-Tongue-Based Primary Education  
> **Target Region**: Primary Schools across Jharkhand (Grades 1–3)  
> **Multilingual Context**: Hindi-medium instruction with native speakers of **Ho**, **Mundari**, and **Santali**  
> **Alignment**: NIPUN Bharat Mission (Foundational Literacy & Numeracy — FLN)

---

## 1. Executive Summary

In government primary schools across Jharkhand, teachers primarily deliver instruction in Hindi, while over 60–80% of children speak indigenous tribal languages—principally **Ho**, **Mundari**, and **Santali**—at home. This linguistic disconnect leads to early learning stalls, low comprehension, and high dropout rates by Grade 3.

**Maatribhasha** is a production-grade, tablet-optimized Flutter application designed for a single classroom device managed by the teacher. It equips teachers with:
1. **Real-time 2-way speech-to-speech translation** between Hindi and tribal languages with cultural nuance preservation.
2. **NIPUN Bharat-aligned 6-stage lesson delivery** grounded in local tribal folklore, daily life (e.g., *Sohrai* art, *Sarhul*, *mahua* harvesting, weekly *haat* markets), and dual-language scaffolds.
3. **Automated multilingual material generation** (bilingual worksheets, visual cultural flashcards).
4. **Individual learner tracking** (strictly individual—no aggregate masking of struggling students) with diagnostic gap analysis and one-touch remedial pathways.
5. **100% Offline-First operation** designed for remote schools without active internet access.

---

## 2. Visual Identity & Design System

The visual design adheres strictly to the official color palette specified in the competition problem statement:
- **Primary Brand Color**: Forest Green (`#1B5E3A`) — represents Jharkhand's sal forest heritage, growth, and trust.
- **Canvas / Background**: Warm Cream / Off-White (`#F8F9F5`) — high contrast, gentle on eyes during long classroom sessions.
- **Surface**: Pure White (`#FFFFFF`) cards with soft borders (`#E5E9E2`) and subtle elevation.
- **Accents**: Warm Ochre Amber (`#D97706`) for interactive highlights, Terracotta Rust (`#C2410C`) for active recording, and Deep Sky Blue (`#0284C7`) for informational tags.
- **Status Tones**: NIPUN Achieved Green (`#16A34A`), Emerging Amber (`#D97706`), Needs Support Red (`#DC2626`).
- **Zero Purple**: In strict compliance with guidelines, purple/violet hues are excluded from the entire design system.
- **Typography**: Google Fonts Poppins with comprehensive Devanagari Unicode support, paired with native tribal script transliterations (*Warang Chiti*, *Mundari Bani*, *Ol Chiki*).

---

## 3. Architecture & Tech Stack

The application is built using **Clean Architecture** and **Feature-First modularity**, guaranteeing separation of concerns, testability, and maintainability:

```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp with MultiBlocProvider & GoRouter
│   ├── di/
│   │   └── injection.dart         # Service locator via GetIt
│   ├── router/
│   │   ├── app_router.dart        # GoRouter configuration with 5-tab ShellRoute + 64 routes
│   │   └── route_names.dart       # Centralized route name constants
│   └── theme/
│       ├── app_colors.dart        # Forest Green palette & semantic tokens (No purple)
│       ├── app_radius.dart        # 8px, 12px, 16px, pill border radiuses
│       ├── app_shadows.dart       # Clean, soft elevation shadows
│       ├── app_spacing.dart       # 4px grid spacing system
│       ├── app_theme.dart         # Material 3 ThemeData definition
│       └── app_typography.dart    # Poppins + Devanagari type hierarchy
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # NIPUN standards, tribal metadata, storage keys
│   ├── enums/
│   │   └── app_enums.dart         # OutcomeStatus, TribalLanguage, DeliveryStage, etc.
│   ├── models/
│   │   └── app_models.dart        # Domain models (immutable with Equatable)
│   ├── repositories/
│   │   ├── app_repositories.dart  # Abstract repository interfaces
│   │   └── mock_repositories.dart # Rich mock implementations with Jharkhand tribal data
│   └── widgets/                   # Reusable UI component library
│       ├── app_bottom_nav.dart    # 5-Tab persistent navigation bar
│       ├── app_buttons.dart       # PrimaryButton, SecondaryButton, ActionPill
│       ├── app_header_banner.dart # Screen header with breadcrumbs and actions
│       ├── app_scaffold.dart      # Standardized scaffold with responsive shell
│       ├── audio_play_button.dart # Animated TTS audio preview button
│       ├── badges.dart            # NipunBadge, OfflineBadge, SyncBadge
│       ├── chips.dart             # StatusChip, LanguageChip, SubjectChip
│       ├── custom_card.dart       # Card with custom borders and ripple effect
│       ├── mic_record_button.dart # Pulsing animated STT microphone button
│       ├── responsive_container.dart # Tablet/mobile adaptive constraint container
│       └── section_header.dart    # Standardized section headings
└── features/                      # 7 Feature modules
    ├── home/                      # HomeScreen & Dashboard
    ├── offline/                   # Offline Model & Pack Management
    ├── onboarding/                # Splash, Welcome, Profile, Language Setup
    ├── profile/                   # Teacher Profile & School Setup
    ├── progress/                  # Individual Learner Tracking & Profiles
    ├── resources/                 # Worksheets, Flashcards, Assessments
    ├── settings/                  # System Settings, Sync, Help
    ├── teach/                     # Lesson Planning, 6-Stage Delivery, Copilot
    └── translation/               # Live Classroom Translation, Dual Mic, Phrasebank
```

### State Management: Strict BLoC (Strictly NO Cubit)
Every stateful workflow is governed by `flutter_bloc` using pure `Bloc<Event, State>` with explicit events, ensuring deterministic state transitions and complete event traceability:
- `OnboardingBloc`: Handles first-run wizard, teacher setup, and tribal classroom ratios.
- `HomeBloc`: Orchestrates dashboard overview, quick actions, and sync status.
- `TeachBloc`: Manages subjects, class grade selection, and NIPUN outcome retrieval.
- `LessonDeliveryBloc`: Powers the 6-stage interactive classroom teaching stepper with stage transitions.
- `LessonPlannerBloc`: Generates 3-day structured bilingual lesson plans.
- `TeacherCopilotBloc`: Real-time pedagogical assistant for instant classroom code-switching advice.
- `WorksheetBloc`: Generates dual-language printable worksheets with difficulty levels.
- `FlashcardBloc`: Generates visual, audio-enabled vocabulary flashcards with tribal imagery.
- `AssessmentBloc`: Administers 4-question formative assessments, diagnoses individual gaps, and generates remedial activities.
- `TranslationBloc`: Handles 2-way speech-to-text, neural machine translation, and text-to-speech audio simulation.
- `ProgressBloc`: Tracks individual learner competence, NIPUN mastery, and skill progression.
- `OfflineBloc`: Manages local storage, download packs, and sync queue.
- `ContentGenerationBloc`: Manages asynchronous server-side generation of flashcards and worksheets via FastAPI & Sarvam-105B. Verifies dual connectivity (device + backend `/health`), guides review approval gates, and atomically downloads artifacts into local SQLite and file storage for 100% offline usage. (Strictly BLoC, zero Cubit).

---

## 4. Complete 64-Screen Architecture Mapping

The application implements all 64 screens defined in the official specification document:

| Screen # | Module | Screen Name | Route Path | Key Features |
|---|---|---|---|---|
| **01** | Entry | Splash Screen | `/splash` | Brand emblem, offline ready badge, animated fade-in |
| **02** | Entry | Onboarding Carousel | `/onboarding` | 3 value props: Vernacular pedagogy, real-time voice, NIPUN tracking |
| **03** | Entry | Teacher Profile Setup | `/teacher-setup` | Name, Teacher ID, School, Block, District, Grade selection |
| **04** | Entry | Classroom Language Setup | `/classroom-lang-setup` | Ho, Mundari, Santali percentage sliders with auto-normalization |
| **05** | Entry | Home / Dashboard | `/home` | Quick launch, today's schedule, language breakdown, offline sync pill |
| **06** | Entry | Teacher Profile / My Class | `/profile` | Teacher details, school info, classroom language distribution chart |
| **07** | Entry | Offline Status Center | `/offline-center` | Model health, pending sync queue, manual sync trigger |
| **08** | Teach | Teach Home / Class Hub | `/teach` | Class selector (Class 1-3), subject cards, continue lesson banner |
| **09** | Teach | Class Overview | `/teach/class-overview` | Subject competencies, student breakdown, literacy & numeracy strands |
| **10** | Teach | Subject Detail View | `/teach/subject-detail` | Learning outcomes list, completion status, start lesson action |
| **11** | Teach | NIPUN Outcome Selector | `/teach/outcome-selector` | Grade 1-3 competencies, status chips, search & filter |
| **12** | Teach | Lesson Planner | `/teach/lesson-planner` | Multi-day plan, cultural theme picker, bilingual scaffolding options |
| **13** | Teach | Lesson Plan Detail | `/teach/lesson-detail` | Structured timeline, vocabulary list, required materials, print export |
| **14** | Teach | Lesson Delivery (6-Stage) | `/teach/lesson-delivery` | **Interactive Stepper**: Hook → Direct → Guided → Practice → Formative → Closing |
| **15** | Teach | Teacher Co-Pilot (Live) | `/teach/copilot` | Quick prompts, vernacular suggestions, code-switching guidance |
| **16** | Teach | Local Context Library | `/teach/local-context` | Jharkhand folklore, tribal stories, seasonal songs, harvest themes |
| **17** | Literacy | Oral Language (चित्रात्मक वार्तालाप) | `/teach/literacy/oral` | Picture talk prompts, tribal discussion questions, oral scoring |
| **18** | Literacy | Decoding (ध्वनि व वर्ण पहचान) | `/teach/literacy/decoding` | Phoneme cards, Devanagari-tribal sound mapping, blending drill |
| **19** | Literacy | Reading Comprehension (पठन) | `/teach/literacy/reading` | Dual-column stories, vocabulary popovers, read-along TTS audio |
| **20** | Literacy | Writing Expression (लेखन) | `/teach/literacy/writing` | Tracing patterns, letter formation, bilingual labeling exercises |
| **21** | Literacy | Activity Detail View | `/teach/literacy/activity` | Step-by-step instructions, tribal audio prompts, classroom tips |
| **22** | Numeracy | Oral Math Talk (गणित बातचीत) | `/teach/numeracy/oral` | Daily number routines, tribal counting rhymes, verbal challenges |
| **23** | Numeracy | Skills Teaching (कौशल शिक्षण) | `/teach/numeracy/skills` | Concrete-Pictorial-Abstract steps with tribal counters (seeds, leaves) |
| **24** | Numeracy | Skills Practice (कौशल अभ्यास) | `/teach/numeracy/practice` | Leveled worksheet drills, timed oral questions, peer exercises |
| **25** | Numeracy | Math Games (गणित खेल) | `/teach/numeracy/games` | Traditional tribal games adapted for numeracy, dice and counter rules |
| **26** | Numeracy | Activity Detail View | `/teach/numeracy/activity` | Game rules, scoring rubric, cultural context explanation |
| **27** | Resources | Topic Resource Detail | `/resources/topic-detail` | All resources tied to outcome: worksheets, flashcards, activities |
| **28** | Resources | Bilingual Worksheet Generator | `/resources/worksheet-gen` | Select language pair, question count, difficulty, layout options |
| **29** | Resources | Worksheet Preview & Print | `/resources/worksheet-preview` | Full page preview, bilingual side-by-side questions, print/save |
| **30** | Resources | Visual Flashcard Generator | `/resources/flashcard-gen` | Image prompt, tribal word, Hindi translation, audio preview |
| **31** | Resources | Flashcard Viewer / Slideshow | `/resources/flashcard-viewer` | Full-screen swipeable cards with audio playback in Ho/Mundari/Santali |
| **32** | Resources | Activity Library | `/resources/activities` | Filterable by literacy strand, numeracy stage, duration, language |
| **33** | Resources | Resource Activity Detail | `/resources/activity/:id` | Full multilingual activity plan with local context and teacher prompts |
| **34** | Resources | Saved / Downloaded Materials | `/resources/saved` | Offline cached worksheets, flashcard decks, lesson plans |
| **35** | Assessment | Assessment Builder | `/assessment/builder` | Choose outcome, question formats, oral vs written, language scaffolds |
| **36** | Assessment | Assessment Play (1-on-1) | `/assessment/play` | Individual student tester: voice input, quick scoring, audio prompt |
| **37** | Assessment | Assessment Result & Diagnostics | `/assessment/result` | Student score, NIPUN status tag, error analysis, root causes |
| **38** | Assessment | Learning Gap Analysis | `/assessment/gap` | Specific sub-skill breakdown, tribal language conceptual barriers |
| **39** | Assessment | Remedial Activity Recommendation | `/assessment/remediation` | 1-touch targeted activity tailored to student's specific mother tongue |
| **40** | Assessment | Re-Assessment & Verification | `/assessment/reassessment` | Re-test after remediation, compare scores, update learner profile |
| **41** | Translation | Live Classroom Translation | `/translate` | Big mic, live speech recognition, instant tribal text + TTS audio |
| **42** | Translation | Context-Aware Translation | `/translate/context` | Pedagogical translations preserving math/science terms |
| **43** | Translation | Classroom Language Router | `/translate/router` | Broadcast same phrase into Ho, Mundari, and Santali simultaneously |
| **44** | Translation | Student Response Translator | `/translate/student-response` | Listen to student speaking in tribal language → translate to Hindi |
| **45** | Translation | Two-Way Conversation Session | `/translate/conversation` | Split-screen interface for 1-on-1 teacher-student dialogue |
| **46** | Translation | Quick Phrase Bank | `/translate/phrases` | Pre-recorded classroom management phrases in all 3 tribal languages |
| **47** | Translation | New Sentence Translation Result | `/translate/new-sentence` | Offline NMT execution on unseen sentences with dual-script rendering |
| **48** | Translation | Translation Feedback | `/translate/feedback` | Teacher rating of translation accuracy for edge model fine-tuning |
| **49** | Progress | Individual Progress Home | `/progress` | Student roster with photos, individual NIPUN mastery, language tag |
| **50** | Progress | Student List & Search | `/progress/students` | Searchable individual learner roster with language filters & gap flags |
| **51** | Progress | Student Learning Profile | `/progress/student/:id` | Complete individual portfolio: literacy, numeracy, language strengths |
| **52** | Progress | Subject Progress | `/progress/student/:id/subject` | Longitudinal competency tracking by subject (Literacy & Numeracy) |
| **53** | Progress | Assessment History | `/progress/student/:id/assessments` | Chronological assessment log for selected student with score trends |
| **54** | Progress | Learning Gap History | `/progress/student/:id/gaps` | Detailed log of diagnosed conceptual gaps and targeted remediations |
| **55** | Progress | Recommended Next Lessons | `/progress/student/:id/recommendations` | Personalized pedagogical next steps based on recent assessments |
| **56** | Offline | Initial Provisioning Screen | `/offline/provisioning` | First-time offline asset unpacking, model weight verification |
| **57** | Offline | Language Pack Manager | `/offline/languages` | Download size, version, and update status for Ho, Mundari, Santali |
| **58** | Offline | Content Pack Manager | `/offline/content` | Selective curriculum pack downloads for Classes 1, 2, and 3 |
| **59** | Offline | Sync & Updates Center | `/offline/sync` | Background sync queue, district upload trigger, conflict resolution |
| **60** | Offline | Offline Storage Breakdown | `/offline/storage` | Cache breakdown: models, audio, worksheets, free disk space |
| **61** | Settings | Language Settings | `/settings/language` | Teacher interface language & active classroom tribal languages |
| **62** | Settings | Audio Settings | `/settings/audio` | Speech rate, voice gender, volume boost for noisy classrooms |
| **63** | Settings | Classroom Settings | `/settings/classroom` | Active class, term schedule, and default target tribal language |
| **64** | Settings | About & Help Center | `/about` | NIPUN Bharat guidelines, tribal language contributors, app version |

---

## 5. Primary Clickable User Journeys

The application features complete end-to-end interactive journeys without dead ends:

### Journey 1: Teach ➔ Deliver ➔ Formative Assessment ➔ Remediation
1. **Teach Hub** (`/teach`) → Select **Class 2 Hindi** (`/teach/subject-detail`).
2. Pick Outcome `H2.1: मौखिक अभिव्यक्ति (वर्णनात्मक भाषा)` → Tap **"Start 6-Stage Lesson"**.
3. **6-Stage Interactive Stepper** (`/teach/lesson-delivery`):
   - Stage 1: Hook (स्थानीय संदर्भ) with Sarhul flower imagery and Santali prompt.
   - Stage 2: Direct Instruction with bilingual side-by-side script.
   - Stage 3: Guided Practice with interactive class call-and-response.
   - Stage 4: Independent Practice with verbal challenge.
   - Stage 5: Formative Check → Tap **"Run Formative Check"** to launch assessment.
4. **Assessment Player** (`/assess/play`) → Test student *Birsa Munda* using dual mic:
   - Teacher speaks question in Hindi → Tablet broadcasts Mundari audio prompt.
   - Student answers in Mundari → Speech recognition transcribes response.
   - Score: Needs Support (45%).
5. **Learning Gap Analysis** (`/assess/gap-analysis`):
   - Pinpoints specific vocabulary obstacle: confusion between Mundari and Hindi word for *peacock*.
   - Tap **"Generate Remedial Activity"**.
6. **Remedial Activity Screen** (`/assess/remedial`):
   - Generates mother-tongue specific picture-matching game.
   - Tap **"Conduct Reassessment"** (`/assess/reassessment`).
   - Score improves to 85% (Achieved) → Updates student's individual record.

### Journey 2: Real-Time Classroom Translation & Language Routing
1. Tap **Translate Tab** in bottom navigation bar (`/translate`).
2. Select target language: **Mundari** (or Ho / Santali).
3. Tap the pulsing central microphone:
   - Speaks Hindi: *"बच्चों, अपनी गणित की किताब का पन्ना 14 खोलो।"*
   - Real-time simulation performs ASR → NMT → TTS.
   - Output displayed in Mundari: *"होपोनको, आपेयाक् लेकर किताब 14 नंबर साकम ओड़ोकपे।"*
   - Audio speaker button plays pronunciation for the entire classroom.
4. Tap **"Multi-Language Router"** (`/translate/router`):
   - Simultaneously renders the phrase in **Ho**, **Mundari**, and **Santali** on one screen.
5. Tap **"Quick Phrases"** (`/translate/phrases`):
   - Access instant one-tap classroom commands (*"शांत बैठो"*, *"बहुत अच्छा"*, *"अपनी बारी का इंतजार करो"*).

### Journey 3: Bilingual Material Generation (Worksheets & Flashcards)
1. Navigate to **Resources** (`/resources/activities`).
2. Tap **"Bilingual Worksheet Generator"** (`/resources/worksheet-gen`):
   - Select Outcome: `M2.4: दो अंकों का जोड़`.
   - Select Language: **Hindi + Santali** (or Ho / Mundari).
   - Select Layout & Difficulty: Side-by-side dual columns with pictorial counters.
   - Tap **"Generate Worksheet"**:
     - Flutter verifies usable internet + FastAPI server reachability (`/api/v1/health`). If unreachable, generation is safely prevented.
     - Asynchronous request dispatched to backend: `POST /api/v1/ai/teacher/generate`.
     - Server invokes **Sarvam-105B** with NIPUN blueprint & PromptComposer.
     - Content passes pedagogical and JSON Schema validation.
     - Review gate modal displayed (e.g. confirming Ol Chiki script for Santali).
     - Upon approval, backend marks artifact **READY**.
     - Flutter atomically downloads structured JSON and assets to device storage and persists metadata to SQLite (`SavedMaterials`).
     - Content is marked **AVAILABLE OFFLINE**.
3. Tap **"Visual Flashcard Generator"** (`/resources/flashcard-gen`):
   - Generates deck of cultural cards with tribal text, Hindi translation, and image/audio metadata using the same server-side generation and local download pipeline.
   - Tap **"Launch Slideshow"** (`/resources/flashcard-viewer`) or view in **Saved Materials** (`/resources/saved`) completely offline with zero server calls.

### Journey 4: Strict Individual Learner Tracking
1. Tap **Progress Tab** (`/progress`).
2. View roster of individual students:
   - *Birsa Munda* (Mundari, Class 2, 78% mastery).
   - *Soniya Soren* (Santali, Class 2, 85% mastery).
   - *Budheshwar Ho* (Ho, Class 2, 62% mastery).
3. Tap on any student to open their **Student Learning Profile** (`/progress/student-profile`):
   - Radar competencies, NIPUN progress breakdown, dual-language proficiency balance.
   - Generate bilingual **Parent-Teacher Card** (`/progress/parent-card`) in their native tribal tongue.

---

## 6. How to Run the Application

### Prerequisites
- Flutter SDK (version `^3.27.0` or higher)
- Dart SDK (`^3.6.0`)
- Any target: Android Emulator / Tablet, Chrome, or Windows Desktop

### Running the App
```bash
# Clone and navigate to workspace
cd d:\SIH_JHARKHAND

# Fetch dependencies
flutter pub get

# Run static analysis (Expected: No issues found!)
dart analyze

# Run automated tests (Expected: All tests passed!)
flutter test

# Run application locally
flutter run -d chrome    # For Web browser preview
flutter run -d windows   # For Windows Desktop
flutter run -d android   # For connected Android Tablet
```

---

## 7. Connecting Real AI Models & Backends (Production Extensibility)

The application uses an inversion-of-control repository pattern (`lib/core/repositories/`). All mock implementations (`MockTeacherRepository`, `MockTranslationRepository`, `MockLessonRepository`, etc.) are registered in `lib/app/di/injection.dart`.

To replace mock data with live AI microservices and on-device models:

```dart
// lib/app/di/injection.dart
void setupDependencyInjection() {
  // Replace MockTranslationRepository with OnDeviceNmtRepository:
  // sl.registerLazySingleton<TranslationRepository>(() => BhashiniNmtRepository(apiKey: ...));
  
  // Or register an on-device ONNX/TFLite IndicWav2Vec model for zero-internet STT:
  // sl.registerLazySingleton<SpeechRecognitionRepository>(() => OnDeviceWav2VecRepository());
}
```

- **ASR & STT**: Compatible with AI4Bharat IndicWav2Vec or Whisper-Small fine-tuned on Ho, Mundari, and Santali.
- **NMT (Translation)**: Compatible with Bhashini IndicTrans2 or quantized local ONNX IndicBART models.
- **TTS**: Compatible with Indic-TTS supporting Devanagari phoneme-to-speech generation.
- **Sync**: Built-in sync queue (`OfflineRepository`) serializes records to local SQLite and performs HTTP POST sync when connectivity is restored.

---

## 8. Alignment with NIPUN Bharat Guidelines

| NIPUN Target | Maatribhasha Implementation |
|---|---|
| **Balvatika & Grade 1 Oral Fluency** | Oral Language picture talk screens (`चित्रात्मक वार्तालाप`) with mother-tongue scaffolds |
| **Grade 2 Decoding & Word Recognition** | Phoneme blending drills (`ध्वनि व वर्ण पहचान`) linking Devanagari letters to tribal sounds |
| **Grade 3 Reading with Comprehension** | Bilingual side-by-side reading passages with instant TTS pronunciations |
| **Foundational Numeracy (0–99)** | Number concepts taught via tribal counting games, *haat* market word problems, and seed counters |
| **Individual Diagnostic Remediation** | One-touch remedial activity generation addressing the specific tribal mother-tongue gap |
#   M a a t r i B h a s h a - d e m o  
 