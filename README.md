# TriVaani (त्रिवाणी)

### SIH 2026 | Team Mindflow
### Problem Statement: 26042

**One teacher's tablet. Three tribal languages. Zero internet required.**

TriVaani is an AI-powered classroom platform for mother-tongue-based primary education. It is designed for teachers working in multilingual classrooms in Jharkhand, where children may speak **Ho, Mundari or Santali** at home while classroom instruction is mainly in Hindi.

The main idea is simple: the teacher uses one tablet for teaching, translation and assessment. The AI handles speech recognition, translation and voice output locally, while the wider platform provides learning resources, language review and a government-level view of implementation.

---

## The Problem

Teachers working in multilingual classrooms may have to teach in Hindi while many children are more comfortable with their mother tongue.

For Ho, Mundari and Santali, the challenge is not only translation. Digital language resources, speech data and classroom-ready content are also limited.

TriVaani is designed around this problem: make classroom communication easier now, while creating a practical workflow through which teachers and language experts can review and improve language content over time.

---

## What the Platform Includes

### 1. Teacher App

The main application used in the classroom.

- Teach
- Translate
- Assess
- Learning resources
- Progress tracking
- Offline access
- Bilingual classroom activities

Students do not need individual devices. The teacher's tablet acts as the common classroom device.

### 2. Language Expert Portal

A separate review layer for language experts and native speakers.

- Review translations
- Correct language content
- Check terminology
- Validate educational material
- Approve content for future packs

Teacher feedback can be collected locally and synchronized when connectivity is available.

### 3. Government Dashboard

A higher-level dashboard for implementation and monitoring.

- Language coverage
- Content validation
- Usage overview
- Model and translation performance
- School and teacher-level information
- Progress across deployment

The government view is kept separate from the classroom workflow so that monitoring can focus on aggregate information.

---

## How TriVaani Works

### Teacher → Student

```text
Teacher speaks in Hindi
        ↓
Speech Recognition
        ↓
Context Processing
        ↓
Translation
        ↓
Ho / Mundari / Santali
        ↓
Text + Voice Output
        ↓
Classroom
```

### Student → Teacher

```text
Student speaks in mother tongue
        ↓
Speech Recognition
        ↓
Translation
        ↓
Hindi
        ↓
Teacher
```

The goal is to make this feel like a classroom conversation rather than making the teacher manually translate every sentence.

---

## Offline Architecture

Offline operation is a core part of TriVaani.

The main classroom interaction is designed around local processing:

```text
Teacher Speech
      ↓
Local Speech Recognition
      ↓
Context Processing
      ↓
Local Translation
      ↓
Local / Cached TTS
      ↓
Classroom Audio
```

Internet connectivity is used for activities such as:

- Content synchronization
- Language-resource updates
- Teacher corrections
- Language-expert review
- Content-pack updates
- System updates

The core classroom workflow is designed so that loss of connectivity does not stop the teacher from using the locally available models and content.

---

## Models

TriVaani uses AI4Bharat models and optimized local inference components.

| Component | Model / Technology | Runtime |
|---|---|---|
| Hindi ASR | AI4Bharat IndicConformer | ONNX INT8 |
| Santali ASR | AI4Bharat IndicConformer | ONNX INT8 |
| Translation | AI4Bharat IndicTrans2 | Local inference |
| TTS | Local TTS pipeline | Local / cached |
| Inference runtime | ONNX Runtime | CPU |

### ASR Optimization

The ASR models are converted to ONNX and INT8 quantized to reduce model size and improve CPU inference efficiency.

The original full-precision model files are kept separately from the lightweight runtime models where required.

### Hindi → Santali

```text
Hindi Audio
    ↓
IndicConformer — Hindi ASR
    ↓
Hindi Text
    ↓
IndicTrans2
    ↓
Santali — Ol Chiki
    ↓
Local TTS
    ↓
Audio Output
```

### Santali → Hindi

```text
Santali Audio
    ↓
IndicConformer — Santali ASR
    ↓
Santali Text
    ↓
IndicTrans2
    ↓
Hindi Text
    ↓
Local TTS
    ↓
Audio Output
```

---

## NIPUN Bharat Alignment

The teaching side of TriVaani is organised around foundational literacy and numeracy.

It includes:

- Oral language development
- Reading and comprehension
- Writing and expression
- Foundational numeracy
- Classroom activities
- Formative assessment
- Remedial learning

The purpose is to give the teacher the same learning activity with mother-tongue support where it is needed.

---

## Key Features

### Real-Time Classroom Translation

Hindi speech can be converted into the selected mother-tongue language and presented as text and voice.

### Two-Way Communication

The system supports communication in both directions between the teacher and students.

### Mother-Tongue Learning

Teaching resources can be presented with Hindi and mother-tongue support.

### Teacher-Centred Design

Students do not need separate phones or tablets. The teacher's device is the main classroom interface.

### Human Review

Teachers and language experts remain part of the language-quality workflow. AI output is not treated as the final authority for low-resource language content.

### Offline-First

Core classroom functionality is designed around locally available models and content.

---

## Tech Stack

### Frontend

- Flutter
- Dart
- `flutter_bloc`
- Material UI
- Android-first tablet design

### Backend

- Python
- FastAPI
- PostgreSQL / cloud storage for synchronization and management

### AI / ML

