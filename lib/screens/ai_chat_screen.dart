import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';
import 'premium_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  final List<String> _suggestionChips = [
    'Tugas apa hari ini?',
    'Tugas mana yang paling mendesak?',
    'Bantu cicil tugas dengan skor prioritas tertinggi',
    'Tips manajemen waktu kuliah minggu ini',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Halo! Saya TugasKu AI 🎓. Saya siap membantumu mengatur prioritas tugas, memberi saran cicilan tugas, dan menyusun strategi belajar berdasarkan deadline aslimu!',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String query) async {
    final text = query.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
    });

    _scrollToBottom();

    final provider = context.read<TaskProvider>();
    final result = await provider.aiService.askAssistant(
      userQuestion: text,
      activeTasks: provider.activeTasks,
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    if (result.isQuotaExceeded) {
      _showPaywallPrompt(result.errorMessage ?? 'Kuota AI telah habis.');
      return;
    }

    if (result.success && result.data != null) {
      setState(() {
        _messages.add(ChatMessage(text: result.data!, isUser: false));
      });
      _scrollToBottom();
    } else {
      setState(() {
        _messages.add(
          ChatMessage(
            text: result.errorMessage ?? 'Maaf, terjadi kendala saat memproses jawabanmu. Silakan coba lagi.',
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPaywallPrompt(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.borderSubtleColor),
        ),
        title: const Text('👑 Kuota AI Habis', style: TextStyle(color: AppConstants.textPrimaryColor)),
        content: Text(
          '$message\n\nUpgrade ke TugasKu Premium hanya Rp10.000/bulan untuk akses Asisten AI tanpa batas!',
          style: const TextStyle(color: AppConstants.textSecondaryColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nanti Saja', style: TextStyle(color: AppConstants.textSecondaryColor))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
            },
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final profile = provider.profile;
    final isPremium = profile?.isPremium ?? false;
    final remainingQuota = profile?.remainingAiQuota ?? AppConstants.freeAiMonthlyQuota;

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Asisten TugasKu AI ✨'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPremium ? const Color(0xFF382E1E) : AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPremium ? AppConstants.warningColor : AppConstants.primaryColor,
              ),
            ),
            child: Text(
              isPremium ? '👑 AI Unlimited' : 'Sisa Kuota: $remainingQuota/${AppConstants.freeAiMonthlyQuota}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPremium ? AppConstants.warningColor : AppConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppConstants.primaryColor : AppConstants.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                      ),
                      border: msg.isUser ? null : Border.all(color: AppConstants.borderSubtleColor),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: msg.isUser ? Colors.white : AppConstants.textPrimaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isSending) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: AppConstants.primaryColor, strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('TugasKu AI sedang berpikir...', style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor)),
                ],
              ),
            ),
          ],

          // Quick Suggestion Chips
          Container(
            color: AppConstants.scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestionChips.map((chipText) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(chipText, style: const TextStyle(fontSize: 12, color: AppConstants.textPrimaryColor)),
                      backgroundColor: AppConstants.cardColor,
                      side: const BorderSide(color: AppConstants.borderSubtleColor),
                      onPressed: () => _sendMessage(chipText),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Input field
          Container(
            color: AppConstants.surfaceColor,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: AppConstants.textPrimaryColor),
                    decoration: const InputDecoration(
                      hintText: 'Tanya tugas atau minta saran prioritas...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
