import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupportChatbot extends StatefulWidget {
  const SupportChatbot({super.key});

  @override
  State<SupportChatbot> createState() => _SupportChatbotState();
}

class _SupportChatbotState extends State<SupportChatbot> {
  // Design tokens
  static const Color _bg = Color(0xFF161616);
  static const Color _surface = Color(0xFF1B1C1C);
  static const Color _borderColor = Color(0xFF262626);
  static const Color _primaryGreen = Color(0xFF4BE277);
  static const Color _userBubble = Color(0xFF22C55E);
  static const Color _primaryText = Color(0xFFE5E5E5);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late GenerativeModel _model;
  late ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    // Add default greeting
    _messages.add({
      'role': 'model',
      'text': 'Hi! I am the FairForge built-in support AI. I can help you understand ML Bias analysis, mitigating proxy features, or how to navigate the FairForge UI. How can I assist you?',
    });

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _messages.add({
        'role': 'model',
        'text': '⚠️ Cannot start. GEMINI_API_KEY is missing from the frontend .env file.',
      });
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('You are the helpful technical support chatbot for "FairForge". FairForge is a Flutter+FastAPI Hackathon project built to evaluate Machine Learning algorithms for bias. Features include checking Demographic Parity, Equalized Odds, mitigating proxies, and viewing Audit History. Provide concise, friendly answers regarding these topics or ML Fairness in general.'),
    );

    _chatSession = _model.startChat();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
      _controller.clear();
    });
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      setState(() {
        _messages.add({
          'role': 'model',
          'text': response.text ?? "Sorry, I couldn't process that.",
        });
      });
    } catch (e) {
      // Fallback mechanism: if the specific region/key does not support the primary model on v1beta API.
      if (e.toString().contains('v1beta') || e.toString().contains('not found')) {
        try {
          final apiKey = dotenv.env['GEMINI_API_KEY']!;
          // Re-initialize with the secondary model discovered for this key
          final fallbackModel = GenerativeModel(
            model: 'gemini-3.1-flash-live-preview',
            apiKey: apiKey,
          );
          _chatSession = fallbackModel.startChat();
          // Pre-seed context since systemInstruction is removed
          await _chatSession.sendMessage(Content.text('System Context: You are the helpful technical support chatbot for "FairForge". FairForge evaluates ML algorithms for bias (Demographic Parity, Equalized Odds). Acknowledge concisely.'));
          
          // Retry actual message
          final response = await _chatSession.sendMessage(Content.text(text));
          setState(() {
            _messages.add({
              'role': 'model',
              'text': response.text ?? "Sorry, I couldn't process that.",
            });
          });
        } catch (fallbackError) {
          setState(() {
            _messages.add({
              'role': 'model',
              'text': "Oops! Fallback failed: $fallbackError",
            });
          });
        }
      } else {
        setState(() {
          _messages.add({
            'role': 'model',
            'text': "Oops! An error occurred: $e",
          });
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 20,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: _borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent, color: _primaryGreen),
                      const SizedBox(width: 12),
                      Text(
                        'FairForge Support',
                        style: GoogleFonts.dmSans(
                          color: _primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? _userBubble.withValues(alpha: 0.1) : _surface,
                        border: Border.all(
                          color: isUser ? _userBubble.withValues(alpha: 0.3) : _borderColor,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isUser ? 12 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 12),
                        ),
                      ),
                      child: Text(
                        msg['text']!,
                        style: GoogleFonts.dmSans(
                          color: isUser ? _userBubble : _primaryText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.dmSans(color: _primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        hintStyle: GoogleFonts.dmSans(color: Colors.grey, fontSize: 14),
                        filled: true,
                        fillColor: _surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _primaryGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 18, 
                            height: 18, 
                            child: CircularProgressIndicator(color: _bg, strokeWidth: 2)
                          )
                        : const Icon(Icons.send, color: _bg, size: 18),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
