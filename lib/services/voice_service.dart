import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static final stt.SpeechToText _stt = stt.SpeechToText();
  static bool _sttReady = false;
  static bool isSpeaking = false;
  static bool isListening = false;

  // ─── TTS Init ─────────────────────────────────────────────────────────────
  static Future<void> initTTS() async {
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setLanguage('hi-IN');

    _tts.setCompletionHandler(() {
      isSpeaking = false;
    });
  }

  // Auto detect script → choose TTS language
  static String detectLangCode(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return 'hi-IN'; // Devanagari
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return 'ta-IN'; // Tamil
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(text)) return 'te-IN'; // Telugu
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) return 'bn-IN'; // Bengali
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)) return 'kn-IN'; // Kannada
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) return 'ml-IN'; // Malayalam
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) return 'gu-IN'; // Gujarati
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(text)) return 'pa-IN'; // Punjabi
    if (RegExp(r'[\u0B00-\u0B7F]').hasMatch(text)) return 'or-IN'; // Odia
    return 'hi-IN'; // Default Hindi
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    final lang = detectLangCode(text);
    await _tts.setLanguage(lang);
    isSpeaking = true;
    await _tts.speak(text);
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
    isSpeaking = false;
  }

  // ─── STT Init ─────────────────────────────────────────────────────────────
  static Future<bool> initSTT() async {
    if (!_sttReady) {
      _sttReady = await _stt.initialize(
        onError: (e) => isListening = false,
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            isListening = false;
          }
        },
      );
    }
    return _sttReady;
  }

  static Future<bool> startListening({
    required Function(String text) onResult,
    String localeId = 'hi-IN',
  }) async {
    if (!_sttReady) {
      final ok = await initSTT();
      if (!ok) return false;
    }
    if (_stt.isListening) await _stt.stop();

    isListening = true;
    await _stt.listen(
      localeId: localeId,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          isListening = false;
          onResult(result.recognizedWords);
        }
      },
    );
    return true;
  }

  static Future<void> stopListening() async {
    await _stt.stop();
    isListening = false;
  }

  static Future<List<stt.LocaleName>> availableLocales() async {
    if (!_sttReady) await initSTT();
    return await _stt.locales();
  }
}
