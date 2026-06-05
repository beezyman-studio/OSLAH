import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../services/bootstrapper_service.dart';
import 'dashboard_screen.dart';

class SplashWelcomeScreen extends StatefulWidget {
  const SplashWelcomeScreen({super.key});

  @override
  State<SplashWelcomeScreen> createState() => _SplashWelcomeScreenState();
}

class _SplashWelcomeScreenState extends State<SplashWelcomeScreen> {
  int _currentStage = 1; // 1 = Model Selection, 2 = Download & Bootstrap Progress
  String? _selectedModel; // 'deepseek-r1:7b' or 'llama3'
  String? _hoveredModel; // 'deepseek-r1:7b' or 'llama3'
  
  final BootstrapperService _bootstrapper = BootstrapperService();
  StreamSubscription<BootstrapperProgress>? _bootstrapSub;
  BootstrapperProgress _progress = BootstrapperProgress.idle();

  @override
  void dispose() {
    _bootstrapSub?.cancel();
    super.dispose();
  }

  void _startOnboarding(AgentProvider provider) {
    if (_selectedModel == null) return;
    
    setState(() {
      _currentStage = 2;
    });

    _bootstrapSub = _bootstrapper.progressStream.listen((event) {
      setState(() {
        _progress = event;
      });

      if (event.status == BootstrapperStatus.completed) {
        // Refresh models registry in provider and disable first launch
        provider.setFirstLaunchFinished();
        
        // Navigate to Dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    });

    // Start background bootstrap
    _bootstrapper.bootstrap(_selectedModel!);
  }

  String _getStatusText(BootstrapperStatus status) {
    switch (status) {
      case BootstrapperStatus.checking:
        return 'Checking local dependency files... / സിസ്റ്റം ഫയലുകൾ പരിശോധിക്കുന്നു...';
      case BootstrapperStatus.downloadingInstaller:
        return 'Downloading local Ollama installer... / Ollama ഇൻസ്റ്റാളർ ഡൗൺലോഡ് ചെയ്യുന്നു...';
      case BootstrapperStatus.installing:
        return 'Running silent background installation... / ഒല്ലാമ പശ്ചാത്തലത്തിൽ ഇൻസ്റ്റാൾ ചെയ്യുന്നു...';
      case BootstrapperStatus.startingOllama:
        return 'Initializing local service host... / ലോക്കൽ എപിഐ സർവർ സജ്ജീകരിക്കുന്നു...';
      case BootstrapperStatus.pullingModel:
        return 'Downloading model weights registry... / മോഡൽ ഫയലുകൾ ഡൗൺലോഡ് ചെയ്യുന്നു...';
      case BootstrapperStatus.completed:
        return 'Setup completed successfully! Opening dashboard...';
      case BootstrapperStatus.failed:
        return 'Onboarding execution failure. Please retry setup.';
      default:
        return 'Setting up your local AI engine... / ഇൻ്റലിജൻസ് സജ്ജീകരിക്കുന്നു...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF070913), // Ultra dark Obsidian base
      body: Center(
        child: Container(
          width: 900,
          height: 620,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: const Color(0xFF0F111A).withValues(alpha: 0.75), // Glassmorphism container
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1E233B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 5,
              )
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStage == 1 
                ? _buildModelSelectionStage(provider)
                : _buildProgressStage(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelectionStage(AgentProvider provider) {
    final activeModelDetails = _hoveredModel ?? _selectedModel;
    
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
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
                child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OSLAH SETUP WIZARD',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                ),
                Text(
                  'Choose your default local intelligence engine to begin.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Side-by-side cards
        Expanded(
          child: Row(
            children: [
              // DeepSeek Card
              Expanded(
                child: _ModelCard(
                  modelTag: 'deepseek-r1:7b',
                  title: 'DeepSeek-R1 (7B)',
                  description: 'State-of-the-art reasoning model designed for logical math and step-by-step thinking.',
                  isSelected: _selectedModel == 'deepseek-r1:7b',
                  onTap: () {
                    setState(() {
                      _selectedModel = 'deepseek-r1:7b';
                    });
                  },
                  onHover: (hovering) {
                    setState(() {
                      _hoveredModel = hovering ? 'deepseek-r1:7b' : null;
                    });
                  },
                  color: const Color(0xFF6366F1),
                  icon: Icons.psychology_rounded,
                ),
              ),
              const SizedBox(width: 16),
              // Llama 3 Card
              Expanded(
                child: _ModelCard(
                  modelTag: 'llama3',
                  title: 'Llama 3 (8B)',
                  description: 'Meta\'s highly robust, general-purpose LLM, offering rapid and natural conversation streams.',
                  isSelected: _selectedModel == 'llama3',
                  onTap: () {
                    setState(() {
                      _selectedModel = 'llama3';
                    });
                  },
                  onHover: (hovering) {
                    setState(() {
                      _hoveredModel = hovering ? 'llama3' : null;
                    });
                  },
                  color: const Color(0xFFEC4899),
                  icon: Icons.blur_on_rounded,
                ),
              ),
              const SizedBox(width: 16),
              // Phi 3 Card
              Expanded(
                child: _ModelCard(
                  modelTag: 'phi3',
                  title: 'Phi-3 (3.8B)',
                  description: 'Microsoft\'s highly efficient lightweight model, optimized for fast and responsive local streams.',
                  isSelected: _selectedModel == 'phi3',
                  onTap: () {
                    setState(() {
                      _selectedModel = 'phi3';
                    });
                  },
                  onHover: (hovering) {
                    setState(() {
                      _hoveredModel = hovering ? 'phi3' : null;
                    });
                  },
                  color: const Color(0xFF10B981),
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pros / Cons Animated Display
        Container(
          height: 110,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111422),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E233B), width: 1),
          ),
          child: activeModelDetails == null
              ? const Center(
                  child: Text(
                    'Hover or select a card to review model details & language capabilities.',
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              : _buildProsCons(activeModelDetails),
        ),
        const SizedBox(height: 24),

        // Proceed Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 48,
              width: 220,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedModel != null ? const Color(0xFF6366F1) : const Color(0xFF1E2338),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF131622),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                ),
                onPressed: _selectedModel != null ? () => _startOnboarding(provider) : null,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Provision Engine', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProsCons(String modelTag) {
    if (modelTag == 'deepseek-r1:7b') {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROS (മേന്മകൾ)', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 6),
                _BulletText('മലയാളം സൂപ്പർ ആയി അറിയാം (Excellent Malayalam)'),
                _BulletText('Reasons step-by-step using <think> tags'),
              ],
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONS (കുറവുകൾ)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 6),
                _BulletText('Needs decent CPU/RAM allocation'),
                _BulletText('Generates slightly slower due to thinking'),
              ],
            ),
          ),
        ],
      );
    } else if (modelTag == 'phi3') {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROS (മേന്മകൾ)', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 6),
                _BulletText('Extremely fast & lightweight (വളരെ വേഗത്തിൽ പ്രവർത്തിക്കും)'),
                _BulletText('Requires very little RAM/CPU (കുറഞ്ഞ മെമ്മറി മതി)'),
              ],
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONS (കുറവുകൾ)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 6),
                _BulletText('Weak Malayalam translation (മലയാളം അത്ര പോരാ)'),
                _BulletText('Simple reasoning only (ലളിതമായ ചിന്തകൾ മാത്രം)'),
              ],
            ),
          ),
        ],
      );
    } else {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROS (മേന്മകൾ)', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 6),
                _BulletText('Fast in pure English conversations'),
                _BulletText('Great general knowledge & memory'),
              ],
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONS (കുറവുകൾ)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 6),
                _BulletText('മലയാളം അത്ര പോരാ (Weak Malayalam translation)'),
                _BulletText('No native step-by-step reasoning'),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildProgressStage(AgentProvider provider) {
    final status = _progress.status;
    final isFailed = status == BootstrapperStatus.failed;

    return Column(
      key: const ValueKey(2),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROVISIONING INTELLIGENCE',
          style: TextStyle(
            color: Color(0xFF818CF8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isFailed ? 'Setup Failed / പരാജയപ്പെട്ടു' : 'Installing Local AI Engine Setup...',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Progress Message Ticker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111422),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E233B), width: 1),
          ),
          child: Row(
            children: [
              if (!isFailed)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                )
              else
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isFailed ? _progress.errorMessage : _getStatusText(status),
                  style: TextStyle(
                    color: isFailed ? const Color(0xFFFCA5A5) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Progress bar
        if (!isFailed) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress.progress / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFF1E233B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_progress.progress.toStringAsFixed(1)}% Completed',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (_progress.speedMBs > 0)
                Text(
                  '${_progress.speedMBs.toStringAsFixed(1)} MB/s',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w800),
                ),
            ],
          ),
        ] else ...[
          // Retry button
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _clearForm();
                setState(() {
                  _currentStage = 1;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Setup Flow', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }

  void _clearForm() {
    setState(() {
      _selectedModel = null;
      _hoveredModel = null;
      _progress = BootstrapperProgress.idle();
    });
  }
}

class _ModelCard extends StatefulWidget {
  final String modelTag;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final Color color;
  final IconData icon;

  const _ModelCard({
    required this.modelTag,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
    required this.color,
    required this.icon,
  });

  @override
  State<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<_ModelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? widget.color.withValues(alpha: 0.1) 
                : _isHovered 
                    ? const Color(0xFF151829) 
                    : const Color(0xFF0F111A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected 
                  ? widget.color 
                  : _isHovered 
                      ? const Color(0xFF4B5563) 
                      : const Color(0xFF1E233B),
              width: widget.isSelected ? 2 : 1.5,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E243B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
