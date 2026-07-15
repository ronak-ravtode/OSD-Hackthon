# Trace — Architecture & Technical Specifications

This document outlines the architecture, model pipeline, data flow, optimization techniques, performance benchmarks, and compliance sections for **Trace** (on-device AI screenshot search & utility).

---

## 1. Clean Architecture Layers

```mermaid
graph TD
    UI[Presentation Layer: Screens, Widgets, Providers] --> Domain[Domain Layer: Models, Repositories]
    Data[Data Layer: SQLite Helper, ML Kit OCR, Image Preprocessor] --> Domain
```

*   **Domain Layer (`lib/domain/`)**: Pure Dart entity models (`Screenshot`, `OcrBlock`, `Album`) and abstract repository definitions. Absolutely zero platform or framework dependencies.
*   **Data Layer (`lib/data/`)**: Concrete implementations of SQLite helpers with FTS5, Google ML Kit wrapper (`MlKitOcrService`), image compression, and duplicate detection.
*   **Presentation Layer (`lib/presentation/`)**: Responsive UI components featuring Google Lens-style zoom/pan overlay, custom selection toolbars, and state management via Provider.

---

## 2. On-Device AI Pipeline & Data Flow

```mermaid
sequenceDiagram
    participant UI as Presentation UI
    participant IP as Image Preprocessor
    participant OCR as Google ML Kit OCR
    participant DB as SQLite FTS5 Database
    
    UI->>IP: Import Screenshot (File Path)
    IP->>IP: Rescale (Max Long Side 1024px) & Compress
    IP->>OCR: Process Resized Image
    OCR->>UI: Return Extracted Text + Bounding Boxes (Original Pixels)
    UI->>DB: Insert metadata + text to FTS5 table
```

1.  **Preprocessing**: Resizes the screenshot (maintaining aspect ratio) if the longest side exceeds 1024px to prevent Out-Of-Memory (OOM) faults on low-end devices.
2.  **Inference**: The resized frame is fed to `google_mlkit_text_recognition` running completely locally on-device.
3.  **Indexing**: The text is indexed into a local SQLite virtual table utilizing **FTS5** (Full-Text Search 5) for tokenized, indexed substring queries.