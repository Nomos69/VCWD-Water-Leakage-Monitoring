import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const WaterMonitorApp());
}

// User model
enum UserRole { consumer, technician, admin }

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final DateTime createdAt;
  bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    DateTime? createdAt,
    this.isVerified = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

// Auth Service for managing user authentication
class AuthService extends ChangeNotifier {
  User? _currentUser;
  final Map<String, User> _userDatabase = {};

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;

  AuthService() {
    _initializeDefaultAccounts();
  }

  // Initialize with default test accounts
  void _initializeDefaultAccounts() {
    _userDatabase['consumer@test.com'] = User(
      id: '1',
      name: 'John Consumer',
      email: 'consumer@test.com',
      password: 'password123',
      role: UserRole.consumer,
      isVerified: true,
    );

    _userDatabase['technician@test.com'] = User(
      id: '2',
      name: 'Jane Technician',
      email: 'technician@test.com',
      password: 'password123',
      role: UserRole.technician,
      isVerified: true,
    );

    _userDatabase['admin@test.com'] = User(
      id: '3',
      name: 'Admin User',
      email: 'admin@test.com',
      password: 'password123',
      role: UserRole.admin,
      isVerified: true,
    );
  }

  // Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    if (_userDatabase.containsKey(email)) {
      throw Exception('Email already registered');
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('Please fill all fields');
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      role: role,
    );

    _userDatabase[email] = user;
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    notifyListeners();
    return true;
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Please fill all fields');
    }

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (!_userDatabase.containsKey(email)) {
      throw Exception('User not found');
    }

    final user = _userDatabase[email]!;
    if (user.password != password) {
      throw Exception('Invalid password');
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  // Logout user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Verify user email
  Future<bool> verifyEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_userDatabase.containsKey(email)) {
      _userDatabase[email]!.isVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }
}

class WaterMonitorApp extends StatelessWidget {
  const WaterMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Valencia Water Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// AuthWrapper to determine which screen to show
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isLoggedIn) {
          return const LoginScreen();
        }

        switch (authService.userRole) {
          case UserRole.consumer:
            return const ConsumerDashboardScreen();
          case UserRole.technician:
            return const TechnicianDashboardScreen();
          case UserRole.admin:
            return const AdminDashboardScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}

// Sensor model
class WaterSensor {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  double flowRate;
  bool hasFlow;
  DateTime lastUpdate;

