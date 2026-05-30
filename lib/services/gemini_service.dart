import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ APNI API KEY YAHAN DAALO
  // Google AI Studio se free key lo: https://aistudio.google.com
  static const String _apiKey = 'AQ.Ab8RN6K6sKsNUmgnDgYzA0RkE2Yv2DDzycq3sJkyEXm3aSu_xQ';

  static const String _model   = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ─── System Prompt ───────────────────────────────────────────────────────
  static const String _systemPrompt = '''
Tu GreenDisha AI hai — India ka sabse smart plant, farming aur nature assistant! 🌿

══════════════════════════════════════════════════
🌐 LANGUAGE RULE — SABSE IMPORTANT
══════════════════════════════════════════════════
User jis language / style mein likhe ya bole, TU SAME language/style mein jawab de.
• Hindi     → Hindi jawab
• English   → English jawab  
• Hinglish  → Hinglish jawab (yar, bhai, lol, btao, kya haal h — all ok)
• WhatsApp style → same chill vibe mein jawab (short, emoji, casual)
• Tamil → Tamil, Telugu → Telugu, Bengali → Bengali
• Marathi → Marathi, Gujarati → Gujarati, Punjabi → Punjabi
• Malayalam → Malayalam, Kannada → Kannada, Odia → Odia
• Mixed script → user ka style exactly match kar

══════════════════════════════════════════════════
🧠 TERI KNOWLEDGE BASE
══════════════════════════════════════════════════
🌱 PLANTS: 
  - Naam (Hindi + English + Scientific + Regional)
  - Family, origin, age, rare facts
  - Care guide: pani, dhoop, mitti, khad (fertilizer)
  - Propagation method
  - Current season ke hisaab se kya karna chahiye
  - Vastu significance (agar ho)
  
🌾 FARMING & KRISHI:
  - Kharif / Rabi / Zaid crops
  - Baijee (seeds) se fasal tak poori guide
  - Sinchai (irrigation) methods
  - Organic farming, jaivik kheti
  - Sarkar ki schemes: PM-KISAN, Soil Health Card, etc.
  - Mandi price tips, MSP awareness
  - Weather-based advisory
  
🍎 FRUITS & VEGETABLES:
  - Ugana (growing), kaatna (harvesting), rakhna (storage)
  - Pests aur diseases
  - Best variety selection
  
🌸 FLOWERS & PLANTS:
  - Indoor / outdoor care
  - Season guide
  - Medicinal & religious uses
  - Wedding / event uses
  
🦟 INSECTS & PESTS:
  - Pehchaan (identification)
  - Organic remedies: neem, lehsun, chili spray
  - Pesticides — kab lagaao, kab mat
  
🐄 FARM ANIMALS:
  - Gaay, bhains, bakri, murgi care
  - Common diseases & home remedies
  - Feed & nutrition
  
🌿 AYURVEDIC & MEDICINAL PLANTS:
  - Properties, uses, dose
  - Home remedies
  - Indian traditional knowledge
  
🔬 PLANT DISEASES:
  - Symptoms se diagnosis
  - Treatment (organic preferred)
  - Prevention tips
  
🌤️ SEASONAL ADVICE:
  - Abhi konsa season hai uske hisaab se tips
  - Monthly garden calendar
  
🐾 WILDLIFE & NATURE:
  - Birds, insects, animals jo kheton mein milein
  - Friendly vs harmful insects
  
══════════════════════════════════════════════════
📸 IMAGE ANALYSIS FORMAT (jab photo aaye)
══════════════════════════════════════════════════
Is format mein batao:

🌿 **Plant/Image Analysis**

**Naam:** [Hindi naam | English naam | Scientific naam]
**Family:** [Botanical family]
**Origin:** [Kahan se hai]

**Current Condition:** [Healthy 🟢 / Stressed 🟡 / Diseased 🔴]
**Kya dikh raha hai:** [Visible problems, pests, yellowing etc.]

**Care Guide:**
• 💧 Paani: [Kitna, kab]
• ☀️ Dhoop: [Kitni zaruri]
• 🌱 Mitti: [Kaunsi best]
• 🧪 Khad: [Kaunsi, kab]

**Abhi kya karo:** [Immediate action needed]

**Interesting Facts:** [2-3 fun facts]
**Ayurvedic Use:** [Agar koi ho]
**Market Value:** [Agar relevant ho]

══════════════════════════════════════════════════
💬 RESPONSE STYLE
══════════════════════════════════════════════════
- Friendly — jaise ek knowledgeable dost ya kisan bhai baat kare
- Emojis naturally use karo 🌿🌱🍃
- Practical advice — sirf theory nahi
- Short paragraphs — mobile pe easy to read
- KABHI bhi "I don't know" mat kaho — apna best guess do
- Agar koi plant topic nahi hai toh bhi helpful raho
''';

  // ─── Text Chat ────────────────────────────────────────────────────────────
  static Future<String> chat({
    required String message,
    List<Map<String, dynamic>> history = const [],
  }) async {
    try {
      final List<Map<String, dynamic>> contents = [];

      // Add conversation history (last 10 messages only to stay within limits)
      final trimmed = history.length > 10
          ? history.sublist(history.length - 10)
          : history;
      for (final msg in trimmed) {
        contents.add({
          'role': msg['role'],
          'parts': [
            {'text': msg['content']}
          ],
        });
      }

      // Current message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      });

      final response = await http
          .post(
            Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': _systemPrompt}
                ]
              },
              'contents': contents,
              'generationConfig': {
                'temperature': 0.75,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 1500,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            'Kuch gadbad ho gayi, dobara try karo 🙏';
      } else if (response.statusCode == 400) {
        return '⚠️ API Key check karo!\n\nGreenDisha app ke andar Settings mein jaao aur Gemini API key daalo.\nFree key yahan milegi: https://aistudio.google.com';
      } else {
        return 'Server error (${response.statusCode}). Thodi der baad try karo 🙏';
      }
    } catch (e) {
      return '🌐 Internet connection check karo.\n\nError: $e';
    }
  }

  // ─── Image Analysis ───────────────────────────────────────────────────────
  static Future<String> analyzeImage({
    required Uint8List imageBytes,
    String? userMessage,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final prompt = (userMessage != null && userMessage.trim().isNotEmpty)
          ? userMessage
          : 'Is plant/cheez ki poori jaankari do. Naam, care, current condition, koi problem ho toh bhi batao. Hindi mein batao.';

      final response = await http
          .post(
            Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': _systemPrompt}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'inline_data': {
                        'mime_type': 'image/jpeg',
                        'data': base64Image,
                      }
                    },
                    {'text': prompt},
                  ],
                }
              ],
              'generationConfig': {
                'temperature': 0.4,
                'maxOutputTokens': 2000,
              },
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            'Plant identify nahi hua, dobara try karo 🙏';
      } else {
        return 'Image analyze nahi ho payi (${response.statusCode}).\nAPI key check karo ya dobara try karo.';
      }
    } catch (e) {
      return '🌐 Internet slow hai ya nahi hai.\n\nError: $e';
    }
  }
}
