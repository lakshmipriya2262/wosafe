# 🛡️ WOSAFE - Women Safety & Real-Time Emergency Navigation System

> **Team**: **PIXAL TECH HUB** (Team ID: `24IPD010`)  
> **Institution**: Agni College of Technology, Chennai  
> **Platform**: Flutter (Android / iOS / IoT Wearables)  
> **Backend**: Real-time Node.js / Socket.IO GPS Telemetry Hub  

---

## 🌟 Key Highlights & Innovations

### 1. ⚡ Instant Zero-Delay SOS (<0.2s Dispatch)
- Native Android background SMS dispatch via Kotlin `MethodChannel("wosafe/emergency_channel")` leveraging `SmsManager`.
- Automated non-blocking dispatch with real-time Google Maps live GPS tracking link:
  `https://maps.google.com/?q={lat},{lng}`
- Sends alerts directly to emergency contacts and Police Women Helpline (`1091`) without manual popup prompts.

### 2. 🗺️ Safe Route Navigation (Google Maps Style Multi-Route)
- **Fastest Route (சீக்கிரமான வழி)**: Shortest travel time along high-traffic arterial roads.
- **Safest Main Corridor (சிசிடிவி & மக்கள் நடமாட்டம் உள்ள முதன்மை வழி)**: Prioritizes active CCTV coverage, floodlit boulevards, and dense pedestrian footfall.
- **Hazard Avoidance Route (தடைகள் தவிர்க்கும் வழி)**: Bypasses isolated shortcuts, unlit back-alleys, and construction zones.
- Real GPS step-by-step navigation tracking user physical movement via high-accuracy Geolocator stream.
- Dynamic turn-by-turn guidance countdown banners and Google Maps style maneuvers.

### 3. 🏥 Nearby Help Proximity Analysis
- Real-time catalog of verified Clinics, Hospitals, Police Stations, and Safe Cab Kiosks.
- Multi-modal transit time estimation: Walking (🚶), Two-Wheeler (🏍️), and Cab (🚕).
- 1-tap direct route navigation with exact coordinate pin-drop into the Safe Route engine.
- 1-tap direct emergency phone calling and number clipboard copying.

### 4. 🎙️ Hands-Free Voice SOS (Bilingual NLP Trigger)
- Native Android `SpeechRecognizer` processing real-time microphone audio directly on device.
- **English Distress Keywords**: `"Help Me"`, `"Save Me"`, `"Help"`, `"Emergency"`, `"Danger"`, `"Police"`.
- **Tamil Distress Keywords**: `"காப்பாத்துங்க"` (*kaappaathunga*), `"காப்பாத்து"`, `"உதவி"` (*udhavi*).
- Live volume RMS waveform visualizer, real-time transcript bubble, and 1-tap simulation test chips.

### 5. ⌚ Bluetooth Smartwatch Module & Hardware SOS Trigger
- Dedicated `SmartwatchService` managing BLE connection with smart bands and wearables (*WOSAFE Smart Band*, *Noise*, *Fire-Boltt*, *Boat Wave*, *Samsung Galaxy Watch / WearOS*).
- Live vitals telemetry dashboard: Heart rate (BPM) with panic tachycardia spike auto-alert (>125 BPM), Blood Oxygen (SpO2 %), Battery level, and 6-Axis Gyroscope Fall Detection.
- **🔘 HARDWARE WATCH SOS BUTTON**: Simulates pressing the physical watch crown/button to automatically broadcast live GPS tracking SMS, auto-call police helpline (`1091`), and launch safe route autopilot.

---

## 🚀 Tech Stack

- **Frontend**: Flutter 3.x, Dart
- **Mapping & GIS**: Flutter Map, LatLong2, OpenStreetMap Nominatim Geocoding API
- **Native Android**: Kotlin, SpeechRecognizer API, SmsManager, Intent.ACTION_CALL / DIAL
- **Hardware & IoT**: Bluetooth Low Energy (BLE), ESP32-C3 Firmware GATT integration
- **State Management**: Provider Architecture (`AuthProvider`, `ThemeProvider`, `EmergencyProvider`, `SensorProvider`, `SmartwatchService`)

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Android Studio / VS Code
- Android Device or Emulator running Android 8.0+ (API 26+)

### Installation
```bash
# Clone the repository
git clone https://github.com/lakshmipriya2262/wosafe--.git

# Navigate to project directory
cd wosafe--

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

---

## 📄 License & Attribution
Developed with pride by **PIXAL TECH HUB (Team ID: 24IPD010)**, Agni College of Technology.  
Protected under the MIT License.

<<<<<<< HEAD
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 7035039 (Initial commit)
=======
>>>>>>> 544bd1e (docs: update README with WOSAFE architecture, features, and setup guide)