  WaterSensor({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.flowRate = 0.0,
    this.hasFlow = false,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();
}

// Consumer Report model
enum ReportType { lowPressure, leakage }

enum ReportStatus { pending, inProgress, resolved }

class ConsumerReport {
  final String id;
  final String consumerName;
  final String contactNumber;
  final String address;
  final String barangay;
  final ReportType type;
  final String description;
  final DateTime reportedAt;
  ReportStatus status;
  final double latitude;
  final double longitude;

  ConsumerReport({
    required this.id,
    required this.consumerName,
    required this.contactNumber,
    required this.address,
    required this.barangay,
    required this.type,
    required this.description,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    required this.latitude,
    required this.longitude,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Sensors placed at different locations in Valencia City, Bukidnon
  // Valencia City coordinates: approximately 7.9042° N, 125.0928° E
  final List<WaterSensor> sensors = [
    WaterSensor(
      id: 'S001',
      name: 'Sensor 1 - Poblacion',
      location: 'Poblacion, Valencia City',
      latitude: 7.9042,
      longitude: 125.0928,
    ),
    WaterSensor(
      id: 'S002',
      name: 'Sensor 2 - Bagontaas',
      location: 'Bagontaas, Valencia City',
      latitude: 7.9150,
      longitude: 125.1050,
    ),
    WaterSensor(
      id: 'S003',
      name: 'Sensor 3 - Lumbo',
      location: 'Lumbo, Valencia City',
      latitude: 7.8950,
      longitude: 125.0800,
    ),
    WaterSensor(
      id: 'S004',
      name: 'Sensor 4 - Mailag',
      location: 'Mailag, Valencia City',
      latitude: 7.9200,
      longitude: 125.0750,
    ),
    WaterSensor(
      id: 'S005',
      name: 'Sensor 5 - Lumbayao',
      location: 'Lumbayao, Valencia City',
      latitude: 7.8880,
      longitude: 125.1100,
    ),
    WaterSensor(
      id: 'S006',
      name: 'Sensor 6 - Guinoyuran',
      location: 'Guinoyuran, Valencia City',
      latitude: 7.9300,
      longitude: 125.0900,
    ),
    WaterSensor(
      id: 'S007',
      name: 'Sensor 7 - Pinatilan',
      location: 'Pinatilan, Valencia City',
      latitude: 7.8800,
      longitude: 125.0950,
    ),
    WaterSensor(
      id: 'S008',
      name: 'Sensor 8 - Concepcion',
      location: 'Concepcion, Valencia City',
      latitude: 7.9100,
      longitude: 125.1150,
    ),
  ];

  // Consumer Reports List
  final List<ConsumerReport> _reports = [];
  int _currentView = 0; // 0 = Map, 1 = Reports

  Timer? _simulationTimer;
  WaterSensor? _selectedSensor;

  // WebSocket connection to ESP32
  WebSocketChannel? _channel;
  final String _esp32Ip = '192.168.1.10'; // Your ESP32's IP address
  final int _esp32Port = 81; // WebSocket port on ESP32

  @override
  void initState() {
    super.initState();
    // Try to connect to ESP32, fall back to simulation if not available
    _connectToESP32();
  }

  void _connectToESP32() {
    try {
      final wsUrl = Uri.parse('ws://$_esp32Ip:$_esp32Port');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          _handleESP32Data(message);
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _startDataSimulation(); // Fall back to simulation
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );

      setState(() {
        // Connection established
      });
    } catch (e) {
      print('Failed to connect to ESP32: $e');
      _startDataSimulation(); // Fall back to simulation
    }
  }

  void _handleESP32Data(String message) {
    // Expected format from ESP32: "SENSOR:S001,FLOW:12.5"
    try {
      final data = jsonDecode(message);
      final sensorId = data['sensorId'] as String;
      final flowRate = (data['flowRate'] as num).toDouble();

      setState(() {
        final sensor = sensors.firstWhere(
          (s) => s.id == sensorId,
          orElse: () => sensors[0],
        );
        sensor.flowRate = flowRate;
        sensor.hasFlow = flowRate > 0.5;
        sensor.lastUpdate = DateTime.now();
      });
    } catch (e) {
      // Try simple format: "S001:12.5"
      try {
        final parts = message.split(':');
        if (parts.length == 2) {
          final sensorId = parts[0].trim();
          final flowRate = double.tryParse(parts[1].trim()) ?? 0.0;

          setState(() {
            final sensor = sensors.firstWhere(
              (s) => s.id == sensorId,
              orElse: () => sensors[0],
            );
            sensor.flowRate = flowRate;
            sensor.hasFlow = flowRate > 0.5;
            sensor.lastUpdate = DateTime.now();
          });
        }
      } catch (e) {
        print('Error parsing sensor data: $e');
      }
    }
  }

  void _startDataSimulation() {
    // Simulate random flow data updates (In production, connect to ESP32 via WebSocket)
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        final random = Random();
        for (var sensor in sensors) {
          // Randomly update sensor data to simulate real sensor readings
          if (random.nextDouble() > 0.3) {
            sensor.flowRate = random.nextDouble() * 20; // 0-20 L/min
            sensor.hasFlow = sensor.flowRate > 0.5;
          } else {
            sensor.flowRate = 0.0;
            sensor.hasFlow = false;
          }
          sensor.lastUpdate = DateTime.now();
        }
      });
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingReports = _reports
        .where((r) => r.status == ReportStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.lightBlue),
            SizedBox(width: 10),
            Text('Valencia City Water Flow Monitor'),
          ],
        ),
        backgroundColor: const Color(0xFF1a237e),
        actions: [
          // Navigation buttons
          _buildNavButton(0, Icons.map, 'Map'),
          _buildNavButton(
            1,
            Icons.report_problem,
            'Reports',
            badge: pendingReports,
          ),
          const SizedBox(width: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatusIndicator(Colors.green, 'Flow Detected'),
                const SizedBox(width: 20),
                _buildStatusIndicator(Colors.red, 'No Flow'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentView == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddReportDialog(context),
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.add),
              label: const Text('New Report'),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a237e), Color(0xFF0d1421)],
          ),
        ),
        child: _currentView == 0 ? _buildMapSection() : _buildReportsSection(),
      ),
    );
  }

  Widget _buildNavButton(
    int index,
    IconData icon,
    String label, {
    int badge = 0,
  }) {
    final isSelected = _currentView == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _currentView = index),
            icon: Icon(
              icon,
              color: isSelected ? Colors.lightBlue : Colors.white70,
            ),
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.lightBlue : Colors.white70,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: isSelected ? Colors.white10 : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Row(
      children: [
        // Map section
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: const Color(0xFF263238),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white24)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.map, color: Colors.lightBlue),
                        SizedBox(width: 10),
                        Text(
                          'Valencia City, Bukidnon - Sensor Map',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildMapView()),
                ],
              ),
            ),
          ),
        ),
        // Sensor list section
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: const Color(0xFF263238),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white24)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sensors, color: Colors.lightBlue),
                        SizedBox(width: 10),
                        Text(
                          'Sensor Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildSensorList()),
                  _buildStatsSummary(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Reports Section
  Widget _buildReportsSection() {
    return Row(
      children: [
        // Reports List
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: const Color(0xFF263238),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.report_problem, color: Colors.orange),
                        const SizedBox(width: 10),
                        const Text(
                          'Consumer Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _buildReportFilter(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _reports.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No reports yet',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                Text(
                                  'Click "New Report" to add one',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              return _buildReportCard(report);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Reports Summary
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildReportsSummaryCard(),
                const SizedBox(height: 16),
                _buildRecentActivityCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'All',
          dropdownColor: const Color(0xFF263238),
          style: const TextStyle(color: Colors.white70),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Reports')),
            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
            DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
            DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
          ],
          onChanged: (value) {},
        ),
      ),
    );
  }

  Widget _buildReportCard(ConsumerReport report) {
    final isLeakage = report.type == ReportType.leakage;
    final statusColor = report.status == ReportStatus.pending
        ? Colors.orange
        : report.status == ReportStatus.inProgress
        ? Colors.blue
        : Colors.green;

    return Card(
      color: Colors.blueGrey[800],
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLeakage
                        ? Colors.red.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLeakage ? Icons.water_damage : Icons.compress,
                    color: isLeakage ? Colors.red : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLeakage ? 'Water Leakage' : 'Low Pressure',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        report.barangay,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    report.status == ReportStatus.pending
                        ? 'PENDING'
                        : report.status == ReportStatus.inProgress
                        ? 'IN PROGRESS'
                        : 'RESOLVED',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                report.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  report.consumerName,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  report.contactNumber,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _formatDate(report.reportedAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (report.status == ReportStatus.pending)
                  TextButton.icon(
                    onPressed: () =>
                        _updateReportStatus(report, ReportStatus.inProgress),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                if (report.status == ReportStatus.inProgress)
                  TextButton.icon(
                    onPressed: () =>
                        _updateReportStatus(report, ReportStatus.resolved),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Resolve',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                TextButton.icon(
                  onPressed: () => _deleteReport(report),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSummaryCard() {
    final pending = _reports
        .where((r) => r.status == ReportStatus.pending)
        .length;
    final inProgress = _reports
        .where((r) => r.status == ReportStatus.inProgress)
        .length;
    final resolved = _reports
        .where((r) => r.status == ReportStatus.resolved)
        .length;
    final leakages = _reports.where((r) => r.type == ReportType.leakage).length;
    final lowPressure = _reports
        .where((r) => r.type == ReportType.lowPressure)
        .length;

    return Card(
      elevation: 8,
      color: const Color(0xFF263238),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.lightBlue),
                SizedBox(width: 8),
                Text(
                  'Reports Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Total Reports',
              _reports.length.toString(),
              Colors.white,
            ),
            _buildSummaryRow('Pending', pending.toString(), Colors.orange),
            _buildSummaryRow('In Progress', inProgress.toString(), Colors.blue),
            _buildSummaryRow('Resolved', resolved.toString(), Colors.green),
            const Divider(color: Colors.white24),
            _buildSummaryRow('Leakages', leakages.toString(), Colors.red),
            _buildSummaryRow(
              'Low Pressure',
              lowPressure.toString(),
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Expanded(
      child: Card(
        elevation: 8,
        color: const Color(0xFF263238),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.lightBlue),
                  SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _reports.isEmpty
                    ? const Center(
                        child: Text(
                          'No activity',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _reports.length > 5 ? 5 : _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              report.type == ReportType.leakage
                                  ? Icons.water_damage
                                  : Icons.compress,
                              color: report.type == ReportType.leakage
                                  ? Colors.red
                                  : Colors.orange,
                              size: 20,
                            ),
                            title: Text(
                              report.barangay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              _formatDate(report.reportedAt),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _updateReportStatus(ConsumerReport report, ReportStatus newStatus) {
    setState(() {
      report.status = newStatus;
    });
  }

  void _deleteReport(ConsumerReport report) {
    setState(() {
      _reports.remove(report);
    });
  }

  void _showAddReportDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String consumerName = '';
    String contactNumber = '';
    String address = '';
    String selectedBarangay = 'Poblacion';
    ReportType selectedType = ReportType.lowPressure;
    String description = '';

    final barangays = [
      'Poblacion',
      'Bagontaas',
      'Lumbo',
      'Mailag',
      'Lumbayao',
      'Guinoyuran',
      'Pinatilan',
      'Concepcion',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              'Submit Consumer Report',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Consumer Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Colors.white54),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (v) => consumerName = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone, color: Colors.white54),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (v) => contactNumber = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home, color: Colors.white54),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (v) => address = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBarangay,
                    decoration: const InputDecoration(
                      labelText: 'Barangay',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Colors.white54,
                      ),
                    ),
                    dropdownColor: const Color(0xFF263238),
                    style: const TextStyle(color: Colors.white),
                    items: barangays
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => selectedBarangay = v ?? 'Poblacion',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ReportType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, color: Colors.white54),
                    ),
                    dropdownColor: const Color(0xFF263238),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: ReportType.lowPressure,
                        child: Text('Low Pressure'),
                      ),
                      DropdownMenuItem(
                        value: ReportType.leakage,
                        child: Text('Water Leakage'),
                      ),
                    ],
                    onChanged: (v) =>
                        selectedType = v ?? ReportType.lowPressure,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.description,
                        color: Colors.white54,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (v) => description = v ?? '',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();

                // Get coordinates based on barangay
                final coords = _getBarangayCoords(selectedBarangay);

                setState(() {
                  _reports.insert(
                    0,
                    ConsumerReport(
                      id: 'R${DateTime.now().millisecondsSinceEpoch}',
                      consumerName: consumerName,
                      contactNumber: contactNumber,
                      address: address,
                      barangay: selectedBarangay,
                      type: selectedType,
                      description: description,
                      reportedAt: DateTime.now(),
                      latitude: coords['lat']!,
                      longitude: coords['lng']!,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Submit Report'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getBarangayCoords(String barangay) {
    final coords = {
      'Poblacion': {'lat': 7.9042, 'lng': 125.0928},
      'Bagontaas': {'lat': 7.9150, 'lng': 125.1050},
      'Lumbo': {'lat': 7.8950, 'lng': 125.0800},
      'Mailag': {'lat': 7.9200, 'lng': 125.0750},
      'Lumbayao': {'lat': 7.8880, 'lng': 125.1100},
      'Guinoyuran': {'lat': 7.9300, 'lng': 125.0900},
      'Pinatilan': {'lat': 7.8800, 'lng': 125.0950},
      'Concepcion': {'lat': 7.9100, 'lng': 125.1150},
    };
    return coords[barangay] ?? {'lat': 7.9042, 'lng': 125.0928};
  }

  Widget _buildStatusIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildMapView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Map background with Valencia City representation
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1b2838),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: ValenciaMapPainter(),
                child: Stack(
                  children: [
                    // City label
                    const Positioned(
                      top: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VALENCIA CITY',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Bukidnon, Philippines',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sensor markers
                    ...sensors.map((sensor) {
                      return _buildSensorMarker(sensor, constraints);
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorMarker(WaterSensor sensor, BoxConstraints constraints) {
    // Convert lat/long to screen position
    // Valencia City bounds (approximate)
    const minLat = 7.87;
    const maxLat = 7.94;
    const minLong = 125.07;
    const maxLong = 125.12;

    final x =
        ((sensor.longitude - minLong) / (maxLong - minLong)) *
            (constraints.maxWidth - 100) +
        50;
    final y =
        ((maxLat - sensor.latitude) / (maxLat - minLat)) *
            (constraints.maxHeight - 100) +
        50;

    final isSelected = _selectedSensor?.id == sensor.id;

    return Positioned(
      left: x - 15,
      top: y - 15,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedSensor = sensor;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                // Pulse animation for active sensors
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (sensor.hasFlow)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Container(
                            width: 40 + (value * 10),
                            height: 40 + (value * 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(
                                0.3 - (value * 0.3),
                              ),
                            ),
                          );
                        },
                        onEnd: () {},
                      ),
                    Container(
                      width: isSelected ? 35 : 30,
                      height: isSelected ? 35 : 30,
                      decoration: BoxDecoration(
                        color: sensor.hasFlow ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white54,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (sensor.hasFlow ? Colors.green : Colors.red)
                                .withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.water_drop,
                        size: isSelected ? 18 : 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          sensor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${sensor.flowRate.toStringAsFixed(1)} L/min',
                          style: TextStyle(
                            color: sensor.hasFlow
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        final isSelected = _selectedSensor?.id == sensor.id;

        return Card(
          color: isSelected ? Colors.blueGrey[700] : Colors.blueGrey[800],
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            onTap: () {
              setState(() {
                _selectedSensor = sensor;
              });
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: sensor.hasFlow
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: sensor.hasFlow ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Icon(
                sensor.hasFlow ? Icons.check : Icons.close,
                color: sensor.hasFlow ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              sensor.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.location,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 12,
                      color: sensor.hasFlow
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sensor.flowRate.toStringAsFixed(2)} L/min',
                      style: TextStyle(
                        color: sensor.hasFlow
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sensor.hasFlow ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sensor.hasFlow ? 'FLOW' : 'NO FLOW',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSummary() {
    final flowingCount = sensors.where((s) => s.hasFlow).length;
    final notFlowingCount = sensors.length - flowingCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        children: [
          const Text(
            'SUMMARY',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Active', flowingCount.toString(), Colors.green),
              _buildStatCard(
                'Inactive',
                notFlowingCount.toString(),
                Colors.red,
              ),
              _buildStatCard('Total', sensors.length.toString(), Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

// Custom painter for Valencia City map background
class ValenciaMapPainter extends CustomPainter {
  final List<WaterSensor>? sensors;

  ValenciaMapPainter({this.sensors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid lines to represent streets/roads
    for (int i = 0; i < 20; i++) {
      // Horizontal lines
      canvas.drawLine(
        Offset(0, size.height * i / 20),
        Offset(size.width, size.height * i / 20),
        paint..color = Colors.white.withOpacity(0.05),
      );
      // Vertical lines
      canvas.drawLine(
        Offset(size.width * i / 20, 0),
        Offset(size.width * i / 20, size.height),
        paint..color = Colors.white.withOpacity(0.05),
      );
    }

    // Draw some abstract roads/paths
    final roadPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Main road (horizontal)
    final mainRoad = Path();
    mainRoad.moveTo(0, size.height * 0.5);
    mainRoad.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.5,
    );
    mainRoad.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.6,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(mainRoad, roadPaint);

    // Secondary road (vertical)
    final secondaryRoad = Path();
    secondaryRoad.moveTo(size.width * 0.5, 0);
    secondaryRoad.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    secondaryRoad.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.7,
      size.width * 0.5,
      size.height,
    );
    canvas.drawPath(secondaryRoad, roadPaint..strokeWidth = 2);

    // Draw decorative elements representing barangay areas
    final areaPaint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      80,
      areaPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.4),
      60,
      areaPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.7),
      70,
      areaPaint,
    );

    // Draw sensors on the map
    if (sensors != null) {
      for (var sensor in sensors!) {
        // Map coordinates
        const mapMinLat = 7.85, mapMaxLat = 7.95;
        const mapMinLon = 125.05, mapMaxLon = 125.15;

        // Convert lat/lon to canvas coordinates
        final x = (sensor.longitude - mapMinLon) / (mapMaxLon - mapMinLon) * size.width;
        final y = (mapMaxLat - sensor.latitude) / (mapMaxLat - mapMinLat) * size.height;

        // Draw sensor circle based on status
        final sensorColor = sensor.hasFlow ? Colors.green : Colors.red;
        
        // Outer glow
        final glowPaint = Paint()
          ..color = sensorColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 20, glowPaint);

        // Main circle
        final sensorPaint = Paint()
          ..color = sensorColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 12, sensorPaint);

        // Center dot
        final centerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 6, centerPaint);
      }
    }

    // Draw compass
    final compassPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final compassX = size.width - 60;
    final compassY = size.height - 60;

    canvas.drawCircle(Offset(compassX, compassY), 25, compassPaint);

    // North indicator
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(color: Colors.white54, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(compassX - 5, compassY - 40));
  }

  @override
  bool shouldRepaint(ValenciaMapPainter oldDelegate) {
    return oldDelegate.sensors != sensors;
  }
}

// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                const SizedBox(height: 20),
                const Icon(
                  Icons.water_drop,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Valencia Water Monitor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smart Water Management System',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register here',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// REGISTER SCREEN
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.consumer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name Field
              const Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              const Text(
                'Confirm Password',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role Selection
              const Text(
                'Select Your Role',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<UserRole>(
                  value: _selectedRole,
                  isExpanded: true,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (role) {
                    if (role != null) {
                      setState(() {
                        _selectedRole = role;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getRoleDescription(_selectedRole),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.consumer:
        return 'Report water issues and track service requests';
      case UserRole.technician:
        return 'Manage and respond to water reports';
      case UserRole.admin:
        return 'Oversee entire system and user management';
    }
  }
}

// CONSUMER DASHBOARD SCREEN
class ConsumerDashboardScreen extends StatefulWidget {
  const ConsumerDashboardScreen({super.key});

  @override
  State<ConsumerDashboardScreen> createState() =>
      _ConsumerDashboardScreenState();
}

class _ConsumerDashboardScreenState extends State<ConsumerDashboardScreen> {
  final List<ConsumerReport> reports = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumer Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthService>(
              builder: (context, authService, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${authService.currentUser?.name}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authService.currentUser?.email ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Stats
            const Text(
              'Your Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Pending', reports
                    .where((r) => r.status == ReportStatus.pending)
                    .length
                    .toString()),
                _buildStatCard('In Progress', reports
                    .where((r) => r.status == ReportStatus.inProgress)
                    .length
                    .toString()),
                _buildStatCard('Resolved', reports
                    .where((r) => r.status == ReportStatus.resolved)
                    .length
                    .toString()),
                _buildStatCard('Total', reports.length.toString()),
              ],
            ),
            const SizedBox(height: 24),

            // Report Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Report'),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Reports
            if (reports.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    report.type.toString().split('.').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(report.status)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      report.status
                                          .toString()
                                          .split('.')
                                          .last,
                                      style: TextStyle(
                                        color: _getStatusColor(report.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reports yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
    }
  }
}

// TECHNICIAN DASHBOARD SCREEN
class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  final List<ConsumerReport> pendingReports = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthService>(
              builder: (context, authService, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${authService.currentUser?.name}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Technician Mode',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Task Stats
            const Text(
              'Task Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Pending', '5', Colors.orange),
                _buildStatCard('In Progress', '3', Colors.blue),
                _buildStatCard('Completed', '12', Colors.green),
                _buildStatCard('Total', '20', Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Tasks
            const Text(
              'Pending Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (pendingReports.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All tasks completed!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ADMIN DASHBOARD SCREEN
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentView = 0; // 0 = Overview, 1 = Map, 2 = Management

  // Sensors placed at different locations in Valencia City, Bukidnon
  final List<WaterSensor> sensors = [
    WaterSensor(
      id: 'S001',
      name: 'Sensor 1 - Poblacion',
      location: 'Poblacion, Valencia City',
      latitude: 7.9042,
      longitude: 125.0928,
      flowRate: 45.2,
      hasFlow: true,
    ),
    WaterSensor(
      id: 'S002',
      name: 'Sensor 2 - Paralinao',
      location: 'Paralinao, Valencia City',
      latitude: 7.8950,
      longitude: 125.0850,
      flowRate: 0.0,
      hasFlow: false,
    ),
    WaterSensor(
      id: 'S003',
      name: 'Sensor 3 - Tagbual',
      location: 'Tagbual, Valencia City',
      latitude: 7.9150,
      longitude: 125.1050,
      flowRate: 0.0,
      hasFlow: false,
    ),
    WaterSensor(
      id: 'S004',
      name: 'Sensor 4 - Upland',
      location: 'Upland, Valencia City',
      latitude: 7.8850,
      longitude: 125.0750,
      flowRate: 0.0,
      hasFlow: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentView,
        onTap: (index) {
          setState(() {
            _currentView = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Management',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentView) {
      case 0:
        return _buildOverviewSection();
      case 1:
        return _buildMapSection();
      case 2:
        return _buildManagementSection();
      default:
        return _buildOverviewSection();
    }
  }

  Widget _buildOverviewSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${authService.currentUser?.name}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Administrator Mode',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // System Stats
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Total Users', '156', Colors.blue),
              _buildStatCard('Active Sensors', '${sensors.where((s) => s.hasFlow).length}', Colors.green),
              _buildStatCard('Pending Reports', '8', Colors.orange),
              _buildStatCard('System Health', '98%', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        
        // Map coordinates (approximate)
        const mapMinLat = 7.85, mapMaxLat = 7.95;
        const mapMinLon = 125.05, mapMaxLon = 125.15;
        const mapWidth = 800.0, mapHeight = 600.0;
        
        final lat = mapMaxLat - (local.dy / mapHeight) * (mapMaxLat - mapMinLat);
        final lon = mapMinLon + (local.dx / mapWidth) * (mapMaxLon - mapMinLon);
        
        // Find nearest sensor
        WaterSensor? nearest;
        double minDistance = double.infinity;
        
        for (var sensor in sensors) {
          final distance = sqrt(((sensor.latitude - lat) * (sensor.latitude - lat) +
              (sensor.longitude - lon) * (sensor.longitude - lon)));
          if (distance < minDistance && distance < 0.01) {
            minDistance = distance;
            nearest = sensor;
          }
        }
        
        if (nearest != null) {
          _showSensorDetails(nearest);
        }
      },
      child: Stack(
        children: [
          // Map with sensors
          CustomPaint(
            painter: ValenciaMapPainter(sensors: sensors),
            size: Size.infinite,
          ),
          
          // Top info panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Valencia City Water Monitor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active: ${sensors.where((s) => s.hasFlow).length}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Inactive: ${sensors.where((s) => !s.hasFlow).length}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap on a sensor to view details',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom sensor list
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sensors.map((sensor) {
                    return GestureDetector(
                      onTap: () => _showSensorDetails(sensor),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sensor.hasFlow ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sensor.hasFlow ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sensor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sensor.flowRate.toStringAsFixed(1)} L/min',
                              style: TextStyle(
                                color: sensor.hasFlow ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSensorDetails(WaterSensor sensor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sensor.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${sensor.location}'),
            const SizedBox(height: 8),
            Text('Latitude: ${sensor.latitude.toStringAsFixed(4)}'),
            const SizedBox(height: 8),
            Text('Longitude: ${sensor.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sensor.hasFlow ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Flow Rate: ${sensor.flowRate.toStringAsFixed(2)} L/min',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: sensor.hasFlow ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${sensor.hasFlow ? "Active" : "Inactive"}',
                    style: TextStyle(
                      color: sensor.hasFlow ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Update: ${sensor.lastUpdate.toString().split('.')[0]}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildManagementOption(
            'Users',
            'Manage user accounts and roles',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildManagementOption(
            'Sensors',
            'Monitor and configure sensors',
            Icons.sensors,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildManagementOption(
            'Reports',
            'View and manage all reports',
            Icons.assessment,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildManagementOption(
            'System Settings',
            'Configure system parameters',
            Icons.settings,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title feature coming soon!'),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
