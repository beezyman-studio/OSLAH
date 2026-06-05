import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/agent_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite FFI database factory for desktop platforms
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const OSLAHApp());
}

class OSLAHApp extends StatelessWidget {
  const OSLAHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AgentProvider()),
      ],
      child: MaterialApp(
      title: 'OSLAH - Local Agent Hub',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Standard Windows font fallback, looks clean
        
        // Color System Setup
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo
          secondary: Color(0xFFEC4899), // Pink accent
          surface: Color(0xFF0B0D16), // Obsidian base containers
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE5E7EB), // Soft gray text
        ),

        // Custom Component styling for dark theme
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        
        // Slider Custom Styling
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.onDrag,
        ),

        // Scrollbar Custom Styling
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF1E2338)),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          thickness: WidgetStateProperty.all(6),
          radius: const Radius.circular(3),
        ),

        // Tooltip Custom Styling
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2338),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF313754)),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
      home: Consumer<AgentProvider>(
        builder: (context, provider, _) {
          if (provider.isFirstLaunch) {
            return const SplashWelcomeScreen();
          }
          return const DashboardScreen();
        },
      ),
    ),);
  }
}