- PyTorch
- AI4Bharat IndicConformer
- AI4Bharat IndicTrans2
- ONNX Runtime
- INT8 quantization

### Local Storage

- SQLite / Drift
- Local content packs
- Offline data
- Corrections
- Consent records
- Sync queue

---

## Project Structure

```text
TriVaani/
│
├── lib/                    # Flutter frontend
│   ├── app/                # App setup, routing, theme and DI
│   ├── core/               # Shared models, repositories and widgets
│   └── features/           # Main application modules
│       ├── home/
│       ├── teach/
│       ├── translation/
│       ├── resources/
│       ├── assessment/
│       ├── progress/
│       ├── offline/
│       ├── profile/
│       └── settings/
│
├── backend/                # FastAPI / Python backend
├── models/                 # Local AI models
│   └── onnx/               # Optimized runtime models
├── assets/                 # Images and application assets
├── scripts/                # Utility and model scripts
├── reports/                # Benchmark / evaluation reports
├── android/                # Android project
├── web/                    # Flutter web project
├── windows/                # Windows project
├── pubspec.yaml            # Flutter dependencies
├── requirements.txt        # Python dependencies
└── README.md
```

---

## Getting Started

### Prerequisites

Install:

- Flutter SDK
- Dart SDK
- Python 3.10/3.11
- Git
- Android Studio and Android SDK for Android deployment

Check the installations:

```bash
flutter --version
python --version
```

### 1. Clone the Repository

```bash
git clone https://github.com/virti7/SIH2026_26042_Mind2Flow.git
cd SIH2026_26042_Mind2Flow
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Create the Python Environment

#### Windows

```powershell
python -m venv .venv
.venv\Scriptsctivate
pip install -r requirements.txt
```

### 4. Start the Local Backend

```powershell
python -m app.main
```

The local service runs on:

```text
http://127.0.0.1:7871
```

### 5. Run the Flutter App

For Chrome:

```bash
flutter run -d chrome
```

For Android:

```bash
flutter devices
flutter run -d <device-id>
```

Android tablet is the recommended deployment target.

---

## Using TriVaani

1. Open the Teacher App.
2. Complete the teacher and classroom setup.
3. Select the class and required language.
4. Open **Teach** for lesson delivery and classroom activities.
5. Open **Translate** for Hindi ↔ mother-tongue communication.
6. Use **Assess** for formative checks.
7. Use **Progress** to review individual learner performance.
8. Use the **Language Expert Portal** for translation and content review.
9. Use the **Government Dashboard** for higher-level monitoring.

For the voice workflow, speak into the device microphone. The local pipeline processes the audio and returns the corresponding translated text and voice output.

---

## Model Setup

Large model weights are not stored in normal Git history when they exceed practical repository limits.

After cloning the repository:

1. Set up the Python environment.
2. Install the required dependencies.
3. Place the required runtime models in the `models/` directory.
4. Verify the model paths used by the backend.
5. Start the local backend.
6. Launch the Flutter application.

The runtime uses the optimized ONNX INT8 ASR models where available.

---

## Performance and Evaluation

The main model components are evaluated separately:

| Component | Metric |
|---|---|
| Speech Recognition | WER / CER |
| Translation | BLEU / translation quality |
| Speech Synthesis | Inference latency |
| Runtime | End-to-end latency |
| ASR Deployment | ONNX INT8 model size and CPU inference |

Performance values shown in the application are intended to come from actual model inference or benchmark runs rather than simulated results.

---

## Human-in-the-Loop Language Improvement

TriVaani is designed so that language improvement does not depend only on model training.

```text
Teacher uses translation
        ↓
Teacher flags / corrects content
        ↓
Correction stored locally
        ↓
Sync when connectivity returns
        ↓
Language Expert Review
        ↓
Approved Content
        ↓
Future Content Pack / Model Improvement
```

This is especially important for lower-resource languages where classroom data and expert-reviewed material are limited.

---

## Three-Layer Ecosystem

```text
             TRI VAANI
                 │
        ┌────────┼────────┐
        ↓        ↓        ↓
    Teacher    Language  Government
      App       Expert    Dashboard
                 │
                 ↓
        Review & Validation
                 │
                 ↓
          Better Content
```

The three layers work together while keeping their responsibilities separate:

**Teacher App**  
Classroom teaching, translation, assessment and learning resources.

**Language Expert Portal**  
Language review, corrections and content validation.

**Government Dashboard**  
Aggregate monitoring, implementation and system-level visibility.

---

## Team Mindflow

**Mindflow** represents the way we approached the problem: connect the teacher, language and learning process instead of building a standalone translation tool.

```text
Teacher
   ↓
Language
   ↓
Understanding
   ↓
Learning
   ↓
Progress
```

TriVaani carries this flow into the classroom through one platform.

---

## Project Status

TriVaani is an SIH 2026 prototype focused on demonstrating the classroom workflow, local speech and translation pipeline, offline-first approach, and the teacher–language expert–government ecosystem.

The current implementation focuses on the language and model paths available in the repository. The architecture is designed to expand as more verified language data and models become available.

---

## SIH 2026

**Project:** TriVaani (त्रिवाणी)  
**Team:** Mindflow  
**Problem Statement:** 26042  
**Focus:** AI-powered vernacular pedagogy and real-time classroom translation for mother-tongue-based primary education
