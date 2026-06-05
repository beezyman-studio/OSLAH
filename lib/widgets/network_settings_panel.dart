import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../services/local_server_service.dart';

class NetworkSettingsPanel extends StatefulWidget {
  const NetworkSettingsPanel({super.key});

  @override
  State<NetworkSettingsPanel> createState() => _NetworkSettingsPanelState();
}

class _NetworkSettingsPanelState extends State<NetworkSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _apiKeyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AgentProvider>(context, listen: false);
    _hostController = TextEditingController(text: provider.serverHost);
    _portController = TextEditingController(text: provider.serverPort.toString());
    _apiKeyController = TextEditingController(text: provider.serverApiKey);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _generateRandomKey() {
    // Generate a simple 16-char random alphanumeric key
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final key = List.generate(16, (i) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]).join();
    setState(() {
      _apiKeyController.text = key;
    });
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        width: 280,
      ),
    );
  }

  void _saveConfiguration(AgentProvider provider) {
    if (_formKey.currentState!.validate()) {
      final port = int.tryParse(_portController.text.trim()) ?? 8080;
      provider.updateServerConfig(
        host: _hostController.text.trim(),
        port: port,
        apiKey: _apiKeyController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Server configurations updated.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          width: 300,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);
    final isRunning = provider.isServerRunning;
    final serverUrl = 'http://${provider.localIpAddress}:${provider.serverPort}/api/chat';

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left configuration form column (60% width)
          Expanded(
            flex: 6,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-User API Engine',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Expose OSLAH local LLM sequential queue to other network clients securely.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    // Server status hero card
                    ServerStatusCard(
                      isRunning: isRunning,
                      ipAddress: provider.localIpAddress,
                      port: provider.serverPort,
                      serverUrl: serverUrl,
                      onCopy: () => _copyToClipboard(serverUrl, 'API Endpoint copied to clipboard!'),
                      onToggle: () async {
                        try {
                          await provider.toggleServer();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Server Error: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'HOST BINDING PARAMETERS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Host IP binding field
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Binding Host IP Address',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _hostController,
                                enabled: !isRunning,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF131722),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF22293F)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Binding IP is required.';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Port binding field
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Port Binding',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _portController,
                                enabled: !isRunning,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF131722),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF22293F)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Port is required.';
                                  final p = int.tryParse(value);
                                  if (p == null || p < 1 || p > 65535) return 'Invalid Port number.';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Security Key Verification Section
                    const Text(
                      'API GATEWAY SECURITY BINDINGS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Client Authorization Key (Optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _apiKeyController,
                                obscureText: _obscureKey,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Courier'),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF131722),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF22293F)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: const Color(0xFF4B5563),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureKey = !_obscureKey;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F243B),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF2E3452)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _generateRandomKey,
                                child: const Text('Generate Token', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If configured, remote requests must include X-OSLAH-Key or Bearer token header authorization.',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Apply config button
                    if (!isRunning)
                      SizedBox(
                        width: 200,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _saveConfiguration(provider),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Save Configurations',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Vertical divider separator
          Container(
            width: 1,
            height: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            color: const Color(0xFF1E2338),
          ),

          // Right traffic monitor column (40% width)
          Expanded(
            flex: 4,
            child: const ServerTrafficMonitor(),
          ),
        ],
      ),
    );
  }
}

/// Server Status Indicator Card
class ServerStatusCard extends StatelessWidget {
  final bool isRunning;
  final String ipAddress;
  final int port;
  final String serverUrl;
  final VoidCallback onCopy;
  final VoidCallback onToggle;

  const ServerStatusCard({
    super.key,
    required this.isRunning,
    required this.ipAddress,
    required this.port,
    required this.serverUrl,
    required this.onCopy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isRunning ? const Color(0xFF101B24) : const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? const Color(0xFF1E3A3B) : const Color(0xFF282D3D),
          width: 1.5,
        ),
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
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isRunning ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isRunning ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRunning ? 'GATEWAY ROUTER: ONLINE' : 'GATEWAY ROUTER: OFFLINE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isRunning ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onToggle,
                child: Row(
                  children: [
                    Icon(
                      isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRunning ? 'Shutdown' : 'Launch Server',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1E2338), height: 1),
          const SizedBox(height: 24),
          const Text(
            'HOST ENDPOINT CLIENT URL',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  serverUrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF818CF8), size: 18),
                onPressed: onCopy,
                tooltip: 'Copy API URL',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Server Active Traffic Monitor
class ServerTrafficMonitor extends StatelessWidget {
  const ServerTrafficMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);
    final activeRequests = provider.activeServerRequests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Traffic Monitor',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activeRequests.isNotEmpty ? const Color(0xFF3B1E43) : const Color(0xFF111422),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${activeRequests.length} Running',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: activeRequests.isNotEmpty ? const Color(0xFFEC4899) : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Monitors real-time API query loads routed into the sequential processor.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: activeRequests.isEmpty
              ? const EmptyMonitorWidget()
              : ListView.builder(
                  itemCount: activeRequests.length,
                  itemBuilder: (context, index) {
                    final req = activeRequests[index];
                    return TrafficRequestCard(req: req);
                  },
                ),
        ),
      ],
    );
  }
}

class EmptyMonitorWidget extends StatelessWidget {
  const EmptyMonitorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_rounded, color: Color(0xFF1E2338), size: 36),
          SizedBox(height: 12),
          Text(
            'API Gateway Idle',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
          SizedBox(height: 2),
          Text(
            'No external connections active.',
            style: TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}

class TrafficRequestCard extends StatelessWidget {
  final ActiveRequestInfo req;

  const TrafficRequestCard({super.key, required this.req});

  @override
  Widget build(BuildContext context) {
    final timeStr = '${DateTime.now().difference(req.requestedAt).inSeconds}s ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111422),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2338)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lan_rounded,
              color: Color(0xFFEC4899),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Client IP: ${req.clientIp}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Model: ${req.model}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFEC4899),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
