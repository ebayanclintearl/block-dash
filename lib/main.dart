import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(BlockDashApp(prefs: prefs));
}

class BlockDashApp extends StatelessWidget {
  const BlockDashApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: BlockDashColors.bgTop,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BlockDashColors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(prefs: prefs),
    );
  }
}

// ─── Colour Palette ────────────────────────────────────────────────────────────
class BlockDashColors {
  static const bgTop = Color(0xFF1255CC);
  static const bgMid = Color(0xFF1A6AD8);
  static const bgBottom = Color(0xFF3A9AEF);
  static const board = Color(0xFF183080);
  static const boardCell = Color(0xFF1C3A96);
  static const boardBorder = Color(0xFF2654BC);
  static const cyan = Color(0xFF00C8F0);
  static const blue = Color(0xFF1E72E8);
  static const yellow = Color(0xFFFFD600);
  static const orange = Color(0xFFFF9800);
  static const red = Color(0xFFEF3030);
  static const green = Color(0xFF43C447);
  static const purple = Color(0xFF9C3FD8);
  static const blockCyan = Color(0xFF14C8F0);
  static const blockRed = Color(0xFFEF3030);
  static const blockGreen = Color(0xFF30C050);
  static const blockYellow = Color(0xFFFFCC00);
  static const blockPurple = Color(0xFF9B3FE0);
  static const blockOrange = Color(0xFFFF7030);
  static const blockBlue = Color(0xFF2080FF);
  static const shadow18 = Color(0x2D000000);
  static const shadow28 = Color(0x47000000);
  static const shadow45 = Color(0x73000000);
  static const white12 = Color(0x1FFFFFFF);
  static const white30 = Color(0x4DFFFFFF);
  static const white55 = Color(0x8CFFFFFF);
  static const List<Color> trailRainbow = [
    Color(0xFF3A8CFF),
    Color(0xFF10C8F0),
    Color(0xFF38C048),
    Color(0xFFE8C000),
    Color(0xFFFF6828),
    Color(0xFFB050EE),
  ];
  static const List<Color> mutedTrailRainbow = [
    Color(0xC83A8CFF),
    Color(0xC810C8F0),
    Color(0xC838C048),
    Color(0xC8E8C000),
    Color(0xC8FF6828),
    Color(0xC8B050EE),
  ];
}

int _channel(double value) => (value * 255).round().clamp(0, 255);
int _red(Color color) => _channel(color.r);
int _green(Color color) => _channel(color.g);
int _blue(Color color) => _channel(color.b);

Color _colorWithAlpha(Color color, int alpha) {
  return Color.fromARGB(alpha, _red(color), _green(color), _blue(color));
}

Color _scaleColor(Color color, double scale, {int alpha = 255}) {
  return Color.fromARGB(
    alpha,
    (_red(color) * scale).round().clamp(0, 255),
    (_green(color) * scale).round().clamp(0, 255),
    (_blue(color) * scale).round().clamp(0, 255),
  );
}

Color _lightenColor(Color color, int amount) {
  return Color.fromARGB(
    255,
    math.min(255, _red(color) + amount),
    math.min(255, _green(color) + amount),
    math.min(255, _blue(color) + amount),
  );
}

class _GameSettings {
  static const sfxKey = 'blockDashSfxEnabled';
  static const backgroundMusicKey = 'blockDashBackgroundMusicEnabled';
  static const vibrationKey = 'blockDashVibrationEnabled';

  static bool sfxEnabled(SharedPreferences prefs) =>
      prefs.getBool(sfxKey) ?? true;

  static bool backgroundMusicEnabled(SharedPreferences prefs) =>
      prefs.getBool(backgroundMusicKey) ?? false;

  static bool vibrationEnabled(SharedPreferences prefs) =>
      prefs.getBool(vibrationKey) ?? true;
}

const _blockDashAudioFiles = [
  'move.wav',
  'combo.wav',
  'death.wav',
  'new_best.wav',
];

Future<void>? _blockDashAudioPreloadFuture;

Future<void> _preloadBlockDashAudio() {
  return _blockDashAudioPreloadFuture ??= FlameAudio.audioCache.loadAll(
    _blockDashAudioFiles,
  );
}

// ─── Home Screen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<void> _audioPreloadFuture;

  @override
  void initState() {
    super.initState();
    _audioPreloadFuture = _preloadBlockDashAudio();
  }

  @override
  Widget build(BuildContext context) {
    return _BlueScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const _HomeBlocks(),
                  const SizedBox(height: 12),
                  const _BlockTitle(text: 'BLOCK\nDASH'),
                  const SizedBox(height: 16),
                  _SubTag(text: 'STACK · DODGE · WIN'),
                  const Spacer(flex: 2),
                  _BigButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFFFF8C00),
                    accentColor: const Color(0xFFFFD000),
                    shadowColor: const Color(0xAAFF6000),
                    tall: true,
                    onPressed: () async {
                      await _audioPreloadFuture;
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(prefs: widget.prefs),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _BigButton(
                    label: 'RATE US',
                    icon: Icons.star_rate_rounded,
                    color: const Color(0xFF2DBD44),
                    accentColor: const Color(0xFF52E868),
                    shadowColor: const Color(0xAA1A8830),
                    onPressed: () => _showRateUsDialog(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: _HomeIconButton(
                tooltip: 'Settings',
                icon: Icons.settings_rounded,
                onPressed: () => _showSettingsDialog(context, widget.prefs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showSettingsDialog(
  BuildContext context,
  SharedPreferences prefs,
) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xAA071431),
    builder: (_) => _SettingsDialog(prefs: prefs),
  );
}

Future<void> _showRateUsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99071431),
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF263A9D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Rate Us',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: BlockDashColors.yellow, size: 34),
              Icon(Icons.star_rounded, color: BlockDashColors.yellow, size: 34),
              Icon(Icons.star_rounded, color: BlockDashColors.yellow, size: 34),
              Icon(Icons.star_rounded, color: BlockDashColors.yellow, size: 34),
              Icon(Icons.star_rounded, color: BlockDashColors.yellow, size: 34),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'Thanks for supporting Block Dash.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    ),
  );
}

class _HomeIconButton extends StatelessWidget {
  const _HomeIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x55183080),
              border: Border.all(color: const Color(0x66B0D8FF), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.prefs});

  final SharedPreferences prefs;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late bool _sfxEnabled;
  late bool _backgroundMusicEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _sfxEnabled = _GameSettings.sfxEnabled(widget.prefs);
    _backgroundMusicEnabled = _GameSettings.backgroundMusicEnabled(
      widget.prefs,
    );
    _vibrationEnabled = _GameSettings.vibrationEnabled(widget.prefs);
  }

  Future<void> _setSfxEnabled(bool value) async {
    setState(() => _sfxEnabled = value);
    await widget.prefs.setBool(_GameSettings.sfxKey, value);
  }

  Future<void> _setBackgroundMusicEnabled(bool value) async {
    setState(() => _backgroundMusicEnabled = value);
    await widget.prefs.setBool(_GameSettings.backgroundMusicKey, value);
  }

  Future<void> _setVibrationEnabled(bool value) async {
    setState(() => _vibrationEnabled = value);
    await widget.prefs.setBool(_GameSettings.vibrationKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6D95FF), Color(0xFF4C6EE8)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x778DB0FF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 3),
                              blurRadius: 4,
                              color: Color(0x66000000),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFD8E6FF),
                        size: 42,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 3,
                            color: Color(0x66000000),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xAA263A9D),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            _SettingsToggleRow(
                              icon: Icons.volume_up_rounded,
                              label: 'SFX',
                              value: _sfxEnabled,
                              onChanged: _setSfxEnabled,
                            ),
                            const _SettingsDivider(),
                            _SettingsToggleRow(
                              icon: Icons.music_note_rounded,
                              label: 'Background Music',
                              value: _backgroundMusicEnabled,
                              onChanged: _setBackgroundMusicEnabled,
                            ),
                            const _SettingsDivider(),
                            _SettingsToggleRow(
                              icon: Icons.vibration_rounded,
                              label: 'Vibration',
                              value: _vibrationEnabled,
                              onChanged: _setVibrationEnabled,
                            ),
                            const _SettingsDivider(),
                            _SettingsLinkRow(
                              icon: Icons.description_rounded,
                              label: 'Terms of Service',
                              onTap: () => _showInfoDialog(
                                context,
                                title: 'Terms of Service',
                                body:
                                    'Block Dash is provided for entertainment. '
                                    'By playing, you agree to use the game fairly '
                                    'and follow applicable app store rules.',
                              ),
                            ),
                            const _SettingsDivider(),
                            _SettingsLinkRow(
                              icon: Icons.privacy_tip_rounded,
                              label: 'Privacy Policy',
                              onTap: () => _showInfoDialog(
                                context,
                                title: 'Privacy Policy',
                                body:
                                    'Block Dash stores your settings and best '
                                    'score on this device. This build does not '
                                    'collect personal information.',
                              ),
                            ),
                            const _SettingsDivider(),
                            _SettingsLinkRow(
                              icon: Icons.mail_rounded,
                              label: 'Contact Us',
                              onTap: () => _showInfoDialog(
                                context,
                                title: 'Contact Us',
                                body:
                                    'For support, feedback, or questions, add '
                                    'your support email or help center link here.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            trackColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? const Color(0xFF68D36D)
                  : const Color(0xFF344793);
            }),
          ),
        ],
      ),
    );
  }
}

