# 🎤 Voice Navigation Feature

## Overview

The FarmOps app now includes a powerful voice navigation feature that allows users to navigate the app using voice commands. This is especially useful for farmers who may be working in the field and need hands-free access to the app.

## How to Use

### 1. Activate Voice Navigation

- Look for the **green microphone button** at the bottom center of the Home Page
- Tap the button to start voice recognition
- The button will glow green when actively listening
- You'll see "Listening..." status text above the button

### 2. Voice Commands

Speak naturally! The app understands various ways to express your intent:

#### 📍 Location Recommendation

- "location"
- "location recommendation"
- "location based"
- "go to location"

#### 🌱 Soil Recommendation

- "soil"
- "soil recommendation"
- "crop recommendation"
- "open soil"

#### 👨‍🌾 Professional Advisor / Chatbot

- "advisor"
- "professional advisor"
- "chatbot"
- "chat"
- "open chat"

#### 🏛️ Government Schemes

- "government"
- "government schemes"
- "schemes"
- "subsidy"

#### 🌤️ Weather Forecast

- "weather"
- "weather forecast"
- "forecast"
- "climate"

#### 🦠 Disease Detection

- "disease"
- "disease detection"
- "plant disease"
- "crop disease"

#### 💰 Market Analysis

- "market"
- "market analysis"
- "price"
- "market price"

#### 📊 Profit/Loss Calculator

- "profit"
- "loss"
- "calculator"
- "profit loss calculator"

#### 👤 Profile

- "profile"
- "my profile"

#### 🏠 Home

- "home"
- "go home"
- "main page"

### 3. Getting Help

- **Long press** the microphone button to see all available commands
- If a command isn't recognized, the app will show a help dialog

### 4. Visual Feedback

- **Glowing Animation**: The button glows with a green pulsating effect when listening
- **Status Text**: Shows current state (Listening, Recognizing, Opening...)
- **Recognized Text**: Displays what you said in real-time
- **Voice Feedback**: The app speaks responses using text-to-speech

## Features

### 🎯 Smart Command Recognition

- Understands natural language patterns
- Supports "go to", "open", "show" prefixes
- Partial matching for flexibility
- Case-insensitive recognition

### 🔊 Audio Feedback

- Speaks confirmation when opening pages
- Provides error messages if command isn't understood
- Clear audio cues for user guidance

### ⏱️ Auto-Stop Listening

- Automatically stops after 10 seconds
- 3-second pause detection for natural speech
- Prevents accidental continuous listening

### 🎨 Beautiful UI

- Glowing animation using `avatar_glow` package
- Smooth transitions and visual feedback
- Clean, intuitive interface
- Responsive design

## Technical Details

### Packages Used

- **speech_to_text** (v6.5.1): For voice recognition
- **flutter_tts** (v3.8.5): For text-to-speech feedback
- **avatar_glow** (v3.0.1): For glowing button animation
- **permission_handler** (v11.3.1): For microphone permissions

### Permissions

The following permissions are automatically configured:

#### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

#### iOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for voice navigation feature.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition to enable voice-controlled navigation.</string>
```

#### macOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for voice navigation feature.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition to enable voice-controlled navigation.</string>
```

## Architecture

### Files Structure

```
lib/
├── services/
│   └── voice_navigation_service.dart    # Core voice navigation logic
├── widgets/
│   └── voice_navigation_button.dart     # UI component
└── home_page.dart                        # Integration point
```

### VoiceNavigationService

Handles:

- Speech-to-text initialization
- Text-to-speech initialization
- Command parsing and mapping
- Audio feedback management

### VoiceNavigationButton Widget

Provides:

- Interactive microphone button
- Visual feedback (glowing animation)
- Status text display
- Help dialog
- Navigation handling

## Usage Tips

1. **Speak Clearly**: Speak at a normal pace in a quiet environment
2. **Wait for Feedback**: The app will confirm what it heard
3. **Use Simple Commands**: Single or two-word commands work best
4. **Check Help**: Long press for a full list of commands
5. **Retry if Needed**: If not recognized, tap again and try a different phrase

## Troubleshooting

### Voice Recognition Not Working

- Ensure microphone permissions are granted
- Check device microphone is working
- Speak in a quiet environment
- Update to latest app version

### Commands Not Recognized

- Try simpler, shorter commands
- Use commands from the help list
- Speak clearly and at normal pace
- Check language settings (English only currently)

### No Audio Feedback

- Check device volume
- Ensure media volume is not muted
- Test TTS in device settings
- Restart the app

## Future Enhancements

- Multi-language support (Hindi, Marathi, etc.)
- Offline voice recognition
- Custom command training
- Voice shortcuts
- Continuous listening mode

## Support

For issues or questions about voice navigation, please contact the FarmOps support team.

---

**Note**: Voice navigation requires an active internet connection for best results. The feature uses on-device speech recognition when available, falling back to cloud-based recognition for improved accuracy.
