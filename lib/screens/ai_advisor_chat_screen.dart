import 'package:flutter/material.dart';

import '../models/ai_advisor_payload.dart';
import '../services/ai_advisor_service_gemini.dart';
import '../widgets/reusable_components.dart';

/// Separate Chat Screen for AI Advisor
class AIAdvisorChatScreen extends StatefulWidget {
  final AIAdvisorPayload payload;

  const AIAdvisorChatScreen({Key? key, required this.payload})
    : super(key: key);

  @override
  State<AIAdvisorChatScreen> createState() => _AIAdvisorChatScreenState();
}

class _AIAdvisorChatScreenState extends State<AIAdvisorChatScreen> {
  final AIAdvisorServiceGemini _advisorService = AIAdvisorServiceGemini();
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with welcome message
    _chatMessages.add(
      ChatMessage(
        text: "Hi! I'm here to help you reduce your electricity bill. What would you like to know?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Send chat message
  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add(
        ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
      );
    });

    _chatController.clear();

    // Show loading
    setState(() {
      _chatMessages.add(
        ChatMessage(text: '...', isUser: false, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    try {
      final response = await _advisorService.askAdvisor(
        widget.payload,
        message,
      );

      setState(() {
        _chatMessages.removeLast(); // Remove "..."
        _chatMessages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error in chat: $e');
      setState(() {
        _chatMessages.removeLast(); // Remove "..."
        _chatMessages.add(
          ChatMessage(
            text: 'Sorry, I couldn\'t process that question. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: 'Ask Advisor', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[_chatMessages.length - 1 - index];
                return _buildChatBubble(message);
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  /// Build chat bubble
  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Color(0xFF005F54),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFF005F54)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message.text,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: message.isUser ? Colors.white : Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF005F54),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  /// Build chat input
  Widget _buildChatInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _chatController,
                maxLines: null,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () => _sendChatMessage(_chatController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[400] : const Color(0xFF005F54),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
