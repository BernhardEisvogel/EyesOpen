# 👁 EyesOpen

![EyesOpen Logo](eyes_open_logo_1777201520579.png)

**EyesOpen** is a sophisticated macOS background application designed to enhance focus and break bad habits. By leveraging real-time computer vision, it monitors your posture and hand movements to prevent you from touching your face, biting your nails, or falling asleep at your desk.

Built for the **Big Berlin 2026 Hack**, EyesOpen combines edge-based AI with dynamic cloud-powered audio generation to create a responsive and personalized habit-correction experience.

---

## 🚀 Features

- **Face-Touch Detection**: Real-time monitoring of hand-to-face proximity using Apple's Vision framework.
- **Alertness Monitoring**: Detects head tilt (pitch) to identify when you are nodding off or losing focus.
- **Dynamic Audio Alerts**:
    - **Gradium TTS**: Personalized voice reminders generated on-the-fly.
    - **Tavily Dynamic Search**: Automatically fetches and plays contextually relevant sounds (e.g., "jump scares" or "pleasant dolphin sounds") to keep you alert.
- **Background Execution**: Runs silently in the macOS status bar with minimal system overhead.
- **Customizable Reminders**: Configure exactly what the app says to you through a simple status bar interface.

---

## 🛠 Tech Stack

### Core Technologies
- **Language**: Swift 5.9+
- **Frameworks**: 
    - `Vision`: For high-performance face and hand pose detection.
    - `AVFoundation`: For camera stream management and audio playback.
    - `AppKit (Cocoa)`: For the macOS status bar interface and background app lifecycle.

### APIs & External Tools
- **Gradium API**: High-quality Text-to-Speech (TTS) for personalized alerts.
- **Tavily API**: AI-powered search to dynamically source audio content from the web.
- **Python 3**: Backend scripts for audio processing and web scraping.
- **FFmpeg**: For on-the-fly audio conversion and normalization.

---

## 📦 Installation & Setup

### Prerequisites
- **macOS 12.0+**
- **Xcode 15+**
- **Python 3.10+**
- **FFmpeg** (Install via Homebrew: `brew install ffmpeg`)

### 1. Clone the Repository
```bash
git clone https://github.com/BernhardEisvogel/EyesOpen.git
cd EyesOpen
```

### 2. Configure API Keys
You will need API keys for Gradium and Tavily.

- **Gradium**: Update the `apiKey` in `Dont/Sources/HeadTracker/GradiumService.swift`.
- **Tavily**: Create a `.env` file in `Dont/Sources/HeadTracker/Resources/` or set the environment variable:
  ```bash
  export TAVILY_API_KEY='your_tavily_key_here'
  ```

### 3. Install Python Dependencies
```bash
pip install tavily-python beautifulsoup4 requests yt-dlp python-dotenv
```

### 4. Build and Run
Open the project in Xcode:
```bash
open Dont/Dont.xcodeproj
```
Select the **HeadTracker** target and press **Cmd + R** to build and run.

---

## 📘 Technical Documentation

### Vision Pipeline
EyesOpen utilizes a dual-request Vision pipeline:
1. **`VNDetectFaceRectanglesRequest`**: Tracks the user's face and calculates head orientation (pitch, yaw, roll).
2. **`VNHumanHandPoseRequest`**: Tracks 21 hand joints. The app specifically monitors fingertip joints (`indexTip`, `thumbTip`, etc.) and checks for intersection with the expanded face bounding box.

### Dynamic Audio Generation
When a violation is detected (e.g., hand touching face), the app:
1. Checks if a pre-generated alert exists in the temporary directory.
2. If not, it calls the **Gradium TTS API** to generate a new `.wav` file based on user preferences.
3. For "Extreme Alerts", it triggers a Python sub-process that uses **Tavily** to find relevant audio clips (like jump scares) from sources like YouTube or NPR, downloads them via `yt-dlp`, and converts them using `FFmpeg` for immediate playback.

### Background Execution
The app operates as a `LSUIElement` (Agent app), meaning it doesn't appear in the Dock but lives entirely in the Status Bar. This ensures it stays out of the way while remaining active.


---

*Developed for Big Berlin 2026 Hackathon.*
*Powered by Gradium, Tavily, and Gemini3*
