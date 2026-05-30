import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  final bool startWithVoice;
  final String? initialMessage;
  const ChatScreen({super.key, this.startWithVoice = false, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll   = ScrollController();
  final List<ChatMessage> _msgs    = [];
  final List<Map<String, dynamic>> _history = [];

  bool _loading   = false;
  bool _listening = false;
  bool _speaking  = false;

  late AnimationController _micCtrl;
  late AnimationController _dotCtrl;

  // Indian language locales for STT
  final List<Map<String, String>> _locales = [
    {'code': 'hi-IN', 'label': '🇮🇳 Hindi'},
    {'code': 'en-IN', 'label': '🇮🇳 English'},
    {'code': 'ta-IN', 'label': 'Tamil'},
    {'code': 'te-IN', 'label': 'Telugu'},
    {'code': 'bn-IN', 'label': 'Bengali'},
    {'code': 'mr-IN', 'label': 'Marathi'},
    {'code': 'gu-IN', 'label': 'Gujarati'},
    {'code': 'pa-IN', 'label': 'Punjabi'},
    {'code': 'ml-IN', 'label': 'Malayalam'},
    {'code': 'kn-IN', 'label': 'Kannada'},
  ];
  String _selectedLocale = 'hi-IN';

  @override
  void initState() {
    super.initState();
    _micCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    VoiceService.initTTS();

    // Add welcome message
    _msgs.add(ChatMessage(
      text: '🌿 Namaste! Main GreenDisha AI hoon.\n\nKisi bhi plant, kheti, phool, phal, jadi-buti ke baare mein poocho — Hindi, English, ya apni koi bhi bhasha mein!\n\nCamera icon se plant scan bhi kar sakte ho 📸',
      isUser: false,
    ));

    // Handle initial message or voice start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialMessage != null) {
        _sendMessage(widget.initialMessage!);
      } else if (widget.startWithVoice) {
        Future.delayed(const Duration(milliseconds: 600), _startVoice);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _micCtrl.dispose();
    _dotCtrl.dispose();
    VoiceService.stopSpeaking();
    VoiceService.stopListening();
    super.dispose();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = text.trim();
    _ctrl.clear();

    setState(() {
      _msgs.add(ChatMessage(text: msg, isUser: true));
      _loading = true;
    });
    _scrollDown();

    _history.add({'role': 'user', 'content': msg});

    final reply = await GeminiService.chat(message: msg, history: _history);

    _history.add({'role': 'model', 'content': reply});
    if (_history.length > 20) _history.removeRange(0, 2);

    if (mounted) {
      setState(() {
        _msgs.add(ChatMessage(text: reply, isUser: false));
        _loading = false;
      });
      _scrollDown();
    }
  }

  Future<void> _startVoice() async {
    if (_listening) {
      await VoiceService.stopListening();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final ok = await VoiceService.startListening(
      localeId: _selectedLocale,
      onResult: (text) {
        if (mounted) {
          setState(() => _listening = false);
          _sendMessage(text);
        }
      },
    );
    if (!ok && mounted) {
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Microphone permission do Settings mein'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<void> _speakLast() async {
    final lastAI = _msgs.lastWhere((m) => !m.isUser, orElse: () => ChatMessage(text: '', isUser: false));
    if (lastAI.text.isEmpty) return;
    if (_speaking) {
      await VoiceService.stopSpeaking();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await VoiceService.speak(lastAI.text);
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _changeLocale() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        Container(width: 40, height: 4, decoration: BoxDecoration(
          color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Voice Language Chuniye', style: TextStyle(
          color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 12),
        ..._locales.map((l) => ListTile(
          leading: Text(l['label']!, style: const TextStyle(fontSize: 16)),
          trailing: _selectedLocale == l['code']
              ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
              : null,
          onTap: () {
            setState(() => _selectedLocale = l['code']!);
            Navigator.pop(context);
          },
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(children: [
          Icon(Icons.smart_toy_rounded, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text('GreenDisha AI', style: TextStyle(
            color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold,
          )),
        ]),
        actions: [
          // Speak last response
          IconButton(
            icon: Icon(
              _speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
              color: AppTheme.purple,
            ),
            onPressed: _speakLast,
            tooltip: 'Jawab suno',
          ),
          // Language picker
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: AppTheme.textSecond),
            onPressed: _changeLocale,
            tooltip: 'Language',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _msgs.length) return _typingIndicator();
              return _bubble(_msgs[i], i);
            },
          ),
        ),
        _inputBar(),
      ]),
    );
  }

  Widget _bubble(ChatMessage msg, int index) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left:  isUser ? 60 : 0,
        right: isUser ? 0  : 60,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(18),
              topRight:    const Radius.circular(18),
              bottomLeft:  Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4  : 18),
            ),
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : AppTheme.surface,
            border: Border.all(
              color: isUser
                  ? AppTheme.primary.withOpacity(0.3)
                  : AppTheme.border.withOpacity(0.4),
            ),
            boxShadow: [BoxShadow(
              color: (isUser ? AppTheme.primary : Colors.black).withOpacity(0.08),
              blurRadius: 8,
            )],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.primary,
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.black, size: 10),
                  ),
                  const SizedBox(width: 5),
                  const Text('GreenDisha', style: TextStyle(
                    color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold,
                  )),
                ]),
              ),
            SelectableText(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : AppTheme.textPrimary,
                fontSize: 14, height: 1.65,
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 60),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _dotCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(
                    0.3 + 0.7 * (((_dotCtrl.value * 3 - i) % 1 + 1) % 1),
                  ),
                ),
              );
            })),
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        // Voice button
        AnimatedBuilder(
          animation: _micCtrl,
          builder: (_, __) => GestureDetector(
            onTap: _startVoice,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening
                    ? AppTheme.primary.withOpacity(0.15 + 0.1 * _micCtrl.value)
                    : AppTheme.card,
                border: Border.all(
                  color: _listening
                      ? AppTheme.primary.withOpacity(0.7 + 0.3 * _micCtrl.value)
                      : AppTheme.border,
                  width: _listening ? 2 : 1,
                ),
                boxShadow: _listening
                    ? [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3 * _micCtrl.value),
                        blurRadius: 14,
                      )]
                    : [],
              ),
              child: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _listening ? AppTheme.primary : AppTheme.textSecond,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Text input
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            maxLines: 4, minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: _sendMessage,
            decoration: InputDecoration(
              hintText: _listening
                  ? '🎤 Bol raha hoon...'
                  : 'Kuch bhi poocho — Hindi, English, Hinglish...',
              hintStyle: TextStyle(
                color: _listening ? AppTheme.primary : AppTheme.textHint,
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.card,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Send button
        GestureDetector(
          onTap: () => _sendMessage(_ctrl.text),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 10,
              )],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
          ),
        ),
      ]),
    );
  }
}
