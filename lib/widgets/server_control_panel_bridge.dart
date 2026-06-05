// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'network_settings_panel.dart' as fallback;

// Conditional import to resolve compile errors on clean public checkouts.
// Since dart.library.js_interop is false on desktop native builds, the compiler
// ignores the premium import path, keeping the build green when the folder is missing.
import 'network_settings_panel.dart'
    if (dart.library.js_interop) 'package:oslah/premium/server_control_panel.dart' as premium;

class ServerControlPanelBridge extends StatelessWidget {
  const ServerControlPanelBridge({super.key});

  @override
  Widget build(BuildContext context) {
    // PUBLIC FALLBACK: Return core NetworkSettingsPanel
    return const fallback.NetworkSettingsPanel();

    // ENTERPRISE PRO: Uncomment below and comment above to activate the premium control panel locally
    // return const premium.ServerControlPanel();
  }
}
