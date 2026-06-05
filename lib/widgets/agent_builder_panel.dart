import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/agent_provider.dart';
import '../services/agent_manager_service.dart';

class AgentBuilderPanel extends StatefulWidget {
  const AgentBuilderPanel({super.key});

  @override
  State<AgentBuilderPanel> createState() => _AgentBuilderPanelState();
}

class _AgentBuilderPanelState extends State<AgentBuilderPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _promptController = TextEditingController();
  
  String _selectedIcon = 'smart';
  CustomAgent? _editingAgent;

  final Map<String, IconData> _iconMap = {
    'smart': Icons.psychology_rounded,
    'code': Icons.code_rounded,
    'edit': Icons.edit_note_rounded,
    'science': Icons.science_rounded,
    'chat': Icons.chat_rounded,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descController.clear();
      _promptController.clear();
      _selectedIcon = 'smart';
      _editingAgent = null;
    });
  }

  void _loadEditingAgent(CustomAgent agent) {
    setState(() {
      _editingAgent = agent;
      _nameController.text = agent.name;
      _descController.text = agent.description;
      _promptController.text = agent.systemPrompt;
      _selectedIcon = agent.icon;
    });
  }

  void _saveAgent(AgentProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final agentName = _nameController.text.trim();
    final agentDesc = _descController.text.trim();
    final agentPrompt = _promptController.text.trim();

    if (_editingAgent != null) {
      final updated = CustomAgent(
        id: _editingAgent!.id,
        name: agentName,
        description: agentDesc,
        systemPrompt: agentPrompt,
        icon: _selectedIcon,
      );
      await provider.updateCustomAgent(updated);
      _showSnackbar('Agent profile updated successfully.', const Color(0xFF10B981));
    } else {
      final created = CustomAgent(
        id: const Uuid().v4(),
        name: agentName,
        description: agentDesc,
        systemPrompt: agentPrompt,
        icon: _selectedIcon,
      );
      await provider.createCustomAgent(created);
      _showSnackbar('New custom agent profile saved.', const Color(0xFF6366F1));
    }

    _clearForm();
  }

  void _showSnackbar(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        width: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentProvider>(context);
    final agents = provider.customAgents;
    final activeAgent = provider.activeAgent;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Custom Agents List (45%)
          Expanded(
            flex: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Agent Profiles',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (activeAgent != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFF3F4F6)),
                        onPressed: () => provider.setActiveAgent(null),
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Reset Default', style: TextStyle(fontSize: 12)),
                      )
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select an agent to activate it for your chat sessions.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: agents.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Render OSLAH default core option
                        final isDefaultActive = activeAgent == null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDefaultActive ? const Color(0xFF161B30) : const Color(0xFF111422),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDefaultActive ? const Color(0xFF6366F1) : const Color(0xFF1E2336),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E243B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF818CF8)),
                            ),
                            title: const Text(
                              'OSLAH Core (Default)',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            subtitle: const Text(
                              'System-level default local AI configurations profile.',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                            trailing: isDefaultActive 
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                                : null,
                            onTap: () => provider.setActiveAgent(null),
                          ),
                        );
                      }

                      final agent = agents[index - 1];
                      final isSelected = activeAgent?.id == agent.id;
                      final isEditingThis = _editingAgent?.id == agent.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF161B30) : const Color(0xFF111422),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEditingThis 
                                ? const Color(0xFFEC4899)
                                : isSelected 
                                    ? const Color(0xFF6366F1) 
                                    : const Color(0xFF1E2336),
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E243B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _iconMap[agent.icon] ?? Icons.psychology_rounded,
                              color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF9CA3AF),
                            ),
                          ),
                          title: Text(
                            agent.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          subtitle: Text(
                            agent.description,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                color: const Color(0xFF9CA3AF),
                                onPressed: () => _loadEditingAgent(agent),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                color: const Color(0xFFEF4444),
                                onPressed: () => provider.deleteCustomAgent(agent.id),
                              ),
                            ],
                          ),
                          onTap: () => provider.setActiveAgent(agent),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          // Divider line
          Container(
            width: 1,
            height: double.infinity,
            color: const Color(0xFF1F2438),
          ),
          const SizedBox(width: 48),
          // Right side: Creation / Editor Form (55%)
          Expanded(
            flex: 55,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingAgent != null ? 'Edit Agent Profile' : 'Configure Custom Agent',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _editingAgent != null 
                          ? 'Modify prompt properties and details of ${_editingAgent!.name}.' 
                          : 'Build specialized persona profiles with system directive prompts.',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    // Agent Name
                    const Text(
                      'AGENT IDENTITY NAME',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4B5563), letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF131722),
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'e.g. Smart Code Assistant',
                        hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22293F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22293F))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please supply an agent identity name' : null,
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'SHORT DESCRIPTION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4B5563), letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF131722),
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'e.g. Specialised helper for clean and optimized C++ code.',
                        hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22293F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22293F))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please supply a short description' : null,
                    ),
                    const SizedBox(height: 24),

                    // Icon Selector
                    const Text(
                      'AVATAR SYMBOL ICON',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4B5563), letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _iconMap.keys.map((iconName) {
                        final isIconSelected = _selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = iconName;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isIconSelected ? const Color(0xFF1E243B) : const Color(0xFF131722),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isIconSelected ? const Color(0xFF6366F1) : const Color(0xFF22293F),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _iconMap[iconName]!,
                              color: isIconSelected ? const Color(0xFF818CF8) : const Color(0xFF6B7280),
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // System Prompt
                    const Text(
                      'SYSTEM INSTRUCTIONS DIRECTIVE (SYSTEM PROMPT)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4B5563), letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _promptController,
                      maxLines: 8,
                      minLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF131722),
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'You are an AI assistant. Help the user solve code bugs...',
                        hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22293F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22293F))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please define a system instruction directive prompt' : null,
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        SizedBox(
                          height: 48,
                          width: 160,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _saveAgent(provider),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _editingAgent != null ? 'Update Agent' : 'Create Agent',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_editingAgent != null) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 48,
                            width: 100,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF9CA3AF),
                                side: const BorderSide(color: Color(0xFF2E3452)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _clearForm,
                              child: const Text('Cancel'),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
