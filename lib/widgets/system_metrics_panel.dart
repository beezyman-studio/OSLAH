import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';

class SystemMetricsPanel extends StatefulWidget {
  const SystemMetricsPanel({super.key});

  @override
  State<SystemMetricsPanel> createState() => _SystemMetricsPanelState();
}

class _SystemMetricsPanelState extends State<SystemMetricsPanel> {
  final _modelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  void _triggerDownload(AgentProvider provider) {
    if (!_formKey.currentState!.validate()) return;
    final modelName = _modelController.text.trim();
    provider.startModelDownload(modelName);
    _modelController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);
    final isDownloading = provider.isModelDownloading;
    final downloadEvent = provider.activeDownloadEvent;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Performance & Downloads',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Monitor live host resource allocations and retrieve local LLM weights from Ollama registry.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 32),

            // Hardware Cards Layout
            Row(
              children: [
                Expanded(
                  child: _HardwareCard(
                    title: 'CPU Utilization',
                    value: provider.cpuUsage,
                    color: const Color(0xFF6366F1), // Indigo
                    icon: Icons.bolt_rounded,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _HardwareCard(
                    title: 'RAM Allocation',
                    value: provider.ramUsage,
                    color: const Color(0xFF10B981), // Emerald
                    icon: Icons.memory_rounded,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _HardwareCard(
                    title: 'GPU Core Power',
                    value: provider.gpuUsage,
                    color: const Color(0xFFEC4899), // Pink
                    icon: Icons.developer_board_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Model Registry Downloader Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF111422),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E233B), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_download_rounded, color: Color(0xFF818CF8), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Ollama Model Registry Downloader',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Directly pull models from Ollama library. Make sure local instance is running.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 28),

                  if (!isDownloading) ...[
                    // Input Form
                    Form(
                      key: _formKey,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF131722),
                                hintText: 'e.g. phi3, deepseek-r1:1.5b, llama3',
                                hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please type a valid model tag' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 52,
                            width: 180,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: () => _triggerDownload(provider),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.downloading_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Pull Weights', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Active Download State UI
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131622),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E2338), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    downloadEvent.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    downloadEvent.modelName.isNotEmpty 
                                        ? 'Ollama Pull: ${downloadEvent.modelName}'
                                        : 'Connecting to registry...',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
                                  ),
                                ],
                              ),
                              if (downloadEvent.status.startsWith('downloading'))
                                Text(
                                  '${downloadEvent.speedMBs.toStringAsFixed(1)} MB/s',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: downloadEvent.progress / 100,
                              minHeight: 8,
                              backgroundColor: const Color(0xFF1E233B),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${downloadEvent.progress.toStringAsFixed(1)}% Completed',
                                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                                onPressed: () => provider.cancelModelDownload(),
                                icon: const Icon(Icons.cancel_rounded, size: 16),
                                label: const Text('Cancel Download', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Download Messages Status Hook
                  if (downloadEvent.status == 'success') ...[
                    const SizedBox(height: 16),
                    _MessageAlert(
                      text: 'Model pulled and registered successfully! Ready for inference selection.',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_outline_rounded,
                    )
                  ] else if (downloadEvent.status == 'error') ...[
                    const SizedBox(height: 16),
                    _MessageAlert(
                      text: 'Download Failed: ${downloadEvent.error}',
                      color: const Color(0xFFEF4444),
                      icon: Icons.error_outline_rounded,
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardwareCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _HardwareCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E233B), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF6B7280), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${value.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF1E233B),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Custom Drawn Circular Progress indicator
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                percentage: value,
                color: color,
                backgroundColor: const Color(0xFF1E233B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = (percentage / 100.0) * 2 * 3.1415926535;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MessageAlert extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _MessageAlert({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
