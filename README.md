# VCWD Water Leakage Monitoring System

A smart water management system for Valencia City, Bukidnon with real-time sensor monitoring, role-based dashboards, and water issue reporting.

## 🚀 Live Demo

**[Access the Web App Here](https://nomos69.github.io/VCWD-Water-Leakage-Monitoring/)**

## Features

✨ **Authentication System**
- User registration with email and password
- Login with role-based access control
- Three user roles: Consumer, Technician, Admin

📊 **Role-Based Dashboards**
- **Consumer Dashboard**: Report water issues, track service requests
- **Technician Dashboard**: View and manage pending tasks
- **Admin Dashboard**: Monitor sensors, manage system, view analytics

🗺️ **Interactive Map**
- Valencia City water sensor map
- Real-time sensor status visualization (🟢 Green = Active, 🔴 Red = Inactive)
- Tap sensors for detailed information
- Flow rate monitoring

🔌 **ESP32 WebSocket Integration**
- Real-time sensor data streaming
- Fallback to data simulation when offline
- Support for multiple sensors

## Quick Start

### Test Accounts
| Role | Email | Password |
|------|-------|----------|
| Consumer | `consumer@test.com` | `password123` |
| Technician | `technician@test.com` | `password123` |
| Admin | `admin@test.com` | `password123` |

### Run Locally
```bash
# Install dependencies
flutter pub get

# Run on web (Chrome)
flutter run -d chrome

# Or Android/iOS
flutter run -d android
flutter run -d ios
```

## Setup & Installation

For detailed setup instructions, see [README_SETUP.md](README_SETUP.md)

## Project Structure

```
lib/main.dart          # Main app with all screens & logic
├── Models             # User, WaterSensor, ConsumerReport
├── Services           # AuthService (state management)
├── Screens            # Login, Register, Dashboards
├── Custom Painters    # Map visualization
└── Utilities          # Helpers
```

## Key Components

- **AuthService**: User authentication & session management
- **ValenciaMapPainter**: Custom map with sensor visualization
- **Role-Based Navigation**: Automatic routing based on user role
- **WebSocket Support**: Real-time ESP32 sensor data

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **WebSocket**: Real-time communication
- **Custom Paint**: Map visualization

## Sensor System

- **4 Water Sensors** across Valencia City
- **Real-time Status**: Active (green) / Inactive (red)
- **Flow Rate Monitoring**: L/min measurements
- **Last Update Tracking**: Timestamp for each reading

## Platform Support

| Platform | Status |
|----------|--------|
| Web (Chrome) | ✅ Fully Supported |
| Android | ✅ Fully Supported |
| iOS | ✅ Fully Supported |
| Windows | ✅ Fully Supported |

## Offline Support

The app works completely offline:
- ✅ Login/registration (local storage)
- ✅ Dashboard access
- ✅ Sensor data simulation when ESP32 unavailable

## ESP32 Configuration

Edit IP and port in `lib/main.dart`:
```dart
final String _esp32Ip = '192.168.1.10';  // Your ESP32's IP
final int _esp32Port = 81;                // WebSocket port
```

Expected data format:
```json
{
  "sensorId": "S001",
  "flowRate": 12.5
}
```

## Future Enhancements

- 🔐 Backend authentication with JWT
- 💾 SQLite database for persistence
- 📍 Real GPS integration
- 📱 Push notifications
- 📈 Advanced analytics dashboard
- 🔔 Alert system for anomalies
- 🗺️ Multiple city support

## License

Created for: Human Computer Interaction 1 - CMU
Course: Third Year, First Semester

## Credits

Developed by: Nomos69
Repository: [VCWD-Water-Leakage-Monitoring](https://github.com/Nomos69/VCWD-Water-Leakage-Monitoring)

---

For detailed setup and development guide, see [README_SETUP.md](README_SETUP.md)
