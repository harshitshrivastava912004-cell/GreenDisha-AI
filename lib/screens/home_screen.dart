import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'scan_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goScan() => Navigator.push(context, _route(const ScanScreen()));
  void _goChat({bool voice = false, String? msg}) =>
      Navigator.push(context, _route(ChatScreen(startWithVoice: voice, initialMessage: msg)));

  PageRoute _route(Widget screen) =>
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Animated background
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            painter: _BgPainter(_bgCtrl.value),
            size: MediaQuery.of(context).size,
          ),
        ),

        // Main content
        SafeArea(
          child: Column(children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 12),
                  _scanHero(),
                  const SizedBox(height: 20),
                  _quickRow(),
                  const SizedBox(height: 20),
                  _categoryGrid(),
                  const SizedBox(height: 16),
                  _bottomBadge(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        // Logo circle
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E676), Color(0xFF1B5E20)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(
                color: AppTheme.primary.withOpacity(0.3 + 0.2 * _pulseCtrl.value),
                blurRadius: 16 + 8 * _pulseCtrl.value,
                spreadRadius: 2,
              )],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
          ),
        ).animate().fadeIn(duration: 600.ms).scale(),
        const SizedBox(width: 12),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GreenDisha AI',
              style: TextStyle(
                color: AppTheme.primary, fontSize: 22,
                fontWeight: FontWeight.bold, letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
            const Text('🌿 Plant Intelligence for India',
              style: TextStyle(color: AppTheme.textSecond, fontSize: 11, letterSpacing: 0.8),
            ).animate().fadeIn(delay: 300.ms),
          ]),
        ),

        // Live badge
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.primary.withOpacity(0.08),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.2 + 0.3 * _pulseCtrl.value),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.6 + 0.4 * _pulseCtrl.value),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary,
                    blurRadius: 6 * _pulseCtrl.value,
                  )],
                ),
              ),
              const SizedBox(width: 5),
              const Text('AI ON', style: TextStyle(
                color: AppTheme.primary, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1,
              )),
            ]),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ]),
    );
  }

  // ── Scan Hero Button ────────────────────────────────────────────────────
  Widget _scanHero() {
    return GestureDetector(
      onTap: _goScan,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: double.infinity, height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1F0A), Color(0xFF163816)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.25 + 0.2 * _pulseCtrl.value),
              width: 1.5,
            ),
            boxShadow: [BoxShadow(
              color: AppTheme.primary.withOpacity(0.08 + 0.07 * _pulseCtrl.value),
              blurRadius: 24, spreadRadius: 2,
            )],
          ),
          child: Stack(alignment: Alignment.center, children: [
            // Ripple rings
            ...List.generate(3, (i) {
              final scale = 0.35 + i * 0.22 + 0.06 * _pulseCtrl.value;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.12 - i * 0.03),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),

            // Icon + text
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.12),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.7), width: 2,
                  ),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25 + 0.15 * _pulseCtrl.value),
                    blurRadius: 20,
                  )],
                ),
                child: const Icon(Icons.camera_alt_rounded,
                  color: AppTheme.primary, size: 36),
              ),
              const SizedBox(height: 18),
              const Text('PLANT SCAN KARO', style: TextStyle(
                color: AppTheme.primary, fontSize: 18,
                fontWeight: FontWeight.bold, letterSpacing: 2.5,
              )),
              const SizedBox(height: 4),
              Text('Camera ya Gallery — koi bhi plant', style: TextStyle(
                color: AppTheme.textSecond.withOpacity(0.8), fontSize: 12,
              )),
            ]),

            // Corner tag
            Positioned(top: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.gold.withOpacity(0.15),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                ),
                child: const Text('AI Powered', style: TextStyle(
                  color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold,
                )),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15);
  }

  // ── Quick Action Row ────────────────────────────────────────────────────
  Widget _quickRow() {
    return Row(children: [
      Expanded(child: _actionCard(
        icon: Icons.chat_bubble_rounded,
        title: 'Text Chat',
        subtitle: 'Likho aur jaano',
        color: AppTheme.blue,
        onTap: () => _goChat(),
      )),
      const SizedBox(width: 12),
      Expanded(child: _actionCard(
        icon: Icons.mic_rounded,
        title: 'Voice Chat',
        subtitle: 'Bolkar poocho',
        color: AppTheme.purple,
        onTap: () => _goChat(voice: true),
      )),
    ]).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15);
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(
            color: color, fontSize: 15, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(
            color: AppTheme.textSecond, fontSize: 11,
          )),
        ]),
      ),
    );
  }

  // ── Category Grid ───────────────────────────────────────────────────────
  Widget _categoryGrid() {
    final cats = [
      {'icon': Icons.local_florist_rounded, 'label': 'Phool 🌸',    'msg': 'Phoolon ke baare mein poori jaankari do', 'color': 0xFFEC407A},
      {'icon': Icons.agriculture_rounded,   'label': 'Kheti 🌾',    'msg': 'Kheti aur farming ke tips do',            'color': 0xFF66BB6A},
      {'icon': Icons.eco_rounded,           'label': 'Plants 🌿',   'msg': 'Indoor outdoor plants ke baare mein batao','color': 0xFF26C6DA},
      {'icon': Icons.bug_report_rounded,    'label': 'Kide 🦟',     'msg': 'Plants ke kide pests ke baare mein batao', 'color': 0xFFFFB300},
      {'icon': Icons.grass_rounded,         'label': 'Jadi Buti 🌱','msg': 'Ayurvedic aur medicinal plants batao',     'color': 0xFF9CCC65},
      {'icon': Icons.set_meal_rounded,      'label': 'Phal 🍎',     'msg': 'Phal ugane ki guide do',                  'color': 0xFFFF7043},
      {'icon': Icons.wb_sunny_rounded,      'label': 'Mausam 🌤️',  'msg': 'Abhi ke mausam mein kya ugaayein?',       'color': 0xFFFFD54F},
      {'icon': Icons.spa_rounded,           'label': 'Vastu 🏡',    'msg': 'Ghar ke liye vastu plants batao',         'color': 0xFFAB47BC},
      {'icon': Icons.water_drop_rounded,    'label': 'Sinchai 💧',  'msg': 'Pani dene ke sahi tarike batao',          'color': 0xFF42A5F5},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Topic chuniye 👇', style: TextStyle(
        color: AppTheme.textSecond, fontSize: 13, letterSpacing: 0.5,
      )),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.05,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cats.length,
        itemBuilder: (ctx, i) {
          final c = cats[i];
          final color = Color(c['color'] as int);
          return GestureDetector(
            onTap: () => _goChat(msg: c['msg'] as String),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withOpacity(0.07),
                border: Border.all(color: color.withOpacity(0.22)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(c['icon'] as IconData, color: color, size: 26),
                const SizedBox(height: 6),
                Text(c['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 550 + i * 60));
        },
      ),
    ]);
  }

  Widget _bottomBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border.withOpacity(0.4)),
      ),
      child: const Text(
        '🌐  Hindi • English • Tamil • Telugu • Bengali • Marathi • Gujarati • Punjabi • Malayalam • Kannada • Hinglish',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textHint, fontSize: 10, height: 1.5),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

// ── Background painter ──────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..style = PaintingStyle.fill;

    p.color = const Color(0xFF00E676).withOpacity(0.025);
    canvas.drawCircle(Offset(s.width * 0.85, s.height * 0.15 + math.sin(t * 2 * math.pi) * 30), 160, p);

    p.color = const Color(0xFF00E676).withOpacity(0.018);
    canvas.drawCircle(Offset(s.width * 0.1, s.height * 0.65 + math.cos(t * 2 * math.pi) * 25), 130, p);

    p.color = const Color(0xFF7C4DFF).withOpacity(0.015);
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.9 + math.sin(t * 2 * math.pi + 1) * 20), 100, p);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
