import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';

class AccessLogsPanel extends StatelessWidget {
  const AccessLogsPanel({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024.0).toStringAsFixed(1)} KB';
    return '${(bytes / (1024.0 * 1024.0)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);
    final logs = provider.accessLogs;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Access Logs',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Audit trail tracking incoming API chat requests and client credentials verification.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
              if (logs.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFF4C1523)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => provider.clearAllAccessLogs(),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Clear Log Vault', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Datatable Content
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111422),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E233B), width: 1.5),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 48, color: Color(0xFF4B5563)),
                          SizedBox(height: 16),
                          Text(
                            'No Security Access Transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'API endpoint calls from network clients will be audited here.',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111422),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E233B), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFF131622)),
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(
                              label: Text('TIMESTAMP', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11)),
                            ),
                            DataColumn(
                              label: Text('CLIENT IP', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11)),
                            ),
                            DataColumn(
                              label: Text('ENDPOINT', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11)),
                            ),
                            DataColumn(
                              label: Text('BYTES', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11)),
                            ),
                            DataColumn(
                              label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11)),
                            ),
                            DataColumn(
                              label: Text('AUTHENTICATION', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11)),
                            ),
                          ],
                          rows: logs.map((log) {
                            final statusCode = log['status_code'] as int? ?? 200;
                            final isSuccess = statusCode >= 200 && statusCode < 300;
                            final isAuthenticated = (log['authenticated'] as int? ?? 0) == 1;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    _formatDateTime(log['timestamp'] as String? ?? ''),
                                    style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    log['client_ip'] as String? ?? '127.0.0.1',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    log['endpoint'] as String? ?? '/api/chat',
                                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatBytes(log['bytes_processed'] as int? ?? 0),
                                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSuccess ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusCode.toString(),
                                      style: TextStyle(
                                        color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isAuthenticated ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isAuthenticated ? 'PASSED' : 'REJECTED',
                                      style: TextStyle(
                                        color: isAuthenticated ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
