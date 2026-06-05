import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/agent_provider.dart';

class ChatInterface extends StatefulWidget {
  const ChatInterface({super.key});

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(AgentProvider provider) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    provider.sendMessage(text);
    _focusNode.requestFocus();
    
    // Scroll down shortly after message is added
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    // Call scroll to bottom if streaming changes
    if (provider.messages.isNotEmpty && provider.messages.last.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Row(
      children: [
        // Main Chat Feed (Left 70%)
        Expanded(
          flex: 7,
          child: Container(
            color: const Color(0xFF0F111A), // Dark feed background
            child: Column(
              children: [
                // Chat Window Header
                ChatHeader(onClear: provider.clearChat),
                
                // Message List
                Expanded(
                  child: provider.messages.isEmpty
                      ? const WelcomeView()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            return MessageBubble(message: provider.messages[index]);
                          },
                        ),
                ),

                // Chat Input Area
                ChatInputBar(
                  controller: _textController,
                  focusNode: _focusNode,
                  onSubmit: () => _sendMessage(provider),
                  isQueueActive: provider.isQueueProcessing,
                ),
              ],
            ),
          ),
        ),

        // Vertical divider
        Container(width: 1, color: const Color(0xFF1E2338)),

        // Knowledge Base Context Panel (Right 30%)
        Expanded(
          flex: 3,
          child: const KnowledgeBaseSidePanel(),
        ),
      ],
    );
  }
}

/// Header for the Chat interface
class ChatHeader extends StatelessWidget {
  final VoidCallback onClear;

  const ChatHeader({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0D16),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2338), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF131622),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2338), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('assets/images/logo.png', width: 20, height: 20, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.agentName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.selectedModel ?? 'No Active Model Selected',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF9CA3AF),
            shadowColor: Colors.transparent,
            side: const BorderSide(color: Color(0xFF1E2338)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ).buildButton(
            context: context,
            onPressed: onClear,
            child: const Row(
              children: [
                Icon(Icons.delete_sweep_rounded, size: 16),
                SizedBox(width: 8),
                Text('Clear Thread', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state suggestions dashboard
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Brand Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF131622),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2338), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to OSLAH Studio',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your local-first, privacy-respecting AI coordinate command center.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 40),
          const Text(
            'GETTING STARTED SUGGESTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4B5563),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              SuggestionCard(
                icon: Icons.code_rounded,
                title: 'Develop Local Automation Scripts',
                description: 'Write a python script that extracts tables from PDF documents and exports to CSV.',
              ),
              SuggestionCard(
                icon: Icons.article_rounded,
                title: 'Summarize Knowledge Assets',
                description: 'Drop text documents on the right panel and prompt the model to synthesize key details.',
              ),
              SuggestionCard(
                icon: Icons.security_rounded,
                title: 'Secure Context Checking',
                description: 'Check code syntax or private configuration strings completely offline and safely.',
              ),
              SuggestionCard(
                icon: Icons.speed_rounded,
                title: 'Benchmark LLM Inference speed',
                description: 'Evaluate tokens-per-second capabilities across models like DeepSeek or Llama.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SuggestionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111422),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2338)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF818CF8), size: 20),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders individual chat items
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const AvatarWidget(isModel: true),
          const SizedBox(width: 14),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1D2235) : const Color(0xFF121522),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xFF2C324E) : const Color(0xFF1C2138),
                ),
              ),
              child: isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    )
                  : AssistantMessageContent(text: message.text),
            ),
          ),
          const SizedBox(width: 14),
          if (isUser) const AvatarWidget(isModel: false),
        ],
      ),
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final bool isModel;

  const AvatarWidget({super.key, required this.isModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isModel
              ? [const Color(0xFF6366F1), const Color(0xFF818CF8)]
              : [const Color(0xFFEC4899), const Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isModel ? Icons.auto_awesome_rounded : Icons.person_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

/// Helper that parses DeepSeek reasoning blocks (`<think>` tags) and outputs styled widgets
class AssistantMessageContent extends StatefulWidget {
  final String text;

  const AssistantMessageContent({super.key, required this.text});

  @override
  State<AssistantMessageContent> createState() => _AssistantMessageContentState();
}

class _AssistantMessageContentState extends State<AssistantMessageContent> {
  bool _isThinkingExpanded = true;

  @override
  Widget build(BuildContext context) {
    final text = widget.text;

    // Segment thinking tag outputs
    String thinkingText = '';
    String responseText = '';

    if (text.contains('<think>') && text.contains('</think>')) {
      final parts = text.split('</think>');
      thinkingText = parts[0].replaceAll('<think>', '').trim();
      responseText = parts.sublist(1).join('</think>').trim();
    } else if (text.contains('<think>')) {
      thinkingText = text.replaceAll('<think>', '').trim();
    } else {
      responseText = text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reasoning Block
        if (thinkingText.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2135)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isThinkingExpanded = !_isThinkingExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFBBF24), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Reasoning Process',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _isThinkingExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF4B5563),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isThinkingExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                    child: Text(
                      thinkingText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],

        // Main Response (Markdown renderer)
        if (responseText.isNotEmpty)
          MarkdownBody(
            data: responseText,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14, height: 1.5),
              code: const TextStyle(
                backgroundColor: Color(0xFF1A1D2B),
                color: Color(0xFFE5E7EB),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF0B0D16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E2338)),
              ),
            ),
          )
        else if (thinkingText.isNotEmpty)
          const Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
              ),
              SizedBox(width: 8),
              Text(
                'Thinking...',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
              ),
            ],
          )
      ],
    );
  }
}

