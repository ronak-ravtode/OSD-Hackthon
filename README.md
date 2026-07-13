# SnapSearch — On-Device Screenshot Search Utility 🔍📸

**SnapSearch** is a premium, high-performance Flutter application that allows users to import screenshots, extract text using on-device OCR, and perform lightning-fast Full-Text Search (FTS) to find specific screenshots by their content.

---

## 🌟 Key Features

*   **Multi-Image Indexing:** Import and process multiple screenshots from your gallery/downloads folder simultaneously.
*   **On-Device OCR:** Zero-latency text extraction powered by **Google ML Kit Text Recognition** (keeps your data private and works 100% offline).
*   **SQLite FTS4 Search Engine:** Fast local database search queries using SQLite virtual tables with support for **Prefix Wildcard Matching** (e.g., typing `Home` matches `HomeScreen` instantly).
*   **Interactive Photo Preview:** Tap any screenshot to open a high-resolution preview with interactive zoom and pan support.
*   **Monospace Text & Copy:** View all extracted OCR text in a monospace card, highlight sections, or copy the entire text to your clipboard with a single tap.
*   **Robust Platform Fallbacks:** Fully compatible with Web/Desktop environments through an in-memory database mock and mock OCR stubs.

---

## 🚀 How to Run & Build

### Prerequisites
*   Flutter SDK installed (v3.22+ recommended).
*   Android SDK / Android Studio configured.

### Local Execution (Android Emulator)
1. Start your Android emulator.
2. Run the application:
    ```bash
    flutter run -d emulator-5554
    ```

### Local Execution (Web Browser)
1. Launch the app in Chrome:
    ```bash
    flutter run -d chrome
    ```

---

## 📥 Try on Android Devices (APK Download)

You can download the compiled release APK directly from this repository to try the app on your physical Android device!

👉 **[Download snap_search.apk](release/snap_search.apk)** 

*(Note: Since this is signed with a debug-signing key for preview purposes, you may need to allow "Install from Unknown Sources" on your Android device when prompted).*

---

## 🛠️ Testing Guide

### 1. Adding Test Images to the Emulator
If testing on a new emulator with an empty gallery, copy images from your Windows PC using ADB:
```powershell
# 1. Set environment path to ADB
$env:PATH += ";C:\platform-tools"

# 2. Push your screenshot to the emulator's Download folder
adb push "C:\path\to\your\screenshot.png" /sdcard/Download/test_image.png

# 3. Broadcast file to refresh the gallery
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/test_image.png
```

### 2. Indexing & Searching
1. Open **SnapSearch**.
2. Tap the **Image plus icon (`🖼️+`)** in the top-right corner.
3. Select your imported screenshots from the folder picker.
4. Tap the **Search FAB (`🔍`)** in the bottom-right, type any word contained in your screenshots (e.g., `Flutter`, `Material`), and verify it filters instantly.
5. Tap any card to open the detail view, zoom/pan the screenshot, or copy the extracted text.
