import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:oslah/main.dart';
import 'package:oslah/providers/agent_provider.dart';
import 'package:oslah/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('OSLAH Onboarding Setup smoke test', (WidgetTester tester) async {
    // Configure virtual window size for desktop layout
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const OSLAHApp());
    await tester.pump();

    // Verify onboarding welcome screen is shown on first launch
    expect(find.text('OSLAH SETUP WIZARD'), findsOneWidget);
    expect(find.text('DeepSeek-R1 (7B)'), findsOneWidget);
    expect(find.text('Llama 3 (8B)'), findsOneWidget);
    expect(find.text('Phi-3 (3.8B)'), findsOneWidget);

    // Reset virtual viewport bounds
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('OSLAH Dashboard smoke test', (WidgetTester tester) async {
    // Configure virtual window size for desktop layout
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    // Create a provider and override first launch to false
    final provider = AgentProvider();
    provider.setFirstLaunchFinished();

    // Build the Dashboard screen directly wrapped in the provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AgentProvider>.value(value: provider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify that OSLAH branding is rendered on the Dashboard.
    expect(find.text('OSLAH'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('AI Chat Panel'), findsOneWidget);

    // Clean up provider to stop metrics timers
    provider.dispose();

    // Reset virtual viewport bounds
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
