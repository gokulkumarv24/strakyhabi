import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/providers/providers.dart';
import 'package:streaky_app/ai/ai.dart';
import 'package:streaky_app/screens/auth_screen.dart';
import 'package:streaky_app/screens/home_screen.dart';
import 'package:streaky_app/services/notification_service.dart';
import 'package:streaky_app/services/local_storage.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await _initializeServices();

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: StreakyApp(),
    ),
  );
}

/// Initialize core services before app starts
Future<void> _initializeServices() async {
  try {
    // Initialize local storage (Hive)
    await LocalStorageService.initialize();

    // Initialize notification service
    await NotificationService.initialize();

    // Initialize AI service (non-blocking)
    AiService.initialize().catchError((error) {
      print('AI Service initialization failed: $error');
    });

    print('✅ Core services initialized successfully');
  } catch (e) {
    print('❌ Service initialization failed: $e');
    // Continue with app launch even if some services fail
  }
}

/// Main app widget
class StreakyApp extends ConsumerWidget {
  const StreakyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Streaky - Productivity & Habits',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ),
      
      // Dark theme configuration
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ),
      
      // Use system theme
      themeMode: ThemeMode.system,
      
      // Home widget that handles authentication
      home: const AppWrapper(),
    );
  }
}

/// App wrapper that handles navigation based on auth state
class AppWrapper extends ConsumerWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading screen while initializing
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Streaky...'),
            ],
          ),
        ),
      );
    }

    // Show main app if authenticated, otherwise show auth screen
    return authState.isAuthenticated 
        ? const HomeScreen() 
        : const AuthScreen();
  }
}