/// User Input bar with Enter to Submit handler
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool isQueueActive;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.isQueueActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0D16),
        border: Border(top: BorderSide(color: Color(0xFF1E2338), width: 1)),
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            onSubmit();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask OSLAH local intelligence... (Enter to send, Shift+Enter for new line)',
                  hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F121F),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2338)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2338)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 52,
              width: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: onSubmit,
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar for Knowledge Base Drop and Selection list
class KnowledgeBaseSidePanel extends StatelessWidget {
  const KnowledgeBaseSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);

    return Container(
      color: const Color(0xFF0B0D16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Knowledge Base',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inject custom texts and document structures to prompt payloads offline.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
          const SizedBox(height: 24),

          // File Picker Dropzone Trigger
          InkWell(
            onTap: provider.pickKnowledgeFiles,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0F121F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2338), style: BorderStyle.solid),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        color: Color(0xFF818CF8),
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Attach / Drop Context Files',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supports PDF, TXT, MD, Code',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Document list Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'INDEXED DOCUMENTS (${provider.documents.length})',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B5563),
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider.documents.isNotEmpty)
                TextButton(
                  onPressed: provider.clearDocuments,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 10, color: Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Active documents list scrollable container
          Expanded(
            child: provider.documents.isEmpty
                ? const EmptyDocumentsWidget()
                : ListView.builder(
                    itemCount: provider.documents.length,
                    itemBuilder: (context, index) {
                      final doc = provider.documents[index];
                      return DocumentItemCard(
                        doc: doc,
                        onDelete: () => provider.removeDocument(doc.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class EmptyDocumentsWidget extends StatelessWidget {
  const EmptyDocumentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, color: Color(0xFF1E2338), size: 36),
            SizedBox(height: 12),
            Text(
              'No documents indexed.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Context injection is currently disabled.',
              style: TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentItemCard extends StatelessWidget {
  final KnowledgeDocument doc;
  final VoidCallback onDelete;

  const DocumentItemCard({
    super.key,
    required this.doc,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sizeKb = doc.sizeBytes / 1024;
    final sizeStr = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '${sizeKb.toStringAsFixed(1)} KB';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111422),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2338)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sizeStr,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFEF4444),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

extension on ButtonStyle {
  Widget buildButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return TextButton(
      style: this,
      onPressed: onPressed,
      child: child,
    );
  }
}
