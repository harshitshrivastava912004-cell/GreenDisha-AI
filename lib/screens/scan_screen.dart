import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import 'chat_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String?   _result;
  bool      _loading   = false;
  bool      _speaking  = false;

  late AnimationController _scanCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    VoiceService.initTTS();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _glowCtrl.dispose();
    VoiceService.stopSpeaking();
    super.dispose();
  }

  // ── Pick image ─────────────────────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    try {
      final file = await _picker.pickImage(
        source: src, imageQuality: 85, maxWidth: 1024, maxHeight: 1024,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() { _imageBytes = bytes; _result = null; _loading = true; });
      final res = await GeminiService.analyzeImage(imageBytes: bytes);
      setState(() { _result = res; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo nahi mili: $e'),
            backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _toggleSpeak() async {
    if (_result == null) return;
    if (_speaking) {
      await VoiceService.stopSpeaking();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await VoiceService.speak(_result!);
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _reset() => setState(() { _imageBytes = null; _result = null; });

  void _askMoreInChat() {
    if (_result == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        initialMessage:
            'Maine ek plant ki photo scan ki. Uski analysis ye hai:\n\n$_result\n\nAb mujhe aur detail mein batao.',
      ),
    ));
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
          Icon(Icons.document_scanner_rounded, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text('Plant Scanner', style: TextStyle(
            color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _imageArea(),
          const SizedBox(height: 20),
          if (_imageBytes == null) ...[
            _pickBtn(Icons.camera_alt_rounded, 'Camera se Photo Lo', AppTheme.primary,  () => _pick(ImageSource.camera)),
            const SizedBox(height: 10),
            _pickBtn(Icons.photo_library_rounded, 'Gallery se Photo Lo', AppTheme.purple, () => _pick(ImageSource.gallery)),
            const SizedBox(height: 24),
            _tipCard(),
          ],
          if (_loading) _loadingCard(),
          if (_result != null && !_loading) ...[
            _actionRow(),
            const SizedBox(height: 16),
            _resultCard(),
          ],
        ]),
      ),
    );
  }

  // ── Image preview ───────────────────────────────────────────────────────
  Widget _imageArea() {
    return Container(
      width: double.infinity, height: 270,
      decoration: AppTheme.glassCard(borderColor: AppTheme.primary),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _imageBytes != null
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(_imageBytes!, fit: BoxFit.cover),
                if (_loading)
                  Container(color: Colors.black54,
                    child: AnimatedBuilder(
                      animation: _scanCtrl,
                      builder: (_, __) => Stack(children: [
                        Positioned(
                          top: 270 * _scanCtrl.value - 2,
                          left: 0, right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                AppTheme.primary.withOpacity(0.9),
                                Colors.transparent,
                              ]),
                              boxShadow: [BoxShadow(
                                color: AppTheme.primary.withOpacity(0.5),
                                blurRadius: 10,
                              )],
                            ),
                          ),
                        ),
                        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(height: 100),
                          const Text('🔍 AI Analyze kar raha hai...', style: TextStyle(
                            color: AppTheme.primary, fontWeight: FontWeight.bold,
                          )),
                        ])),
                      ]),
                    ),
                  ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined,
                  size: 64, color: AppTheme.primary.withOpacity(0.4)),
                const SizedBox(height: 14),
                const Text('Plant ki photo yahan dikhegi', style: TextStyle(
                  color: AppTheme.textSecond, fontSize: 15,
                )),
                const SizedBox(height: 6),
                const Text('Neeche se Camera ya Gallery chunein',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ]),
      ),
    );
  }

  Widget _pickBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 15,
          )),
        ]),
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.tips_and_updates_rounded, color: AppTheme.gold, size: 18),
          SizedBox(width: 8),
          Text('Sahi Photo ke Tips', style: TextStyle(
            color: AppTheme.gold, fontWeight: FontWeight.bold,
          )),
        ]),
        const SizedBox(height: 10),
        ...[
          '📸 Plant ke paas jaao — clear photo lo',
          '☀️ Achhi roshni mein lo — andhera nahi',
          '🍃 Patte ya phool clearly dikhne chahiye',
          '🌱 Ek plant ek baar — mix nahi',
        ].map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: const TextStyle(
            color: AppTheme.textSecond, fontSize: 12,
          )),
        )),
      ]),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _loadingCard() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.surface,
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2 + 0.2 * _glowCtrl.value),
          ),
        ),
        child: Column(children: [
          SizedBox(
            width: 44, height: 44,
            child: CircularProgressIndicator(
              color: AppTheme.primary.withOpacity(0.7 + 0.3 * _glowCtrl.value),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          const Text('AI brain kaam kar raha hai... 🌿',
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Plant ki poori jaankari dhundh raha hai',
            style: TextStyle(color: AppTheme.textSecond, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _actionRow() {
    return Row(children: [
      Expanded(child: _actionBtn(Icons.refresh_rounded, 'Naya Scan', AppTheme.primary, _reset)),
      const SizedBox(width: 10),
      Expanded(child: _actionBtn(
        _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
        _speaking ? 'Ruko' : 'Suno',
        AppTheme.purple,
        _toggleSpeak,
      )),
      const SizedBox(width: 10),
      Expanded(child: _actionBtn(Icons.chat_rounded, 'Aur Poocho', AppTheme.blue, _askMoreInChat)),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600,
          )),
        ]),
      ),
    );
  }

  Widget _resultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.neonBorder(),
      child: SelectableText(
        _result!,
        style: const TextStyle(
          color: AppTheme.textPrimary, fontSize: 14, height: 1.7,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }
}
