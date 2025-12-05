# Valencia Water Monitor - Setup Guide

A smart water management system for Valencia City, Bukidnon with real-time sensor monitoring, role-based dashboards, and water issue reporting.

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
- Real-time sensor status visualization (Green = Active, Red = Inactive)
- Tap sensors for detailed information
- Flow rate monitoring

🔌 **ESP32 WebSocket Integration**
- Real-time sensor data streaming
- Fallback to data simulation when offline
- Support for multiple sensors

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: [Download here](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Comes with Flutter
- **Git**: [Download here](https://git-scm.com/)
- **Code Editor**: VS Code, Android Studio, or IntelliJ IDEA

### Verify Installation
```bash
flutter --version
dart --version
```

## Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd valencia_water_monitor
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Get Required Packages
The app uses the following packages (auto-installed via `pub get`):
```
- provider: ^6.0.0 (State management)
- web_socket_channel: ^2.4.0 (WebSocket connection)
- sqflite: ^2.4.2 (Local database)
- path_provider: ^2.1.5 (File path access)
- shared_preferences: ^2.5.3 (Local preferences)
- cupertino_icons: ^1.0.8 (iOS icons)
```

### 4. Run the Application

**For Web (Chrome):**
```bash
flutter run -d chrome
```

**For Android:**
```bash
flutter run -d android
```

**For iOS:**
```bash
flutter run -d ios
```

**For Windows:**
```bash
flutter run -d windows
```

## Test Accounts

The app comes pre-configured with three test accounts:

| Role | Email | Password |
|------|-------|----------|
| Consumer | `consumer@test.com` | `password123` |
| Technician | `technician@test.com` | `password123` |
| Admin | `admin@test.com` | `password123` |

### Testing Each Role

1. **Consumer**: 
   - Can report water issues (low pressure, leakage)
   - View their submitted reports and status
   - Track service requests

2. **Technician**:
   - View pending tasks and assignments
   - Monitor task overview statistics
   - Update task statuses

3. **Admin**:
   - View system overview and statistics
   - Access interactive Valencia City water sensor map
   - Manage users, sensors, reports, and system settings

## Project Structure

```
valencia_water_monitor/
├── lib/
│   └── main.dart              # Main app file with all screens
├── android/                   # Android configuration
├── ios/                       # iOS configuration
├── web/                       # Web configuration
├── windows/                   # Windows configuration
├── pubspec.yaml              # Flutter dependencies
├── analysis_options.yaml     # Lint rules
├── README.md                 # Main documentation
└── README_SETUP.md          # This file
```

## Key Components

### Authentication (`AuthService`)
- Manages user login/registration
- Stores user data locally
- Handles session state
- Pre-loaded test accounts

### User Model
```dart
enum UserRole { consumer, technician, admin }

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  bool isVerified;
  // ...
}
```

### Screens
1. **LoginScreen** - User authentication
2. **RegisterScreen** - New user registration
3. **ConsumerDashboardScreen** - Consumer view
4. **TechnicianDashboardScreen** - Technician view
5. **AdminDashboardScreen** - Admin view with 3 tabs:
   - Overview: Statistics
   - Map: Sensor visualization
   - Management: System management

### Sensor System
- **WaterSensor Model**: Represents individual water sensors
- **ValenciaMapPainter**: Custom painter for map visualization
- **Status**: Green (active/connected), Red (inactive/disconnected)

## ESP32 WebSocket Connection

### Configuration
Edit the ESP32 connection settings in `_DashboardScreenState`:
```dart
final String _esp32Ip = '192.168.1.10';  // Your ESP32's IP
final int _esp32Port = 81;                // WebSocket port
```

### Expected Data Format
The app accepts sensor data in two formats:

**Format 1 (JSON):**
```json
{
  "sensorId": "S001",
  "flowRate": 12.5
}
```

**Format 2 (Simple):**
```
S001:12.5
```

### Sensor Status
- **Active**: Flow rate > 0.5 L/min (Green)
- **Inactive**: Flow rate ≤ 0.5 L/min (Red)

## Offline Functionality

The app works completely offline:
- ✅ Login/registration (local storage)
- ✅ Dashboard access
- ✅ Sensor data simulation when ESP32 unavailable
- ✅ All features except real ESP32 data

When ESP32 is unavailable, the app automatically switches to simulated sensor data.

## Building for Production

### Web
```bash
flutter build web
```

### Android
```bash
flutter build apk
# Or for release
flutter build appbundle
```

### iOS
```bash
flutter build ios
```

### Windows
```bash
flutter build windows
```

## Troubleshooting

### Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

### WebSocket Connection Issues
- Ensure ESP32 is on the same network
- Check IP address and port settings
- App will fall back to simulation if connection fails

### Dependency Issues
```bash
flutter pub upgrade
flutter pub get
```

### Developer Mode (Windows)
If building for Windows fails with symlink error:
```bash
# Run as Administrator
start ms-settings:developers
# Enable "Developer Mode"
```

## Platform Support

| Platform | Status |
|----------|--------|
| Web (Chrome) | ✅ Fully Supported |
| Android | ✅ Fully Supported |
| iOS | ✅ Fully Supported |
| Windows | ✅ Fully Supported |
| macOS | ✅ Supported |
| Linux | ✅ Supported |

## Database

Currently uses in-memory storage. To persist data across sessions:

**Option 1: Local Database (SQLite)**
```dart
import 'package:sqflite/sqflite.dart';
```

**Option 2: Shared Preferences**
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

Both packages are already in `pubspec.yaml`.

## API Integration

To connect to a backend server instead of local storage:

1. Replace `AuthService` methods with HTTP calls
2. Use `package:http` for API requests
3. Store auth tokens in `SharedPreferences`

Example:
```dart
import 'package:http/http.dart' as http;

Future<bool> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('https://your-api.com/login'),
    body: {'email': email, 'password': password},
  );
  // Handle response
}
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## File Structure

```
lib/main.dart (All code in one file):
├── Models
│   ├── User
│   ├── UserRole (enum)
│   ├── WaterSensor
│   ├── ConsumerReport
│   ├── ReportType (enum)
│   └── ReportStatus (enum)
│
├── Services
│   └── AuthService (ChangeNotifier)
│
├── Screens
│   ├── WaterMonitorApp (Main widget)
│   ├── AuthWrapper
│   ├── LoginScreen
│   ├── RegisterScreen
│   ├── ConsumerDashboardScreen
│   ├── TechnicianDashboardScreen
│   └── AdminDashboardScreen
│
├── Custom Painters
│   └── ValenciaMapPainter
│
└── Utilities
    └── Helpers (Dialog, Colors, etc.)
```

## Future Enhancements

- 🔐 Backend authentication with JWT
- 💾 SQLite database for persistence
- 📍 Real GPS integration
- 📱 Push notifications
- 📈 Analytics dashboard
- 🔔 Alert system for anomalies
- 🗺️ Multiple city support
- 🌐 API integration

## License

This project is created for Human-Computer Interaction course at CMU.

## Support

For issues or questions:
1. Check the Flutter documentation: https://flutter.dev/docs
2. Review the code comments in `main.dart`
3. Refer to package documentation on pub.dev

## Contact

Created for: Human Computer Interaction 1 - CMU
Course: Third Year, First Semester

---

**Last Updated**: December 5, 2025
**Version**: 1.0.0