class _SettingsLinkRow extends StatelessWidget {
  const _SettingsLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0x332654BC),
    );
  }
}

Future<void> _showInfoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF263A9D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _HomeBlocks extends StatelessWidget {
  const _HomeBlocks();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: Transform.rotate(
              angle: -0.22,
              child: _MiniBlock(color: BlockDashColors.blockRed, size: 60),
            ),
          ),
          Positioned(
            right: 20,
            child: Transform.rotate(
              angle: 0.18,
              child: _MiniBlock(color: BlockDashColors.blockGreen, size: 55),
            ),
          ),
          Transform.rotate(
            angle: 0.0,
            child: _MiniBlock(color: BlockDashColors.blockYellow, size: 52),
          ),
        ],
      ),
    );
  }
}

class _MiniBlock extends StatelessWidget {
  const _MiniBlock({required this.color, this.size = 56});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: _colorWithAlpha(color, 100),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          const BoxShadow(
            color: Color(0x50000000),
            blurRadius: 6,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-0.5, -0.5),
        child: Container(
          width: size * 0.55,
          height: size * 0.28,
          decoration: BoxDecoration(
            color: BlockDashColors.white55,
            borderRadius: BorderRadius.circular(size * 0.12),
          ),
        ),
      ),
    );
  }
}

class _SubTag extends StatelessWidget {
  const _SubTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x401E72E8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: BlockDashColors.cyan.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Shared Big Button ─────────────────────────────────────────────────────────
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.accentColor,
    required this.shadowColor,
    required this.onPressed,
    this.tall = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color accentColor;
  final Color shadowColor;
  final VoidCallback onPressed;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final h = tall ? 84.0 : 68.0;
    final darkColor = _scaleColor(color, 0.68);

    return SizedBox(
      width: double.infinity,
      height: h + 6,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: darkColor,
                borderRadius: BorderRadius.circular(h / 2),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: h,
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(h / 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(h / 2),
                  onTap: onPressed,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accentColor, color],
                      ),
                      borderRadius: BorderRadius.circular(h / 2),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 5,
                          left: h * 0.6,
                          right: h * 0.6,
                          child: Container(
                            height: h * 0.28,
                            decoration: BoxDecoration(
                              color: BlockDashColors.white30,
                              borderRadius: BorderRadius.circular(h),
                            ),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: tall ? 34 : 28,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Color(0x66000000),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: tall ? 30 : 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(0, 3),
                                      blurRadius: 5,
                                      color: Color(0x77000000),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Block Title ───────────────────────────────────────────────────────────────
class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final fontSize = (shortest * 0.17).clamp(48.0, 84.0);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        height: 0.9,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: BlockDashColors.yellow,
        shadows: const [
          Shadow(offset: Offset(0, 5), blurRadius: 0, color: Color(0xAA000000)),
          Shadow(blurRadius: 20, color: Color(0x882080FF)),
        ],
      ),
    );
  }
}

// ─── Blue Scaffold ─────────────────────────────────────────────────────────────
class _BlueScaffold extends StatelessWidget {
  const _BlueScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            painter: _BgPainter(constraints.biggest),
            child: SizedBox.expand(child: child),
          );
        },
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.viewportSize);

  final Size viewportSize;
  Rect? _cachedRect;
  Shader? _cachedShader;
  final Paint _backgroundPaint = Paint();
  final Paint _dotPaint = Paint()..color = const Color(0x15FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (_cachedRect != rect) {
      _cachedRect = rect;
      _cachedShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          BlockDashColors.bgTop,
          BlockDashColors.bgMid,
          BlockDashColors.bgBottom,
        ],
      ).createShader(rect);
    }
    _backgroundPaint.shader = _cachedShader;
    canvas.drawRect(rect, _backgroundPaint);

    for (var x = 20.0; x < size.width; x += 40) {
      for (var y = 20.0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.5, _dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) {
    return oldDelegate.viewportSize != viewportSize;
  }
}

