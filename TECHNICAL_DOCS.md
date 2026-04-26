# EyesOpen Technical Documentation

This document provides an in-depth look at the architecture, implementation details, and design decisions behind the EyesOpen project.

## 1. System Architecture

EyesOpen is a macOS application built using Swift and Python. It follows a modular architecture to separate concerns between computer vision, audio processing, and user interface.

### Component Overview
- **`HeadTracker` (Swift)**: The core engine responsible for camera management and Vision request handling.
- **`AppDelegate` (Swift)**: Manages the application lifecycle, status bar menu, and user configurations.
- **`GradiumService` (Swift)**: Interface for the Gradium TTS API.
- **`TavilyHandler` (Swift/Python)**: A bridge between the native app and the Python-based dynamic audio search engine.
- **`SoundUtils` (Swift)**: Utility functions for audio playback and event simulation.

## 2. Computer Vision Implementation

### Face & Posture Tracking
The app uses `VNDetectFaceRectanglesRequest` to obtain a `VNFaceObservation`. 
- **Pitch Detection**: We monitor the `pitch` property of the face observation. A pitch value `> 0.4` indicates the head is tilted significantly downwards (potential nodding off), while `< -0.15` indicates looking up.
- **Bounding Box**: The face bounding box is normalized to the image coordinates and used as the "forbidden zone" for hand movements.

### Hand Pose Detection
We use `VNHumanHandPoseRequest` to detect hand joints.
- **Intersection Logic**: The app monitors the coordinates of fingertips (Index, Middle, Ring, Little, and Thumb).
- **Sensitivity**: The face bounding box is expanded by a padding factor (default `0.04`) to trigger alerts slightly before the hand makes physical contact with the face, providing a proactive warning.

## 3. Dynamic Audio Pipeline

### Gradium TTS Integration
The app allows users to customize their alerts. When a user saves new alert text:
1. The app clears the local cache (`NSTemporaryDirectory`).
2. It asynchronously calls `GradiumService` to pre-generate the high-quality `.wav` files.
3. This ensures zero-latency playback when a violation is detected.

### Tavily Dynamic Search (Python Bridge)
For "Extreme Alerts", the app triggers a Python script (`tavily_test.py`):
1. **Search**: Uses Tavily's AI search to find audio sources based on a query (e.g., "scary jump scare sounds").
2. **Extraction**: Scrapes the search results using `BeautifulSoup` and `yt-dlp` to find direct audio links or YouTube videos.
3. **Processing**: Uses `FFmpeg` to extract a 10-second clip, convert it to a compatible format, and save it to the app's resource directory.
4. **Playback**: The Swift layer monitors the directory and plays the newly discovered sounds.

## 4. Design Decisions & Optimizations

- **Low-Resolution Capture**: The `AVCaptureSession` is set to `.low` preset. Since Vision works on normalized coordinates, high resolution is not required for face/hand tracking, significantly reducing CPU and battery consumption.
- **Thread Safety**: Access to the `latestFaceBoundingBox` is protected by an `NSLock` to prevent race conditions between the face detection and hand detection threads.
- **Cooldown Mechanisms**: To prevent "alert fatigue," the app implements a cooldown timer (0.7s) between consecutive notifications.
- **User Privacy**: All vision processing is performed locally on-device. No camera frames are ever uploaded to the cloud. Only text strings are sent to the Gradium API for TTS generation.

## 5. Future Roadmap

- **On-Device LLM**: Integrate a local LLM (via CoreML) to generate even more context-aware reminders without API calls.
- **Screen Time Integration**: Sync with macOS Screen Time to provide reports on focus levels throughout the day.
- **Multi-Camera Support**: Allow users to select which camera to use for tracking.

---
*Technical Lead: Bernhard Eisvogel*
