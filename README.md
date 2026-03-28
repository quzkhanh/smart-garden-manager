# 🌿 Smart Garden

A modern **Smart Garden Management** application built with Flutter — designed to monitor and control smart garden zones from a single, beautiful interface.

---

## 📱 Demo Screenshots

| Login | Home | Area Detail |
|-------|------|-------------|
| ![Login](demo/01_login_screen.png) | ![Home](demo/02_home_screen.png) | ![Detail](demo/03_area_detail_screen.png) |

| Alerts | Settings |
|--------|----------|
| ![Alerts](demo/04_alerts_screen.png) | ![Settings](demo/05_settings_screen.png) |

---

## ✨ Features

### 🔐 Authentication
- Phone number login with OTP verification flow
- QR code login option
- Persistent session management via `AuthProvider`

### 🏡 Home Dashboard
- Overview summary cards: total zones, active devices, unread alerts
- Responsive grid/list layout adapting to screen width (mobile → tablet → desktop)
- Pull-to-refresh for real-time data reloading
- Staggered fade-in animations powered by `flutter_animate`

### 📍 Area / Zone Detail
- **Auto / Manual mode toggle** per garden zone
- Live sensor readings with animated progress bars:
  - 🌡️ Temperature (°C)
  - 💧 Air Humidity (%)
  - 🌱 Soil Moisture (%)
- **24-hour sensor history chart** (tabbed: Temperature / Air Humidity / Soil Moisture) using `fl_chart`
- **Device control panel**: toggle Water Pump, Misting, Ventilation Fan, Lighting
- **Device timer**: set a countdown to auto-toggle any device (Manual mode only)

### 🔔 Alerts
- Categorized notification list: **High / Medium / Low** priority
- Filter tabs: All | Unread | Read
- Tap to mark as read; displays relative timestamps

### ⚙️ Settings
- **Language selector**: Vietnamese 🇻🇳 / English 🇺🇸 (live switch, no restart needed)
- **Theme selector**: Light / Dark / System
- User profile card (phone number)
- Logout with confirmation dialog

---

## 🗂️ Project Structure

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # App root, MultiProvider, MaterialApp.router
├── routes/
│   └── app_router.dart        # GoRouter: auth-guard + route definitions
├── theme/
│   ├── app_theme.dart         # Light & Dark MaterialTheme definitions
│   └── app_colors.dart        # Color palette constants
├── l10n/
│   └── app_localizations.dart # Custom i18n (vi / en)
├── models/
│   ├── area.dart              # Area (zone) model
│   ├── device.dart            # Device model with timer logic
│   ├── sensor.dart            # Sensor model (value, min, max, unit)
│   ├── sensor_reading.dart    # 24h history data point
│   ├── alert.dart             # Alert notification model
│   └── logged_device.dart     # Device log entry model
├── data/
│   └── mock_data.dart         # Static mock data (ready for Firebase swap)
├── providers/
│   ├── auth_provider.dart     # Login state, OTP flow
│   ├── garden_provider.dart   # Areas, device control, timer scheduler
│   ├── alert_provider.dart    # Alerts list, unread count
│   ├── device_provider.dart   # Global device state
│   ├── settings_provider.dart # ThemeMode preference
│   └── locale_provider.dart   # Active locale (vi/en)
├── screens/
│   ├── login/
│   │   ├── login_screen.dart  # Phone input + QR login
│   │   └── otp_screen.dart    # 6-digit OTP entry
│   ├── home/
│   │   └── home_screen.dart   # Dashboard with area cards
│   ├── area_detail/
│   │   └── area_detail_screen.dart  # Zone detail + charts + devices
│   ├── alerts/
│   │   └── alerts_screen.dart # Notifications list
│   ├── devices/               # Devices overview screen
│   └── settings/
│       └── settings_screen.dart # App settings
└── widgets/
    ├── area_card.dart          # Zone summary card
    ├── device_tile.dart        # Device row with toggle + timer
    ├── sensor_bar.dart         # Sensor reading with progress bar
    ├── sensor_chart.dart       # fl_chart 24h line chart card
    ├── summary_card.dart       # Dashboard stat card
    ├── alert_card.dart         # Alert list item
    ├── language_switcher.dart  # Language toggle button
    └── common/
        ├── app_card.dart       # Reusable card container
        └── loading_skeleton.dart # Shimmer loading placeholders
```

---

## 🛠️ Tech Stack

| Category | Library | Version |
|---|---|---|
| Framework | Flutter | ≥ 3.11 |
| State Management | provider | ^6.1.2 |
| Navigation | go_router | ^14.8.1 |
| Fonts | google_fonts | ^6.2.1 |
| Animations | flutter_animate | ^4.5.2 |
| Charts | fl_chart | ^0.70.2 |
| Progress Indicator | percent_indicator | ^4.2.3 |
| QR Code | qr_flutter | ^4.1.0 |
| Localization | flutter_localizations | SDK |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11
- Dart SDK ≥ 3.11
- Chrome (for web) or a Linux/macOS/Windows desktop

### Run the app

```bash
# Clone the repository
git clone <repo-url>
cd smart_garden

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Linux desktop
flutter run -d linux
```

---

## 🏗️ Architecture Overview

```
UI Layer (Screens & Widgets)
        ↓ watches / reads
State Layer (Providers — ChangeNotifier)
        ↓ reads & writes
Data Layer (MockData / Future: Firebase Firestore)
```

- **Provider** handles reactive state across the widget tree.
- **GoRouter** manages declarative navigation with auth-guarding: unauthenticated users are redirected to `/login`.
- **GardenProvider** runs a 1-second `Timer.periodic` loop to process device countdown timers and trigger UI rebuilds.
- All models have `fromMap()` / `toMap()` methods ready for **Firebase Firestore** integration.

---

## 🌐 Localization

The app supports **Vietnamese** and **English** with instant switching (no app restart).

- Locale is controlled by `LocaleProvider`.
- Translations live in `lib/l10n/app_localizations.dart`.
- All UI strings use `l10n.t('key')` — no hardcoded strings in widgets.

---

## 🔮 Roadmap (Future)

- [ ] Firebase Authentication (phone OTP)
- [ ] Firebase Firestore real-time sensor sync
- [ ] Cloud Functions for server-side device timers
- [ ] Push notifications (FCM)
- [ ] Historical analytics dashboard
- [ ] Multi-user / role-based access

---

## 📄 License

MIT License — feel free to use and adapt.
