import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../widgets/chat_interface.dart';
import '../widgets/server_control_panel_bridge.dart';
import '../widgets/agent_builder_panel.dart';
import '../widgets/system_metrics_panel.dart';
import '../widgets/access_logs_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Deep Obsidian background
      body: Row(
        children: [
          // Left Sidebar
          const SidebarWidget(),
          
          // Vertical divider line
          Container(
            width: 1,
            color: const Color(0xFF1F2438),
          ),
          
          // Main Workspace area
          Expanded(
            child: Consumer<AgentProvider>(
              builder: (context, provider, child) {
                switch (provider.activeTab) {
                  case 'agentBuilder':
                    return const AgentBuilderPanel();
                  case 'metrics':
                    return const SystemMetricsPanel();
                  case 'logs':
                    return const AccessLogsPanel();
                  case 'settings':
                    return const SettingsWorkspace();
                  case 'server':
                    return const ServerControlPanelBridge();
                  case 'chat':
                  default:
                    return const ChatInterface();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Left Sidebar Navigation Widget
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Container(
      width: 280,
      color: const Color(0xFF0B0D16), // Darker obsidian sidebar
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131622),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E2338), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset('assets/images/logo.png', width: 24, height: 24, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OSLAH',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Local Agent Hub',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Ollama Connection Status & Model Selector
                  const SidebarModelSelector(),
                  const SizedBox(height: 24),

                  // Workspace Tabs Header
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'WORKSPACE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4B5563),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  // Navigation Links
                  SidebarTabItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'AI Chat Panel',
                    isSelected: provider.activeTab == 'chat',
                    onTap: () => provider.setActiveTab('chat'),
                  ),
                  const SizedBox(height: 6),
                  SidebarTabItem(
                    icon: Icons.psychology_outlined,
                    label: 'Agent Builder',
                    isSelected: provider.activeTab == 'agentBuilder',
                    onTap: () => provider.setActiveTab('agentBuilder'),
                  ),
                  const SizedBox(height: 6),
                  SidebarTabItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'System Metrics',
                    isSelected: provider.activeTab == 'metrics',
                    onTap: () => provider.setActiveTab('metrics'),
                  ),
                  const SizedBox(height: 6),
                  SidebarTabItem(
                    icon: Icons.lan_outlined,
                    label: 'Local Server API',
                    isSelected: provider.activeTab == 'server',
                    onTap: () => provider.setActiveTab('server'),
                  ),
                  const SizedBox(height: 6),
                  SidebarTabItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Access Logs',
                    isSelected: provider.activeTab == 'logs',
                    onTap: () => provider.setActiveTab('logs'),
                  ),
                  const SizedBox(height: 6),
                  SidebarTabItem(
                    icon: Icons.tune_rounded,
                    label: 'App Settings',
                    isSelected: provider.activeTab == 'settings',
                    onTap: () => provider.setActiveTab('settings'),
                  ),
                ],
              ),
            ),
          ),
          
          // Task Queue Status Indicator
          if (provider.isQueueProcessing || provider.queueLength > 0) ...[
            const SizedBox(height: 12),
            const QueueStatusWidget(),
          ],

          const SizedBox(height: 12),

          // Hardware Metrics panel
          const SystemMetricsWidget(),
        ],
      ),
    );
  }
}

/// Model Selector widget inside the sidebar
class SidebarModelSelector extends StatefulWidget {
  const SidebarModelSelector({super.key});

  @override
  State<SidebarModelSelector> createState() => _SidebarModelSelectorState();
}

class _SidebarModelSelectorState extends State<SidebarModelSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(AgentProvider provider) async {
    _rotationController.repeat();
    await provider.refreshModels();
    _rotationController.stop();
    _rotationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2336), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: provider.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (provider.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.isConnected ? 'Ollama Online' : 'Ollama Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: provider.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 16,
                  ),
                ),
                onPressed: () => _handleRefresh(provider),
              ),
            ],
          ),
          const SizedBox(height: 10),
          provider.isLoadingModels
              ? const SizedBox(
                  height: 38,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2132),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.selectedModel,
                      dropdownColor: const Color(0xFF1A1D2B),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      hint: const Text(
                        'Select Local Model',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      items: provider.availableModels.map((String model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(
                            model,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => provider.setSelectedModel(val),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/// Navigation Tab Item inside the sidebar
class SidebarTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarTabItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C1F32) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF313754) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Request Queue UI Indicator
class QueueStatusWidget extends StatelessWidget {
  const QueueStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1523), // Dark purple/wine accent
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B1E43), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sequential Queue Locked',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${provider.queueLength} request(s) waiting',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simulated hardware metrics panel in sidebar
class SystemMetricsWidget extends StatelessWidget {
  const SystemMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111422),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E233B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HARDWARE UTILIZATION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4B5563),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          // CPU Tracker
          MetricProgressBar(
            label: 'Local CPU System',
            value: provider.cpuUsage,
            accentColor: const Color(0xFF6366F1), // Indigo
          ),
          const SizedBox(height: 10),

          // RAM Tracker
          MetricProgressBar(
            label: 'Local RAM Allocation',
            value: provider.ramUsage,
            accentColor: const Color(0xFF10B981), // Emerald Green
          ),
        ],
      ),
    );
  }
}

/// Individual metric bar helper
class MetricProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color accentColor;

  const MetricProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: const Color(0xFF1F243B),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}


/// Core application connection settings workspace
class SettingsWorkspace extends StatefulWidget {
  const SettingsWorkspace({super.key});

  @override
  State<SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  late TextEditingController _urlController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AgentProvider>(context, listen: false);
    _urlController = TextEditingController(text: provider.ollamaUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(AgentProvider provider) async {
    setState(() {
      _isTesting = true;
    });

    provider.setOllamaUrl(_urlController.text.trim());
    await provider.refreshModels();

    setState(() {
      _isTesting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.isConnected
                ? 'Connection Successful! Models synchronised.'
                : 'Connection Failed: Please ensure Ollama server is running.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: provider.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          width: 380,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Preferences',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure host parameters and connectivity bindings for local-first execution.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Ollama Host Endpoint URL',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF131722),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF22293F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF22293F)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F243B),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF2E3452)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isTesting ? null : () => _testConnection(provider),
                          child: _isTesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Test Connection'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Typically http://localhost:11434 or http://127.0.0.1:11434 for local setups.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                  ),
                  const SizedBox(height: 32),

                  if (provider.connectionError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF200F15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF4C1523), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Connection Error Logs',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            provider.connectionError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFCA5A5),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
