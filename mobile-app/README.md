# BabyCare SmartCam

A sophisticated Flutter mobile application with Neumorphism & Glassmorphism hybrid design for baby monitoring and interaction.

## Features

- **Dashboard (Monitoring)**: Live stream view with sound level meter and alert system
- **Expression Controller**: Control robot expressions with emoji buttons
- **Lullaby Player**: Play soothing music for babies

## Design Style

- **Neumorphism**: Soft shadows creating depth and elevation
- **Glassmorphism**: Translucent surfaces with backdrop blur effects
- **Color Palette**: Soft pastel blues and coral accents
- **Responsive**: Fully responsive UI using MediaQuery

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── expression_type.dart
│   └── song.dart
├── providers/                # State management
│   ├── baby_status_provider.dart
│   └── camera_provider.dart
├── screens/                  # App screens
│   ├── dashboard_screen.dart
│   ├── expression_controller_screen.dart
│   └── lullaby_player_screen.dart
├── services/                 # Business logic services
│   └── noise_detector_service.dart
├── theme/                    # App theme and styling
│   └── app_theme.dart
└── widgets/                  # Reusable widgets
    ├── glassmorphic_bar.dart
    ├── neumorphic_button.dart
    ├── pulsating_alert_banner.dart
    └── sound_level_meter.dart
```

## Key Features Implementation

### State Management
- Uses `ChangeNotifierProvider` for reactive state management
- `BabyStatusProvider`: Tracks baby's crying status and sound levels
- `CameraProvider`: Manages expression updates for hardware communication

### Simulated Hardware Bridge
- `CameraProvider.updateExpression()`: Simulates sending signals to 2.8-inch screen hardware
- `NoiseDetectorService`: Monitors sound levels and triggers alerts when dB > 70

### UI Components
- **NeumorphicButton**: Custom button with soft shadows and press animations
- **GlassmorphicBar**: Translucent navigation bar with backdrop blur
- **SoundLevelMeter**: Circular progress indicator for real-time dB display
- **PulsatingAlertBanner**: Animated alert banner for crying detection

## Dependencies

- `provider`: State management
- `percent_indicator`: Circular progress indicators
- `flutter`: Flutter SDK

## License

This project is created for demonstration purposes.
