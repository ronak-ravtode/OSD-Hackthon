# Trace — On-Device AI Screenshot Utility 🔍📸

**Trace** is a premium, high-performance, offline-first mobile application built for **OSDHack 2026** that acts as an intelligent utility for managing screenshots. It extracts text locally via OCR, executes instant Full-Text Search (FTS5), auto-redacts sensitive PII information (Privacy Shield), groups duplicates using Jaccard Similarity, and generates smart bullet summaries using a pure-math implementation of the TextRank/PageRank algorithm.

All operations run **100% on-device** with **zero network requests** and **zero user data leaving your phone**.

---

## 🎥 Mandatory Demo Video
👉 **[Watch the 2-Minute Demo Video Here](https://youtu.be/uxNUnxf1oLM)**

The demo video illustrates:
1. Real-time selection & Google Lens-style zoom/pan.
2. Auto-redaction of PII (Aadhaar & Credit Cards).
3. TextRank summarizer & Regex-based Smart Actions.
4. Smart tags classification & local SQLite search working in Airplane Mode.

---

## 🚀 How to Run & Build (Reproduce Project)

### 1. Prerequisites
*   Flutter SDK installed (v3.22.0+ recommended)
*   Android SDK & Emulator configured
*   Physical Android Device (optional, recommended for local OCR testing)

### 2. Setup & Dependencies
Add permissions handler and SQLite helpers locally by fetching packages:
```bash
# Clone the repository
git clone https://github.com/ronak-ravtode/OSD-Hackthon.git
cd OSD-Hackthon

# Get all dependencies
flutter pub get
```

### 3. Build & Run Commands
```bash
# Analyze static analysis check (must return 0 issues)
flutter analyze

# Run local testing in release mode on emulator or connected phone
flutter run --release

# Generate a fresh testing release APK
flutter build apk --release
```
The compiled APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk` (and is copied to [release/trace.apk](release/trace.apk)).

---

## 📥 Direct APK Download
Try the app directly on your physical Android phone:
👉 **[Download Trace Release APK](release/trace.apk)**

---

## 📱 Sample Inputs & Expected Outputs

| Input Image Type | Sample Input Contents | Expected App Action & Output |
| :--- | :--- | :--- |
| **Receipt / Invoice** | A payment screen containing `Total: ₹1,499` and `Tax` | **Category**: `receipt` <br>**Smart Action**: Adds chip `Copy ₹1499` <br>**Tags**: `receipt` |
| **Travel Ticket** | A flight ticket showing `PNR: W39K1B`, `Flight SG813` | **Category**: `travel_tickets` <br>**Smart Action**: Adds chip `Copy PNR: W39K1B` <br>**Tags**: `travel` |
| **Sensitive Document** | An image containing a 12-digit Aadhaar Card number or 16-digit Credit Card | **Privacy Shield Alert**: Warns PII found <br>**Action**: Redacts digits with `████` block characters |
| **Long Text Article** | A screenshot of a 10-sentence technical article | **Summary**: Returns top 3 most important sentences using PageRank |

---

## 🛡️ Privacy, Safety & Local Verification

*   **100% Offline**: Tested and validated in Airplane Mode.
*   **Permissions**: Requests only `READ_MEDIA_IMAGES` to scan local screenshots.
*   **Privacy Shield**: Uses a local Luhn algorithm validation on 13-19 digit credit cards and regex matches for Aadhaar/passwords before sharing.
*   **Data Handling**: SQLite DB and resized caches are stored strictly within the app's secure private directory.

---

## 🛠️ Attributions & Tech Stack

*   **Framework**: Flutter (Dart 3)
*   **OCR**: Google ML Kit Text Recognition (`google_mlkit_text_recognition`)
*   **Database**: SQLite with FTS5 virtual tables (`sqflite`)
*   **Image Processing**: Grayscale & scale conversion (`image` package)
*   **No Cloud APIs**: 100% local model pipelines.
