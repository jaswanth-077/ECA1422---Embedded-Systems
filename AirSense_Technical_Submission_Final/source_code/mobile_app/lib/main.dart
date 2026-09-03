import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'repositories/mock_sensor_repository.dart';
import 'repositories/firebase_sensor_repository.dart';
import 'repositories/sensor_repository.dart';
import 'screens/main_screen.dart';

// Development toggle: set to true to test UI with static mock values without connecting to Firebase.
const bool useMockRepository = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SensorRepository sensorRepository;

  if (useMockRepository) {
    sensorRepository = MockSensorRepository();
  } else {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDummyKeyForCollegeProjectDemo",
          appId: "1:dummy-app-id-for-project-demonstration",
          messagingSenderId: "1234567890",
          projectId: "airquality-f7011",
          databaseURL: "https://airquality-f7011-default-rtdb.firebaseio.com",
        ),
      );
      sensorRepository = FirebaseSensorRepository();
    } catch (e) {
      // Fallback: instantiate repository to allow stream connection errors to surface in UI
      sensorRepository = FirebaseSensorRepository();
    }
  }

  runApp(AirSenseApp(repository: sensorRepository));
}

class AirSenseApp extends StatelessWidget {
  final SensorRepository repository;

  const AirSenseApp({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirSense',
      debugShowCheckedModeBanner: false,
      
      // Light theme design config
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.teal,
          primary: Colors.teal[700]!,
          secondary: Colors.blue[600]!,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),

      // Dark theme design config
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.teal,
          primary: Colors.teal[300]!,
          secondary: Colors.blue[400]!,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      
      themeMode: ThemeMode.system, // Responsive dark/light theme switching based on Android settings
      home: MainScreen(repository: repository),
    );
  }
}
