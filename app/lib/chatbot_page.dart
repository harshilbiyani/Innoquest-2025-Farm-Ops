import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'services/theme_provider.dart';
import 'services/localization_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addBotMessage(
      "Hello! I'm AgroBot, your agricultural assistant. How can I help you with your farming needs today?",
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: false, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    _addUserMessage(message);
    _messageController.clear();

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    try {
      // Call chatbot API using centralized service
      final response = await _getChatbotResponse(message);

      // Remove typing indicator and add bot response
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _addBotMessage(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _addBotMessage(
          "Sorry, I'm having trouble connecting right now. Please try again later.",
        );
      }
      print('❌ Chatbot error: $e');
    }
  }

  Future<String> _getChatbotResponse(String message) async {
    print('🤖 Sending message to chatbot API');
    print('📤 Message: $message');

    try {
      // Use centralized API service with automatic backend detection
      final result = await ApiService.sendChatMessage(message);

      if (result['success'] == true) {
        final response = result['response'] as String?;
        print('✅ Chatbot response received: ${response?.substring(0, 50)}...');
        return response ?? 'Sorry, I could not understand that.';
      } else {
        final errorMessage = result['message'] as String? ?? 'Unknown error';
        print('❌ Chatbot API error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ API Error: $e');
      // Fallback response if API fails
      return _getFallbackResponse(message);
    }
  }

  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return "Hello! I'm here to help with your farming questions. What would you like to know?";
    } else if (lowerMessage.contains('disease') ||
        lowerMessage.contains('pest')) {
      return "I can help with crop diseases. Please tell me which crop you're growing and describe the symptoms you're seeing.";
    } else if (lowerMessage.contains('fertilizer')) {
      return "For fertilizer recommendations, I suggest first getting a soil test. Which crop are you planning to grow?";
    } else if (lowerMessage.contains('weather')) {
      return "Weather monitoring is crucial for farming. Check daily forecasts for planning your field operations.";
    } else {
      return "I can help with crop diseases, fertilizers, weather advice, and farming guidance. What specific challenge are you facing?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              color: const Color(0xFF008575),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Color(0xFF008575),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgroBot',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Agricultural Assistant',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 197, 191, 191),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about farming...',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color.fromARGB(255, 0, 131, 105),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isTyping ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? Colors.grey
                            : const Color(0xFF2BC24A),
                        shape: BoxShape.circle,
                      ),
                      child: _isTyping
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation bar
          _buildBottomNavBar(),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008575),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF2BC24A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: message.isUser ? Colors.white : const Color.fromARGB(221, 0, 0, 0),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2BC24A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF008575),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + index * 0.3) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF008575),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'chatbot');
  }
}

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