// ─── Game Screen ───────────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BlockDashGame _game;
  Future<void>? _gameLoadFuture;

  @override
  void initState() {
    super.initState();
    _game = BlockDashGame(prefs: widget.prefs, onGameOver: _openGameOver);
  }

  void _openGameOver(GameResult result) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameOverScreen(prefs: widget.prefs, result: result),
      ),
    );
  }

  Future<void> _ensureGameLoaded(Size size) {
    if (_gameLoadFuture != null) return _gameLoadFuture!;
    _gameLoadFuture = _loadGame(size);
    return _gameLoadFuture!;
  }

  Future<void> _loadGame(Size size) async {
    await _preloadBlockDashAudio();
    await Future<void>.delayed(Duration.zero);
    _game.onGameResize(Vector2(size.width, size.height));
    // ignore: invalid_use_of_internal_member
    await _game.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (size.isEmpty) return const _GameLoadingView();

            return FutureBuilder<void>(
              future: _ensureGameLoaded(size),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _GameLoadingView(error: snapshot.error);
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _GameLoadingView();
                }

                return Stack(
                  children: [
                    GameWidget(
                      game: _game,
                      loadingBuilder: (_) => const _GameLoadingView(),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) =>
                                  _game.movePlayer(Direction.left),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) =>
                                  _game.movePlayer(Direction.right),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          children: [
                            _GameHud(game: _game),
                            const SizedBox(height: 8),
                            _TimerBar(game: _game),
                            const SizedBox(height: 20),
                            // Fixed-height slot for combo — no layout shift
                            _ComboPopup(game: _game),
                            const SizedBox(height: 4),
                            // Status banner for fever / last-chance / milestone
                            _StatusBanner(game: _game),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GameLoadingView extends StatelessWidget {
  const _GameLoadingView({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _BgPainter(constraints.biggest),
          child: SizedBox.expand(
            child: Center(
              child: error == null
                  ? const SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 5,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load game.\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Game Over Screen ──────────────────────────────────────────────────────────
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key, required this.prefs, required this.result});

  final SharedPreferences prefs;
  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return _BlueScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Game Over',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFB0D8FF),
                  shadows: [
                    const Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 0,
                      color: Color(0x88000E6A),
                    ),
                    Shadow(
                      blurRadius: 20,
                      color: BlockDashColors.cyan.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ScorePanel(result: result),
              const Spacer(),
              _BigButton(
                label: 'PLAY AGAIN',
                icon: Icons.replay_rounded,
                color: const Color(0xFFFF8C00),
                accentColor: const Color(0xFFFFD000),
                shadowColor: const Color(0xAAFF6000),
                tall: true,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(prefs: prefs),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _BigButton(
                label: 'HOME',
                icon: Icons.home_rounded,
                color: const Color(0xFF2DBD44),
                accentColor: const Color(0xFF52E868),
                shadowColor: const Color(0xAA1A8830),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => HomeScreen(prefs: prefs),
                  ),
                  (_) => false,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0x40183080),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BlockDashColors.cyan.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Score',
            style: TextStyle(
              color: Color(0xAAB0D8FF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.score}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              height: 1,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(offset: Offset(0, 4), color: Color(0x88000000))],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x30B0D8FF)),
          const SizedBox(height: 18),
          const Text(
            'Best Score',
            style: TextStyle(
              color: Color(0xAAB0D8FF),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.bestScore}',
            style: const TextStyle(
              color: BlockDashColors.yellow,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(offset: Offset(0, 3), color: Color(0x88000000))],
            ),
          ),
          if (result.isNewBest) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE564), BlockDashColors.orange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🏆  NEW HIGH SCORE!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          if (result.maxCombo > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Best Combo: ${result.maxCombo}x',
              style: const TextStyle(
                color: Color(0xCCB0D8FF),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── HUD Widgets ───────────────────────────────────────────────────────────────
class _GameHud extends StatelessWidget {
  const _GameHud({required this.game});

  final BlockDashGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RepaintBoundary(
          child: ValueListenableBuilder<int>(
            valueListenable: game.bestNotifier,
            builder: (_, best, _) => _CrownScore(value: best),
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            child: ValueListenableBuilder<int>(
              valueListenable: game.scoreNotifier,
              builder: (_, score, _) => Text(
                '$score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(offset: Offset(0, 3), color: Color(0x88000000)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Fever flame icon — only visible in fever mode
        RepaintBoundary(
          child: ValueListenableBuilder<bool>(
            valueListenable: game.feverNotifier,
            builder: (_, fever, _) => SizedBox(
              width: 36,
              child: fever
                  ? const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF6020),
                      size: 30,
                      shadows: [
                        Shadow(blurRadius: 8, color: Color(0xAAFF4000)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        // Shield icon — shown while last-chance is available
        RepaintBoundary(
          child: ValueListenableBuilder<bool>(
            valueListenable: game.lastChanceNotifier,
            builder: (_, hasShield, _) => SizedBox(
              width: 32,
              child: hasShield
                  ? const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF60D8FF),
                      size: 22,
                      shadows: [
                        Shadow(blurRadius: 6, color: Color(0x8800D0FF)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrownScore extends StatelessWidget {
  const _CrownScore({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: BlockDashColors.yellow,
          size: 22,
        ),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Timer Bar ─────────────────────────────────────────────────────────────────
class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.game});

  static const _trackWidth = 200.0;
  static const _trackPadding = 3.0;
  static const _trackHeight = 14.0;
  static const _fillHeight = _trackHeight - _trackPadding * 2;
  static const _fillMaxWidth = _trackWidth - _trackPadding * 2;
  static const _fillAnimationDuration = Duration(milliseconds: 90);

  static const _greenColors = [BlockDashColors.green, Color(0xFF80E880)];
  static const _yellowColors = [BlockDashColors.yellow, BlockDashColors.orange];
  static const _redColors = [BlockDashColors.red, Color(0xFFFF6060)];

  static const _trackDecoration = BoxDecoration(
    color: Color(0x66183080),
    borderRadius: BorderRadius.all(Radius.circular(10)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x552654BC), width: 2),
    ),
  );

  static const _greenFillDecoration = BoxDecoration(
    gradient: LinearGradient(colors: _greenColors),
    borderRadius: BorderRadius.all(Radius.circular(7)),
  );
  static const _yellowFillDecoration = BoxDecoration(
    gradient: LinearGradient(colors: _yellowColors),
    borderRadius: BorderRadius.all(Radius.circular(7)),
  );
  static const _redFillDecoration = BoxDecoration(
    gradient: LinearGradient(colors: _redColors),
    borderRadius: BorderRadius.all(Radius.circular(7)),
  );

  final BlockDashGame game;

  static BoxDecoration _fillDecorationFor(double value) {
    if (value <= 0.25) return _redFillDecoration;
    if (value <= 0.5) return _yellowFillDecoration;
    return _greenFillDecoration;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: game.timerNotifier,
          builder: (_, value, _) {
            return Container(
              width: _trackWidth,
              height: _trackHeight,
              padding: const EdgeInsets.all(_trackPadding),
              decoration: _trackDecoration,
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                width: _fillMaxWidth * value.clamp(0.0, 1.0),
                height: _fillHeight,
                duration: _fillAnimationDuration,
                curve: Curves.linear,
                decoration: _fillDecorationFor(value),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Combo Popup — shows fever state when active ────────────────────────────────
class _ComboPopup extends StatelessWidget {
  const _ComboPopup({required this.game});

  // Standard yellow/orange combo pill
  static const _comboDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFFFE566), BlockDashColors.orange],
    ),
    borderRadius: BorderRadius.all(Radius.circular(15)),
    border: Border.fromBorderSide(BorderSide(color: Color(0x66FFFFFF))),
  );

  // Hot red/pink fever pill — same shape, hotter palette
  static const _feverDecoration = BoxDecoration(
    gradient: LinearGradient(colors: [Color(0xFFFF6020), Color(0xFFFF1880)]),
    borderRadius: BorderRadius.all(Radius.circular(15)),
    border: Border.fromBorderSide(BorderSide(color: Color(0x77FFFFFF))),
  );

  final BlockDashGame game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            game.comboNotifier,
            game.feverNotifier,
          ]),
          builder: (_, _) {
            final combo = game.comboNotifier.value;
            final fever = game.feverNotifier.value;
            if (combo < 3) return const SizedBox.shrink();
            return Center(
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: fever ? _feverDecoration : _comboDecoration,
                alignment: Alignment.center,
                child: Text(
                  fever ? '🔥 ${combo}x FEVER!' : '${combo}x COMBO!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Status Banner — fever / last-chance / milestone messages ─────────────────
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.game});

  final BlockDashGame game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: RepaintBoundary(
        child: ValueListenableBuilder<String>(
          valueListenable: game.statusNotifier,
          builder: (_, status, _) {
            if (status.isEmpty) return const SizedBox.shrink();
            return Center(
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 6,
                      color: Color(0x88000000),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Game Enums / Models ───────────────────────────────────────────────────────
enum Direction { left, right }

class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.colorKey,
  });
  Offset position;
  final Offset velocity;
  final Color color;
  final int colorKey;
  double age = 0;
  static const life = 0.55;
}

class ScorePopup {
  ScorePopup({required this.worldPosition, required this.points});
  Offset worldPosition;
  final int points;
  double age = 0;
  static const life = 0.9;
}

class GameResult {
  const GameResult({
    required this.score,
    required this.bestScore,
    required this.isNewBest,
    required this.maxCombo,
  });
  final int score;
  final int bestScore;
  final bool isNewBest;
  final int maxCombo;
}

// ─── Flame Game ────────────────────────────────────────────────────────────────
class BlockDashGame extends FlameGame {
  BlockDashGame({required this.prefs, required this.onGameOver})
    : bestScore = prefs.getInt(_bestScoreKey) ?? 0 {
    bestNotifier.value = bestScore;
  }

  static final _identityMatrix4 = Float64List.fromList([
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);

  static const _bestScoreKey = 'blockDashBest';
  static const cols = 5;
  static const gap = 4.0;
  static const baseMoveSeconds = 0.24;
  static const hazardPeriod = 5;
  static const hazardOffset = 6;
  static const lookAheadRows = 80;
  static const cleanupBehindRows = 30;
  static const timerMax = 100.0;
  static const baseTimerDrain = 22.0;
  static const maxTimerDrain = 62.0;
  static const timerRefill = 35.0;
  // ── ARCADE: combo timeout extended for easier chaining ──
  static const comboTimeout = 2.0;
  static const cameraFollowStrength = 12.0;
  static final _cameraFollowFactor = 1 - math.exp(-cameraFollowStrength / 60.0);
  static const maxParticles = 40;
  static const particleBurstCount = 8;
  static const maxScorePopupPainters = 20;

  // ── NEW: Arcade mechanic constants ─────────────────────────────────────────
  /// Rows between bonus (gold) block spawns.
  static const bonusPeriod = 14;

  /// Score awarded per collected bonus block.
  static const bonusScore = 75;

  /// Timer units refilled on bonus block collection.
  static const bonusTimerRefill = 28.0;

  /// Combo count needed to enter Fever mode.
  static const feverComboThreshold = 8;

  /// In Fever mode the drain rate is multiplied by this factor (<1 = slower drain).
  static const feverDrainFactor = 0.6;

  /// Score multiple at which a milestone bonus fires (full timer refill).
  static const milestoneInterval = 100;

  /// Minimum combo to be rescued by Last Chance.
  static const lastChanceMinCombo = 5;

  /// Timer units restored by the Last Chance save.
  static const lastChanceTimerAmount = 42.0;

  /// Points awarded for landing directly adjacent to a hazard.
  static const nearMissBonus = 8;

  /// Probability that a hazard row gets a blocker on BOTH edges.
  static const doubleHazardChance = 0.15;

  static const _particleColors = [
    BlockDashColors.blockRed,
    BlockDashColors.orange,
    BlockDashColors.yellow,
    BlockDashColors.blockGreen,
    BlockDashColors.blockCyan,
    BlockDashColors.blockBlue,
    BlockDashColors.blockPurple,
  ];

  final SharedPreferences prefs;
  final void Function(GameResult result) onGameOver;

  // ── Notifiers ──────────────────────────────────────────────────────────────
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> bestNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> timerNotifier = ValueNotifier<double>(1);
  final ValueNotifier<int> comboNotifier = ValueNotifier<int>(0);

  /// True while Fever mode is active (UI uses this to style the combo pill).
  final ValueNotifier<bool> feverNotifier = ValueNotifier<bool>(false);

  /// True while the player still has their Last Chance shield.
  final ValueNotifier<bool> lastChanceNotifier = ValueNotifier<bool>(true);

  /// Temporary status text (Fever!, Last Chance!, Score Bonus!).
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  // ── Spatial data ───────────────────────────────────────────────────────────
  final hazardsByRow = SplayTreeMap<int, int>();
  final trailsByRow = SplayTreeMap<int, int>();

  /// Bonus (gold) block positions — same bitmask convention as hazards/trails.
  final bonusByRow = SplayTreeMap<int, int>();

  final particles = <Particle>[];
  final scorePopups = <ScorePopup>[];
  final random = math.Random();
  final _cellXs = List<double>.filled(cols, 0, growable: false);
  final _scorePopupPainters = <int, TextPainter>{};
  final _particlePaint = Paint();
  final _particleBatchPath = Path();
  final _blockPictures = <Color, ui.Picture>{};
  ui.Image? _backgroundImage;
  ui.Image? _boardRowImage;
  final _boardPatternPaint = Paint();
  bool _layoutReady = false;

  // Pre-allocated paints (never create Paint in render/update hot path)
  final _boardCellPaint = Paint()..color = BlockDashColors.boardCell;
  final _boardBorderPaint = Paint()
    ..color = const Color(0x202654BC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final _trackPaint = Paint()..color = BlockDashColors.board;
  final _bgLinePaint = Paint()
    ..color = const Color(0x0CFFFFFF)
    ..strokeWidth = 1;
  final _trackLinePaint = Paint()
    ..color = const Color(0x142654BC)
    ..strokeWidth = 1;

  /// Pre-allocated for the fever edge-glow overlay.
  final _feverEdgePaint = Paint();

  /// Pre-allocated for the full-screen flash (milestone / last-chance).
  final _flashPaint = Paint();

  AudioPool? _moveSoundPool;
  AudioPool? _comboSoundPool;

  // ── Layout ─────────────────────────────────────────────────────────────────
  late double cellSize;
  late double rowHeight;
  late double gridWidth;
  late double gridLeft;

  // ── Camera / player state ──────────────────────────────────────────────────
  late double worldScrollY;
  late double cameraTargetScrollY;
  late double playerWorldY;
  late double playerScreenY;
  late int playerCol;
  late int playerRow;
  late int nextHazardRow;
  int? lastHazardSide;
  int? secondLastHazardSide;
  late int nextBonusRow;

  // ── Score / combo ──────────────────────────────────────────────────────────
  int score = 0;
  int bestScore;
  int comboCount = 0;
  int maxCombo = 0;
  double comboTimeLeft = 0;
  String? lastComboMove;

  // ── Fever mode ─────────────────────────────────────────────────────────────
  bool isFeverMode = false;
  double feverPulse = 0;

  // ── Milestones / last chance ───────────────────────────────────────────────
  int lastMilestone = 0;
  bool hasLastChance = true;

  // ── Screen flash ───────────────────────────────────────────────────────────
  double screenFlashAlpha = 0;
  Color _screenFlashColor = Colors.white;

  // ── Timer / difficulty ─────────────────────────────────────────────────────
  double timerValue = timerMax;
  double lastTimerRatio = 1;
  double timerNotifyElapsed = 0;
  double currentSpeed = baseMoveSeconds;
  double currentDrain = baseTimerDrain;

  // ── Move animation ─────────────────────────────────────────────────────────
  bool isMoving = false;
  bool isDead = false;
  double moveElapsed = 0;
  double moveDuration = 0;
  double cachedEasedMoveT = 1;
  double moveStartX = 0;
  double moveEndX = 0;
  double moveStartWorldY = 0;
  double moveEndWorldY = 0;
  int pendingCol = 0;
  int pendingRow = 0;
  int pendingSteps = 0;
  bool pendingDeath = false;
  int pendingBonusCollects = 0;

  // ── Effects ────────────────────────────────────────────────────────────────
  Offset shakeOffset = Offset.zero;
  double shakeTimeLeft = 0;
  double comboSoundCooldown = 0;

  Timer? _statusTimer;

  @override
  Color backgroundColor() => BlockDashColors.bgTop;

  @override
  Future<void> onLoad() async {
    final pools = await Future.wait<AudioPool>([
      FlameAudio.createPool('move.wav', maxPlayers: 4),
      FlameAudio.createPool('combo.wav', maxPlayers: 3),
    ]);
    _moveSoundPool = pools[0];
    _comboSoundPool = pools[1];
    await Future<void>.delayed(Duration.zero);
    resetGame();
  }

  @override
  void onRemove() {
    _statusTimer?.cancel();
    _disposeRenderCache();
    _disposeScorePopupPainters();
    _disposeAudioPools();
    scoreNotifier.dispose();
    bestNotifier.dispose();
    timerNotifier.dispose();
    comboNotifier.dispose();
    feverNotifier.dispose();
    lastChanceNotifier.dispose();
    statusNotifier.dispose();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _computeLayout();
    if (isLoaded) {
      if (!isMoving) playerWorldY = _rowToY(playerRow);
      final anchor = isMoving ? _cameraAnchorY : size.y - cellSize - 20;
      worldScrollY = playerWorldY - anchor;
      cameraTargetScrollY = worldScrollY;
      playerScreenY = playerWorldY - worldScrollY;
    }
  }

  void resetGame() {
    _computeLayout();
    hazardsByRow.clear();
    trailsByRow.clear();
    bonusByRow.clear();
    particles.clear();
    scorePopups.clear();
    _disposeScorePopupPainters();

    playerCol = 2;
    playerRow = 0;
    nextHazardRow = -hazardOffset;
    nextBonusRow = -10; // first bonus block a bit deeper than first hazard
    lastHazardSide = null;
    secondLastHazardSide = null;

    score = 0;
    comboCount = 0;
    maxCombo = 0;
    comboTimeLeft = 0;
    lastComboMove = null;

    isFeverMode = false;
    feverPulse = 0;
    lastMilestone = 0;
    hasLastChance = true;
    screenFlashAlpha = 0;
    pendingBonusCollects = 0;

    timerValue = timerMax;
    lastTimerRatio = 1;
    timerNotifyElapsed = 0;
    currentSpeed = baseMoveSeconds;
    currentDrain = baseTimerDrain;
    isMoving = false;
    isDead = false;
    cachedEasedMoveT = 1;
    comboSoundCooldown = 0;
    shakeOffset = Offset.zero;

    playerWorldY = _rowToY(playerRow);
    playerScreenY = size.y - cellSize - 20;
    worldScrollY = playerWorldY - playerScreenY;
    cameraTargetScrollY = worldScrollY;

    scoreNotifier.value = 0;
    bestNotifier.value = bestScore;
    _syncTimerNotifier(force: true);
    comboNotifier.value = 0;
    feverNotifier.value = false;
    lastChanceNotifier.value = true;
    statusNotifier.value = '';
    _statusTimer?.cancel();

    // Generate hazards first so bonus generation can avoid them
    _generateHazardsUntil(-lookAheadRows);
    _generateBonusUntil(-lookAheadRows);
    _placeTrail(playerCol, playerRow);
  }

  void movePlayer(Direction direction) {
    if (isMoving || isDead || size.x <= 0 || size.y <= 0) return;

    final onRight = playerCol == cols - 1;
    final onLeft = playerCol == 0;
    final isForward =
        (direction == Direction.right && onRight) ||
        (direction == Direction.left && onLeft);

    final int colDelta;
    final int totalSteps;
    final moveKind = isForward ? 'forward' : 'diagonal';

    if (isForward) {
      colDelta = 0;
      totalSteps = 4;
    } else {
      colDelta = direction == Direction.right ? 1 : -1;
      totalSteps = direction == Direction.right
          ? cols - 1 - playerCol
          : playerCol;
    }

    // Generate ahead — hazards first so bonus can check them
    _generateHazardsUntil(playerRow - totalSteps - lookAheadRows);
    _generateBonusUntil(playerRow - totalSteps - lookAheadRows);

    // Determine how far the player can travel (stop at hazard)
    var hitStep = -1;
    var c = playerCol;
    var r = playerRow;
    for (var i = 0; i < totalSteps; i++) {
      c = (c + colDelta).clamp(0, cols - 1);
      r--;
      if (_hasHazardAt(c, r)) {
        hitStep = i + 1;
        break;
      }
    }

    final steps = hitStep > 0 ? hitStep : totalSteps;
    final destCol = (playerCol + colDelta * steps).clamp(0, cols - 1);
    final destRow = playerRow - steps;
    final duration = math.max(0.16, currentSpeed * steps / totalSteps);

    // Collect any bonus blocks along the path
    pendingBonusCollects = 0;
    var pc = playerCol;
    var pr = playerRow;
    for (var i = 0; i < steps; i++) {
      pc = (pc + colDelta).clamp(0, cols - 1);
      pr--;
      if (_hasBonusAt(pc, pr)) {
        pendingBonusCollects++;
        _removeBonusAt(pc, pr);
      }
    }

    _increaseCombo(moveKind);
    _playSound('move.wav');
    _playHapticSelection();
    _placeTrailPath(playerCol, playerRow, colDelta, steps);
    _spawnParticles(
      _screenX(playerCol) + cellSize / 2,
      playerScreenY + cellSize / 2,
    );
    _refillTimer();

    final destWorldY = _rowToY(destRow);

    isMoving = true;
    pendingCol = destCol;
    pendingRow = destRow;
    pendingSteps = steps;
    pendingDeath = hitStep > 0;
    moveElapsed = 0;
    moveDuration = duration;
    cachedEasedMoveT = 0;
    moveStartX = _screenX(playerCol);
    moveEndX = _screenX(destCol);
    moveStartWorldY = playerWorldY;
    moveEndWorldY = destWorldY;
    cameraTargetScrollY = math.min(
      cameraTargetScrollY,
      destWorldY - _cameraAnchorY,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateParticles(dt);
    _updateScorePopups(dt);
    _updateShake(dt);

    // Fever pulse (used for edge-glow animation)
    if (isFeverMode) feverPulse += dt * 5.0;

    // Fade out screen flash
    if (screenFlashAlpha > 0) {
      screenFlashAlpha = math.max(0, screenFlashAlpha - dt * 3.0);
    }

    if (comboSoundCooldown > 0) {
      comboSoundCooldown = math.max(0, comboSoundCooldown - dt);
    }

    if (isDead) return;

    if (comboTimeLeft > 0) {
      comboTimeLeft -= dt;
      if (comboTimeLeft <= 0) _resetCombo();
    }

    // In Fever mode the timer drains more slowly (reward for skilled play)
    final effectiveDrain = isFeverMode
        ? currentDrain * feverDrainFactor
        : currentDrain;
    timerValue = math.max(0, timerValue - effectiveDrain * dt);
    timerNotifyElapsed += dt;
    _syncTimerNotifier();
    if (timerValue <= 0) {
      unawaited(_triggerDeath());
      return;
    }

    if (isMoving) {
      moveElapsed += dt;
      final t = (moveElapsed / moveDuration).clamp(0.0, 1.0);
      cachedEasedMoveT = _ease(t);
      playerWorldY = ui.lerpDouble(
        moveStartWorldY,
        moveEndWorldY,
        cachedEasedMoveT,
      )!;

      if (t >= 1) {
        isMoving = false;
        cachedEasedMoveT = 1;
        playerCol = pendingCol;
        playerRow = pendingRow;
        playerWorldY = moveEndWorldY;
        cameraTargetScrollY = math.min(
          cameraTargetScrollY,
          playerWorldY - _cameraAnchorY,
        );
        _cleanupRowsBehind(playerRow);

        // Base move score
        final movePoints = (pendingSteps + 1) * _comboMultiplier();
        score += movePoints;
        scoreNotifier.value = score;
        scorePopups.add(
          ScorePopup(
            worldPosition: Offset(
              moveEndX + cellSize / 2,
              playerWorldY + cellSize / 2,
            ),
            points: movePoints,
          ),
        );

        // ── Bonus block rewards ────────────────────────────────────────────
        if (pendingBonusCollects > 0) {
          final bonusPoints = pendingBonusCollects * bonusScore;
          score += bonusPoints;
          scoreNotifier.value = score;
          timerValue = math.min(
            timerMax,
            timerValue + bonusTimerRefill * pendingBonusCollects,
          );
          _syncTimerNotifier(force: true);
          scorePopups.add(
            ScorePopup(
              worldPosition: Offset(
                moveEndX + cellSize / 2,
                playerWorldY - cellSize * 1.2,
              ),
              points: bonusPoints,
            ),
          );
          if (comboSoundCooldown <= 0) {
            _playSound('combo.wav');
            comboSoundCooldown = 0.3;
          }
          _triggerScreenFlash(BlockDashColors.blockYellow, 0.28);
          _playHapticHeavy();
          pendingBonusCollects = 0;
        }

        // ── Near-miss bonus ────────────────────────────────────────────────
        // Award points for landing directly adjacent to a hazard row.
        if (!pendingDeath) {
          final leftAdj = playerCol - 1;
          final rightAdj = playerCol + 1;
          final nearMiss =
              (leftAdj >= 0 && _hasHazardAt(leftAdj, playerRow)) ||
              (rightAdj < cols && _hasHazardAt(rightAdj, playerRow));
          if (nearMiss) {
            score += nearMissBonus;
            scoreNotifier.value = score;
            scorePopups.add(
              ScorePopup(
                worldPosition: Offset(
                  moveEndX + cellSize / 2,
                  playerWorldY - cellSize * 0.6,
                ),
                points: nearMissBonus,
              ),
            );
          }
        }

        // ── Score milestone bonus ──────────────────────────────────────────
        final milestone = score ~/ milestoneInterval;
        if (milestone > lastMilestone) {
          lastMilestone = milestone;
          timerValue = timerMax; // full refill as reward
          _syncTimerNotifier(force: true);
          _triggerScreenFlash(Colors.white, 0.5);
          if (comboSoundCooldown <= 0) {
            _playSound('combo.wav');
            comboSoundCooldown = 0.3;
          }
          _setStatus('🎯  ${milestone * milestoneInterval}  SCORE BONUS!');
        }

        _updateDifficulty();
        if (pendingDeath) unawaited(_triggerDeath(byHazard: true));
      }
    }

    _updateCamera();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (shakeOffset == Offset.zero) {
      _renderScene(canvas);
      return;
    }
    canvas.save();
    canvas.translate(shakeOffset.dx, shakeOffset.dy);
    _renderScene(canvas);
    canvas.restore();
  }

  void _renderScene(Canvas canvas) {
    _renderBackground(canvas);
    _renderBoard(canvas);
    _renderTrails(canvas);
    _renderHazards(canvas);
    _renderBonusBlocks(canvas); // ← NEW: gold collectibles
    _renderParticles(canvas);
    _renderPlayer(canvas);
    _renderScorePopups(canvas);
    _renderFeverOverlay(canvas); // ← NEW: warm edge glow in fever
    _renderScreenFlash(canvas); // ← NEW: milestone / last-chance flash
  }

  void _computeLayout() {
    final visibleAbove = size.y * 0.50;
    final byHeight = ((visibleAbove - gap * 8) / 7.2).floor();
    final byWidth = ((size.x * 0.96 - gap * (cols + 1)) / cols).floor();
    final nextCellSize = math.max(math.min(byHeight, byWidth), 44).toDouble();
    final nextRowHeight = nextCellSize + gap;
    final nextGridWidth = cols * (nextCellSize + gap) + gap;
    final nextGridLeft = ((size.x - nextGridWidth) / 2).roundToDouble();
    final changed =
        !_layoutReady ||
        nextCellSize != cellSize ||
        nextRowHeight != rowHeight ||
        nextGridWidth != gridWidth ||
        nextGridLeft != gridLeft;

    cellSize = nextCellSize;
    rowHeight = nextRowHeight;
    gridWidth = nextGridWidth;
    gridLeft = nextGridLeft;
    for (var col = 0; col < cols; col++) {
      _cellXs[col] = gap + col * (cellSize + gap);
    }

    if (changed) {
      _layoutReady = true;
      _rebuildRenderCache();
    }
  }

  double get _cameraAnchorY => size.y * 0.50;
  double _cellX(int col) => _cellXs[col];
  double _rowToY(int row) => gap + row * rowHeight;
  double _screenX(int col) => gridLeft + _cellX(col);

  void _updateCamera() {
    final delta = cameraTargetScrollY - worldScrollY;
    if (delta.abs() < 0.05) {
      worldScrollY = cameraTargetScrollY;
    } else {
      worldScrollY += delta * _cameraFollowFactor;
    }
    playerScreenY = playerWorldY - worldScrollY;
  }

  double _ease(double t) {
    if (t < 0.5) return 4 * t * t * t;
    return 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
  }

  void _disposeRenderCache() {
    _backgroundImage?.dispose();
    _boardRowImage?.dispose();
    for (final picture in _blockPictures.values) {
      picture.dispose();
    }
    _backgroundImage = null;
    _boardRowImage = null;
    _boardPatternPaint.shader = null;
    _blockPictures.clear();
  }

  void _rebuildRenderCache() {
    if (size.x <= 0 || size.y <= 0) return;
    _disposeRenderCache();

    final backgroundPicture = _recordPicture(
      Rect.fromLTWH(0, 0, size.x, size.y),
      (canvas) {
        final full = Rect.fromLTWH(0, 0, size.x, size.y);
        canvas.drawRect(
          full,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BlockDashColors.bgTop,
                BlockDashColors.bgMid,
                BlockDashColors.bgBottom,
              ],
            ).createShader(full),
        );

        for (var x = 20.0; x < size.x; x += 48) {
          for (var y = 0.0; y < size.y; y += 48) {
            if (x < gridLeft || x > gridLeft + gridWidth) {
              canvas.drawCircle(Offset(x, y), 1.2, _bgLinePaint);
            }
          }
        }

        final boardRect = Rect.fromLTWH(gridLeft, 0, gridWidth, size.y);
        canvas.drawRect(boardRect, _trackPaint);

        for (var x = gridLeft + 32; x < gridLeft + gridWidth; x += 32) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.y), _trackLinePaint);
        }
      },
    );
    _backgroundImage = backgroundPicture.toImageSync(
      size.x.ceil(),
      size.y.ceil(),
    );
    backgroundPicture.dispose();

    final boardRowPicture = _recordPicture(
      Rect.fromLTWH(0, 0, gridWidth, rowHeight),
      (canvas) {
        for (var col = 0; col < cols; col++) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(_cellX(col), 0, cellSize, cellSize),
            const Radius.circular(8),
          );
          canvas.drawRRect(rect, _boardCellPaint);
          canvas.drawRRect(rect, _boardBorderPaint);
        }
      },
    );
    _boardRowImage = boardRowPicture.toImageSync(
      gridWidth.ceil(),
      rowHeight.ceil(),
    );
    boardRowPicture.dispose();
    _boardPatternPaint.shader = ui.ImageShader(
      _boardRowImage!,
      TileMode.clamp,
      TileMode.repeated,
      _identityMatrix4,
    );

    _cacheBlockPicture(BlockDashColors.blockCyan);
    _cacheBlockPicture(BlockDashColors.blockRed);
    _cacheBlockPicture(BlockDashColors.blockYellow); // bonus blocks
    for (final color in BlockDashColors.mutedTrailRainbow) {
      _cacheBlockPicture(color);
    }
  }

  ui.Picture _recordPicture(Rect cullRect, void Function(Canvas canvas) paint) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, cullRect);
    paint(canvas);
    return recorder.endRecording();
  }

  void _cacheBlockPicture(Color color) {
    _blockPictures[color] = _recordPicture(
      Rect.fromLTWH(0, 0, cellSize, cellSize + 8),
      (canvas) =>
          _drawBlockRaw(canvas, Rect.fromLTWH(0, 0, cellSize, cellSize), color),
    );
  }

  void _drawPictureAt(Canvas canvas, ui.Picture picture, double x, double y) {
    canvas.save();
    canvas.translate(x, y);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  void _drawPictureRow(
    Canvas canvas,
    ui.Picture picture,
    double y,
    int rowMask,
  ) {
    if (rowMask == 0) return;
    canvas.save();
    canvas.translate(gridLeft, y);
    var currentX = 0.0;
    for (var col = 0; col < cols; col++) {
      if ((rowMask & _colBit(col)) == 0) continue;
      final x = _cellX(col);
      canvas.translate(x - currentX, 0);
      currentX = x;
      canvas.drawPicture(picture);
    }
    canvas.restore();
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  void _renderBackground(Canvas canvas) {
    final image = _backgroundImage;
    if (image != null) canvas.drawImage(image, Offset.zero, Paint());
  }

  void _renderBoard(Canvas canvas) {
    final firstRow = ((worldScrollY - rowHeight) / rowHeight).floor();
    final lastRow = ((worldScrollY + size.y + rowHeight) / rowHeight).ceil();
    if (_boardRowImage == null) return;

    final y = _rowToY(firstRow) - worldScrollY;
    final height = (lastRow - firstRow + 1) * rowHeight;
    canvas.save();
    canvas.translate(gridLeft, y);
    canvas.drawRect(Rect.fromLTWH(0, 0, gridWidth, height), _boardPatternPaint);
    canvas.restore();
  }

  void _renderTrails(Canvas canvas) {
    const trailColors = BlockDashColors.mutedTrailRainbow;
    final firstRow = ((worldScrollY - rowHeight) / rowHeight).floor();
    final lastRow = ((worldScrollY + size.y + rowHeight) / rowHeight).ceil();
    for (var row = firstRow; row <= lastRow; row++) {
      final rowMask = trailsByRow[row] ?? 0;
      if (rowMask == 0) continue;
      final y = _rowToY(row) - worldScrollY;
      final color = trailColors[row.abs() % trailColors.length];
      final picture = _cachedBlockPictureFor(color);
      if (picture == null) continue;
      _drawPictureRow(canvas, picture, y, rowMask);
    }
  }

  void _renderHazards(Canvas canvas) {
    final firstRow = ((worldScrollY - rowHeight) / rowHeight).floor();
    final lastRow = ((worldScrollY + size.y + rowHeight) / rowHeight).ceil();
    for (var row = firstRow; row <= lastRow; row++) {
      final rowMask = hazardsByRow[row] ?? 0;
      if (rowMask == 0) continue;
      final y = _rowToY(row) - worldScrollY;
      final picture = _cachedBlockPictureFor(BlockDashColors.blockRed);
      if (picture == null) continue;
      _drawPictureRow(canvas, picture, y, rowMask);
    }
  }

  /// NEW: Render gold bonus blocks in the visible area.
  void _renderBonusBlocks(Canvas canvas) {
    final firstRow = ((worldScrollY - rowHeight) / rowHeight).floor();
    final lastRow = ((worldScrollY + size.y + rowHeight) / rowHeight).ceil();
    for (var row = firstRow; row <= lastRow; row++) {
      final rowMask = bonusByRow[row] ?? 0;
      if (rowMask == 0) continue;
      final y = _rowToY(row) - worldScrollY;
      final picture = _cachedBlockPictureFor(BlockDashColors.blockYellow);
      if (picture == null) continue;
      _drawPictureRow(canvas, picture, y, rowMask);
    }
  }

  /// NEW: Pulsing warm edge-glow visible during Fever mode.
  void _renderFeverOverlay(Canvas canvas) {
    if (!isFeverMode) return;
    final pulse = math.sin(feverPulse) * 0.5 + 0.5; // 0..1
    final alpha = (pulse * 50).round();
    _feverEdgePaint.color = Color.fromARGB(alpha, 255, 70, 0);
    const edgeW = 32.0;
    final w = size.x;
    final h = size.y;
    canvas.drawRect(Rect.fromLTWH(0, 0, edgeW, h), _feverEdgePaint);
    canvas.drawRect(Rect.fromLTWH(w - edgeW, 0, edgeW, h), _feverEdgePaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, edgeW), _feverEdgePaint);
    canvas.drawRect(Rect.fromLTWH(0, h - edgeW, w, edgeW), _feverEdgePaint);
  }

  /// NEW: Full-screen colour flash for milestone / last-chance events.
  void _renderScreenFlash(Canvas canvas) {
    if (screenFlashAlpha <= 0) return;
    _flashPaint.color = _colorWithAlpha(
      _screenFlashColor,
      (screenFlashAlpha * 255).round().clamp(0, 255),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _flashPaint);
  }

  void _renderPlayer(Canvas canvas) {
    final x = isMoving
        ? ui.lerpDouble(moveStartX, moveEndX, cachedEasedMoveT)!
        : _screenX(playerCol);
    _drawCachedBlock(
      canvas,
      x,
      playerScreenY,
      isDead ? BlockDashColors.blockRed : BlockDashColors.blockCyan,
    );
  }

  void _drawCachedBlock(Canvas canvas, double x, double y, Color color) {
    final picture = _cachedBlockPictureFor(color);
    if (picture == null) return;
    _drawPictureAt(canvas, picture, x, y);
  }

  ui.Picture? _cachedBlockPictureFor(Color color) {
    return _blockPictures[color];
  }

  /// Glossy 3-D block — Block-Blast inspired.
  void _drawBlockRaw(Canvas canvas, Rect rect, Color color) {
    final radius = const Radius.circular(10);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // 1. Drop shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 5)),
      Paint()..color = _scaleColor(color, 0.3, alpha: 130),
    );

    // 2. Bottom-face depth strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 3)), radius),
      Paint()..color = _scaleColor(color, 0.55),
    );

    // 3. Main face gradient
    final lightColor = _lightenColor(color, 40);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightColor, color],
        ).createShader(rect),
    );

    // 4. Gloss highlight
    final glossRect = Rect.fromLTWH(
      rect.left + rect.width * 0.12,
      rect.top + rect.height * 0.09,
      rect.width * 0.74,
      rect.height * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
        ).createShader(glossRect),
    );

    // 5. Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x44FFFFFF),
    );
  }

  void _renderParticles(Canvas canvas) {
    if (particles.isEmpty) return;
    final path = _particleBatchPath;
    var hasBatch = false;
    var batchColor = particles.first.color;
    var batchColorKey = particles.first.colorKey;
    var batchAlpha = -1;

    void flushBatch() {
      if (!hasBatch) return;
      _particlePaint.color = _colorWithAlpha(batchColor, batchAlpha);
      canvas.drawPath(path, _particlePaint);
      path.reset();
      hasBatch = false;
    }

    for (final p in particles) {
      final opacity = (1 - p.age / Particle.life).clamp(0.0, 1.0);
      final alpha = (opacity * 255).round();
      if (p.colorKey != batchColorKey || alpha != batchAlpha) {
        flushBatch();
        batchColor = p.color;
        batchColorKey = p.colorKey;
        batchAlpha = alpha;
      }
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p.position, width: 8, height: 8),
          const Radius.circular(3),
        ),
      );
      hasBatch = true;
    }
    flushBatch();
  }

  void _renderScorePopups(Canvas canvas) {
    for (final popup in scorePopups) {
      final progress = (popup.age / ScorePopup.life).clamp(0.0, 1.0);
      final scale = progress < 0.35
          ? ui.lerpDouble(1, 1.28, progress / 0.35)!
          : ui.lerpDouble(1.28, 0.82, (progress - 0.35) / 0.65)!;
      final painter = _scorePainterFor(popup.points);
      final y = popup.worldPosition.dy - worldScrollY - progress * 70;
      canvas.save();
      canvas.translate(popup.worldPosition.dx, y);
      canvas.scale(scale);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  TextPainter _scorePainterFor(int points) {
    final cachedPainter = _scorePopupPainters.remove(points);
    if (cachedPainter != null) {
      _scorePopupPainters[points] = cachedPainter;
      return cachedPainter;
    }

    while (_scorePopupPainters.length >= maxScorePopupPainters) {
      final oldestKey = _scorePopupPainters.keys.first;
      _scorePopupPainters.remove(oldestKey)?.dispose();
    }

    final painter = TextPainter(
      text: TextSpan(
        text: '+$points',
        style: const TextStyle(
          color: BlockDashColors.yellow,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              offset: Offset(0, 2),
              blurRadius: 6,
              color: Color(0x73000000),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _scorePopupPainters[points] = painter;
    return painter;
  }

  void _disposeScorePopupPainters() {
    for (final painter in _scorePopupPainters.values) {
      painter.dispose();
    }
    _scorePopupPainters.clear();
  }

  // ── Hazard Generation ──────────────────────────────────────────────────────

  /// Generates hazard rows down to [minRow].
  /// NEW: 15 % chance of a double hazard (both edges blocked in one row).
  void _generateHazardsUntil(int minRow) {
    while (nextHazardRow >= minRow) {
      final side = _pickHazardSide();
      _addHazard(side == 0 ? 0 : cols - 1, nextHazardRow);

      // NEW: Occasionally block both sides — creates tighter corridors.
      if (random.nextDouble() < doubleHazardChance) {
        final otherCol = side == 0 ? cols - 1 : 0;
        _addHazard(otherCol, nextHazardRow);
      }

      nextHazardRow -= hazardPeriod;
    }
  }

  /// NEW: Generates bonus (gold) blocks down to [minRow].
  /// Bonus blocks only spawn in centre columns (1–3) and never in hazard cells.
  void _generateBonusUntil(int minRow) {
    while (nextBonusRow >= minRow) {
      // Candidate columns are the inner three — never the hazard edge columns.
      final candidates = <int>[];
      for (var col = 1; col <= cols - 2; col++) {
        if (!_hasHazardAt(col, nextBonusRow)) candidates.add(col);
      }
      if (candidates.isNotEmpty) {
        final col = candidates[random.nextInt(candidates.length)];
        _addBonus(col, nextBonusRow);
      }
      nextBonusRow -= bonusPeriod;
    }
  }

  int _pickHazardSide() {
    final int side;
    if (lastHazardSide != null && lastHazardSide == secondLastHazardSide) {
      side = 1 - lastHazardSide!;
    } else if (lastHazardSide != null && random.nextDouble() < 0.3) {
      side = lastHazardSide!;
    } else {
      side = random.nextBool() ? 1 : 0;
    }
    secondLastHazardSide = lastHazardSide;
    lastHazardSide = side;
    return side;
  }

  // ── Spatial data helpers ───────────────────────────────────────────────────

  int _colBit(int col) => 1 << col;

  void _addHazard(int col, int row) {
    hazardsByRow[row] = (hazardsByRow[row] ?? 0) | _colBit(col);
  }

  void _placeTrail(int col, int row) {
    trailsByRow[row] = (trailsByRow[row] ?? 0) | _colBit(col);
  }

  bool _hasHazardAt(int col, int row) {
    return ((hazardsByRow[row] ?? 0) & _colBit(col)) != 0;
  }

  void _placeTrailPath(int fromCol, int fromRow, int colDelta, int steps) {
    var c = fromCol;
    var r = fromRow;
    for (var i = 0; i < steps; i++) {
      c = (c + colDelta).clamp(0, cols - 1);
      r--;
      _placeTrail(c, r);
    }
  }

  // ── NEW: Bonus block helpers ───────────────────────────────────────────────

  void _addBonus(int col, int row) {
    bonusByRow[row] = (bonusByRow[row] ?? 0) | _colBit(col);
  }

  bool _hasBonusAt(int col, int row) {
    return ((bonusByRow[row] ?? 0) & _colBit(col)) != 0;
  }

  void _removeBonusAt(int col, int row) {
    final current = bonusByRow[row] ?? 0;
    final updated = current & ~_colBit(col);
    if (updated == 0) {
      bonusByRow.remove(row);
    } else {
      bonusByRow[row] = updated;
    }
  }

  void _cleanupRowsBehind(int row) {
    final cutoff = row + cleanupBehindRows;
    _removeRowsAfter(trailsByRow, cutoff);
    _removeRowsAfter(hazardsByRow, cutoff);
    _removeRowsAfter(bonusByRow, cutoff); // NEW
  }

  void _removeRowsAfter(SplayTreeMap<int, int> rows, int cutoff) {
    var key = rows.lastKey();
    while (key != null && key > cutoff) {
      rows.remove(key);
      key = rows.lastKey();
    }
  }

  // ── Combo ──────────────────────────────────────────────────────────────────

  void _increaseCombo(String moveKind) {
    comboCount = lastComboMove == moveKind ? comboCount + 1 : 1;
    lastComboMove = moveKind;
    maxCombo = math.max(maxCombo, comboCount);
    comboTimeLeft = comboTimeout;
    comboNotifier.value = comboCount;

    if (comboCount >= 3 && comboSoundCooldown <= 0) {
      comboSoundCooldown = 0.22;
      _playSound('combo.wav');
    }

    // NEW: Enter Fever mode at threshold
    if (comboCount >= feverComboThreshold && !isFeverMode) {
      isFeverMode = true;
      feverNotifier.value = true;
      _triggerScreenFlash(const Color(0xFFFF5500), 0.38);
      _setStatus('🔥  FEVER MODE!');
    }
  }

  /// NEW: Enhanced multiplier table — higher ceiling, fever doubles it.
  int _comboMultiplier() {
    final base = comboCount < 3
        ? 1
        : comboCount < 5
        ? 2
        : comboCount < 8
        ? 3
        : comboCount < 12
        ? 5
        : 8;
    // In fever, every point is worth twice as much
    return isFeverMode ? base * 2 : base;
  }

  void _resetCombo() {
    comboCount = 0;
    lastComboMove = null;
    comboTimeLeft = 0;
    comboNotifier.value = 0;

    // NEW: Exit Fever mode when combo chain breaks
    if (isFeverMode) {
      isFeverMode = false;
      feverPulse = 0;
      feverNotifier.value = false;
      _statusTimer?.cancel();
      statusNotifier.value = '';
    }
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _refillTimer() {
    timerValue = math.min(timerMax, timerValue + timerRefill);
    _syncTimerNotifier(force: true);
  }

  void _syncTimerNotifier({bool force = false}) {
    final ratio = (timerValue / timerMax).clamp(0.0, 1.0);
    final changedEnough = (ratio - lastTimerRatio).abs() >= 0.025;
    if (force || changedEnough || timerNotifyElapsed >= 0.1) {
      lastTimerRatio = ratio;
      timerNotifyElapsed = 0;
      timerNotifier.value = ratio;
    }
  }

  // ── Difficulty ─────────────────────────────────────────────────────────────

  void _updateDifficulty() {
    currentSpeed = math.max(0.16, baseMoveSeconds - (score ~/ 20) * 0.008);
    currentDrain = math.min(maxTimerDrain, baseTimerDrain + (score ~/ 30) * 3);
  }

  // ── Death ──────────────────────────────────────────────────────────────────

  /// [byHazard] — true when the player physically hit a hazard block.
  /// Last Chance only applies to timer exhaustion, not hazard collisions.
  Future<void> _triggerDeath({bool byHazard = false}) async {
    if (isDead) return;

    // NEW: Last Chance save — fires once per game on timer death with active combo
    if (!byHazard && hasLastChance && comboCount >= lastChanceMinCombo) {
      hasLastChance = false;
      lastChanceNotifier.value = false;
      timerValue = lastChanceTimerAmount;
      _syncTimerNotifier(force: true);
      _triggerScreenFlash(BlockDashColors.orange, 0.65);
      _playHapticHeavy();
      _setStatus(
        '⚡  LAST CHANCE!',
        duration: const Duration(milliseconds: 1800),
      );
      return; // Player lives!
    }

    isDead = true;
    shakeTimeLeft = 0.5;
    _playHapticHeavy();
    _playSound('death.wav');
    final isNewBest = score > bestScore;
    if (isNewBest) {
      bestScore = score;
      bestNotifier.value = bestScore;
      await prefs.setInt(_bestScoreKey, bestScore);
      _playSound('new_best.wav');
    }
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      onGameOver(
        GameResult(
          score: score,
          bestScore: bestScore,
          isNewBest: isNewBest,
          maxCombo: maxCombo,
        ),
      );
    });
  }

  // ── NEW: Screen flash & status helpers ─────────────────────────────────────

  /// Triggers a full-screen colour flash that fades out automatically.
  void _triggerScreenFlash(Color color, double alpha) {
    _screenFlashColor = color;
    screenFlashAlpha = alpha.clamp(0.0, 1.0);
  }

  /// Shows a temporary status message in the HUD banner, then clears it.
  void _setStatus(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    statusNotifier.value = message;
    _statusTimer?.cancel();
    _statusTimer = Timer(duration, () {
      if (!isDead) statusNotifier.value = '';
    });
  }

  // ── Particles ──────────────────────────────────────────────────────────────

  int _particleColorKey(Color color) {
    return (_red(color) << 16) | (_green(color) << 8) | _blue(color);
  }

  void _spawnParticles(double x, double y) {
    final overflow = particles.length + particleBurstCount - maxParticles;
    if (overflow > 0) {
      particles.removeRange(0, math.min(overflow, particles.length));
    }
    for (var i = 0; i < particleBurstCount; i++) {
      final angle = math.pi * 2 * i / particleBurstCount;
      final speed = 70 + random.nextDouble() * 65;
      final color = _particleColors[random.nextInt(_particleColors.length)];
      particles.add(
        Particle(
          position: Offset(x, y),
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          color: color,
          colorKey: _particleColorKey(color),
        ),
      );
    }
    particles.sort((a, b) {
      final c = a.colorKey.compareTo(b.colorKey);
      return c != 0 ? c : a.age.compareTo(b.age);
    });
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.age += dt;
      p.position += p.velocity * dt;
    }
    particles.removeWhere((p) => p.age >= Particle.life);
  }

  void _updateScorePopups(double dt) {
    for (final p in scorePopups) {
      p.age += dt;
    }
    scorePopups.removeWhere((p) => p.age >= ScorePopup.life);
  }

  // ── Shake ──────────────────────────────────────────────────────────────────

  void _updateShake(double dt) {
    if (shakeTimeLeft <= 0) {
      shakeOffset = Offset.zero;
      return;
    }
    shakeTimeLeft = math.max(0, shakeTimeLeft - dt);
    final strength = 12 * (shakeTimeLeft / 0.5);
    shakeOffset = Offset(
      (random.nextDouble() * 2 - 1) * strength,
      (random.nextDouble() * 2 - 1) * strength * 0.35,
    );
  }

  // ── Haptics & audio ────────────────────────────────────────────────────────

  void _playHapticSelection() {
    if (_GameSettings.vibrationEnabled(prefs)) HapticFeedback.selectionClick();
  }

  void _playHapticHeavy() {
    if (_GameSettings.vibrationEnabled(prefs)) HapticFeedback.heavyImpact();
  }

  void _playSound(String fileName) {
    if (!_GameSettings.sfxEnabled(prefs)) return;
    if (fileName == 'move.wav') {
      unawaited(_moveSoundPool?.start(volume: 0.65));
      return;
    }
    if (fileName == 'combo.wav') {
      unawaited(_comboSoundPool?.start(volume: 0.65));
      return;
    }
    FlameAudio.play(fileName, volume: 0.65);
  }

  void _disposeAudioPools() {
    final pools = [_moveSoundPool, _comboSoundPool].whereType<AudioPool>();
    _moveSoundPool = null;
    _comboSoundPool = null;
    if (pools.isNotEmpty) {
      unawaited(Future.wait(pools.map((p) => p.dispose())));
    }
  }
}
