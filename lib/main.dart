import 'dart:math' as math;
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
  // Background blues (Block-Blast bright palette)
  static const bgTop = Color(0xFF1255CC);
  static const bgMid = Color(0xFF1A6AD8);
  static const bgBottom = Color(0xFF3A9AEF);

  // Board / grid
  static const board = Color(0xFF183080);
  static const boardCell = Color(0xFF1C3A96);
  static const boardBorder = Color(0xFF2654BC);

  // Accent / UI
  static const cyan = Color(0xFF00C8F0);
  static const blue = Color(0xFF1E72E8);
  static const yellow = Color(0xFFFFD600);
  static const orange = Color(0xFFFF9800);
  static const red = Color(0xFFEF3030);
  static const green = Color(0xFF43C447);
  static const purple = Color(0xFF9C3FD8);

  // Block colours (glossy set)
  static const blockCyan = Color(0xFF14C8F0);
  static const blockRed = Color(0xFFEF3030);
  static const blockGreen = Color(0xFF30C050);
  static const blockYellow = Color(0xFFFFCC00);
  static const blockPurple = Color(0xFF9B3FE0);
  static const blockOrange = Color(0xFFFF7030);
  static const blockBlue = Color(0xFF2080FF);

  // Pre-baked semi-transparent tones (avoids withValues in hot paths)
  static const shadow18 = Color(0x2D000000);
  static const shadow28 = Color(0x47000000);
  static const shadow45 = Color(0x73000000);
  static const white12 = Color(0x1FFFFFFF);
  static const white30 = Color(0x4DFFFFFF);
  static const white55 = Color(0x8CFFFFFF);
}

// ─── Home Screen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return _BlueScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Decorative floating blocks
              const _HomeBlocks(),
              const SizedBox(height: 12),
              // Title
              const _BlockTitle(text: 'BLOCK\nDASH'),
              const SizedBox(height: 16),
              _SubTag(text: 'STACK · DODGE · WIN'),
              const Spacer(flex: 2),
              // PLAY button
              _BigButton(
                label: 'PLAY',
                icon: Icons.play_arrow_rounded,
                color: BlockDashColors.orange,
                accentColor: const Color(0xFFFFE766),
                tall: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(prefs: prefs),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // SETTINGS button
              _BigButton(
                label: 'SETTINGS',
                icon: Icons.settings_rounded,
                color: BlockDashColors.blue,
                accentColor: BlockDashColors.cyan,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
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
            color: Color.fromARGB(100, color.red, color.green, color.blue),
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
    required this.onPressed,
    this.tall = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color accentColor;
  final VoidCallback onPressed;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final h = tall ? 88.0 : 72.0;
    // Derive a darker shade for the gradient bottom
    final darkColor = Color.fromARGB(
      255,
      (color.red * 0.62).round(),
      (color.green * 0.62).round(),
      (color.blue * 0.62).round(),
    );
    return SizedBox(
      width: double.infinity,
      height: h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accentColor, color, darkColor],
                stops: const [0, 0.45, 1],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(
                    130,
                    color.red,
                    color.green,
                    color.blue,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top gloss strip
                Positioned(
                  top: 4,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: h * 0.30,
                    decoration: BoxDecoration(
                      color: BlockDashColors.white30,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                // Label row
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: tall ? 36 : 30, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: tall ? 32 : 26,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 3),
                              blurRadius: 6,
                              color: Color(0x88000000),
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
    );
  }
}

// ─── Block Title ───────────────────────────────────────────────────────────────
class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.text, this.danger = false});

  final String text;
  final bool danger;

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
        color: danger ? BlockDashColors.red : BlockDashColors.yellow,
        shadows: const [
          Shadow(offset: Offset(0, 5), blurRadius: 0, color: Color(0xAA000000)),
          Shadow(blurRadius: 20, color: Color(0x882080FF)),
        ],
      ),
    );
  }
}

// ─── Blue Scaffold (shared background) ────────────────────────────────────────
class _BlueScaffold extends StatelessWidget {
  const _BlueScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: _BgPainter(),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  // Static cache so the shader isn't recreated every build
  static Rect? _cachedRect;
  static Shader? _cachedShader;

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
    canvas.drawRect(rect, Paint()..shader = _cachedShader);

    // Subtle dot grid
    final dotPaint = Paint()..color = const Color(0x15FFFFFF);
    for (var x = 20.0; x < size.width; x += 40) {
      for (var y = 20.0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedBuilder(
          animation: _game.shakeNotifier,
          builder: (context, child) {
            final offset = _game.shakeNotifier.value;
            return Transform.translate(offset: offset, child: child);
          },
          child: Stack(
            children: [
              // Flame game
              GameWidget(game: _game),
              // Tap zones
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _game.movePlayer(Direction.left),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _game.movePlayer(Direction.right),
                      ),
                    ),
                  ],
                ),
              ),
              // HUD overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      _GameHud(game: _game),
                      const SizedBox(height: 8),
                      _TimerBar(game: _game),
                      const SizedBox(height: 20),
                      _ComboPopup(game: _game),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              // "Game Over" title — styled like reference image
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
              // Score panel
              _ScorePanel(result: result),
              const Spacer(),
              // Play Again
              _BigButton(
                label: 'PLAY AGAIN',
                icon: Icons.replay_rounded,
                color: BlockDashColors.green,
                accentColor: const Color(0xFF80E880),
                tall: true,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(prefs: prefs),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Home
              _BigButton(
                label: 'HOME',
                icon: Icons.home_rounded,
                color: BlockDashColors.blue,
                accentColor: BlockDashColors.cyan,
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
          // Current score
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
          // Best score
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
        // Crown + best score (top-left, like Block Blast)
        ValueListenableBuilder<int>(
          valueListenable: game.bestNotifier,
          builder: (_, best, _) => _CrownScore(value: best),
        ),
        // Current score (centered, large)
        Expanded(
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
        // Spacer to balance crown on the left
        const SizedBox(width: 80),
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

class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.game});

  final BlockDashGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<double>(
        valueListenable: game.timerNotifier,
        builder: (_, value, _) {
          final List<Color> colors;
          if (value <= 0.25) {
            colors = const [BlockDashColors.red, Color(0xFFFF6060)];
          } else if (value <= 0.5) {
            colors = const [BlockDashColors.yellow, BlockDashColors.orange];
          } else {
            colors = const [BlockDashColors.green, Color(0xFF80E880)];
          }
          return Container(
            width: 200,
            height: 14,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0x66183080),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x552654BC), width: 2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(
                        120,
                        colors.first.red,
                        colors.first.green,
                        colors.first.blue,
                      ),
                      blurRadius: value <= 0.25 ? 14 : 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComboPopup extends StatelessWidget {
  const _ComboPopup({required this.game});

  final BlockDashGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.comboNotifier,
      builder: (_, combo, _) {
        if (combo < 3) return const SizedBox(height: 36);
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE566), BlockDashColors.orange],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x88FF9800), blurRadius: 14),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${combo}x COMBO!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(offset: Offset(0, 2), color: Color(0x88000000))],
            ),
          ),
        );
      },
    );
  }
}

// ─── Game Enums / Models ───────────────────────────────────────────────────────
enum Direction { left, right }

class GridPoint {
  const GridPoint(this.col, this.row);
  final int col;
  final int row;
  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.col == col && other.row == row;
  @override
  int get hashCode => Object.hash(col, row);
}

class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
  });
  Offset position;
  final Offset velocity;
  final Color color;
  double age = 0;
  static const life = 0.55;
}

class ScorePopup {
  ScorePopup({required this.position, required this.points});
  Offset position;
  final int points;
  double age = 0;
  static const life = 0.9;
}

class GameResult {
  const GameResult({
    required this.score,
    required this.bestScore,
    required this.isNewBest,
  });
  final int score;
  final int bestScore;
  final bool isNewBest;
}

// ─── Flame Game ────────────────────────────────────────────────────────────────
class BlockDashGame extends FlameGame {
  BlockDashGame({required this.prefs, required this.onGameOver})
    : bestScore = prefs.getInt(_bestScoreKey) ?? 0 {
    bestNotifier.value = bestScore;
  }

  static const _bestScoreKey = 'blockDashBest';
  static const cols = 5;
  static const gap = 4.0;
  static const totalRows = 400;
  static const baseMoveSeconds = 0.24;
  static const hazardPeriod = 5;
  static const hazardOffset = 6;
  static const lookAheadRows = 80;
  static const cleanupBehindRows = 80;
  static const timerMax = 100.0;
  static const baseTimerDrain = 22.0;
  static const maxTimerDrain = 62.0;
  static const timerRefill = 35.0;
  static const comboTimeout = 1.5;
  static const coinsActive = false;

  final SharedPreferences prefs;
  final void Function(GameResult result) onGameOver;
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> bestNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> timerNotifier = ValueNotifier<double>(1);
  final ValueNotifier<int> comboNotifier = ValueNotifier<int>(0);
  final ValueNotifier<Offset> shakeNotifier = ValueNotifier<Offset>(
    Offset.zero,
  );

  final hazards = <GridPoint>{};
  final trails = <GridPoint>{};
  final coins = <GridPoint>{};
  final particles = <Particle>[];
  final scorePopups = <ScorePopup>[];
  final random = math.Random();

  late double cellSize;
  late double rowHeight;
  late double gridWidth;
  late double gridLeft;
  late double worldScrollY;
  late double playerScreenY;
  late int playerCol;
  late int playerRow;
  late int nextHazardRow;
  int? lastHazardSide;
  int? secondLastHazardSide;

  int score = 0;
  int bestScore;
  int comboCount = 0;
  int maxCombo = 0;
  double comboTimeLeft = 0;
  String? lastComboMove;
  double timerValue = timerMax;
  double lastTimerRatio = 1;
  double timerNotifyElapsed = 0;
  double currentSpeed = baseMoveSeconds;
  double currentDrain = baseTimerDrain;
  bool isMoving = false;
  bool isDead = false;
  double moveElapsed = 0;
  double moveDuration = 0;
  double moveStartX = 0;
  double moveStartY = 0;
  double moveEndX = 0;
  double moveEndY = 0;
  double scrollStartY = 0;
  double scrollEndY = 0;
  int pendingCol = 0;
  int pendingRow = 0;
  int pendingSteps = 0;
  bool pendingDeath = false;
  double shakeTimeLeft = 0;

  // ── Pre-baked paints (avoid allocation in hot paths) ──
  final _boardCellPaint = Paint()..color = BlockDashColors.boardCell;
  final _boardBorderPaint = Paint()
    ..color = const Color(0x202654BC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final _trackPaint = Paint()..color = BlockDashColors.board;
  final _trailPaint = Paint()..color = BlockDashColors.blockBlue;

  // Background line paint
  final _bgLinePaint = Paint()
    ..color = const Color(0x0CFFFFFF)
    ..strokeWidth = 1;
  final _trackLinePaint = Paint()
    ..color = const Color(0x142654BC)
    ..strokeWidth = 1;

  @override
  Color backgroundColor() => BlockDashColors.bgTop;

  @override
  Future<void> onLoad() async {
    await FlameAudio.audioCache.loadAll([
      'move.wav',
      'combo.wav',
      'death.wav',
      'new_best.wav',
    ]);
    resetGame();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _computeLayout();
    if (isLoaded) {
      if (!isMoving) playerScreenY = size.y - cellSize - 20;
      worldScrollY = _rowToY(playerRow) - playerScreenY;
    }
  }

  void resetGame() {
    _computeLayout();
    hazards.clear();
    trails.clear();
    coins.clear();
    particles.clear();
    scorePopups.clear();
    playerCol = 2;
    playerRow = totalRows - 1;
    nextHazardRow = totalRows - 1 - hazardOffset;
    lastHazardSide = null;
    secondLastHazardSide = null;
    score = 0;
    comboCount = 0;
    maxCombo = 0;
    comboTimeLeft = 0;
    lastComboMove = null;
    timerValue = timerMax;
    lastTimerRatio = 1;
    timerNotifyElapsed = 0;
    currentSpeed = baseMoveSeconds;
    currentDrain = baseTimerDrain;
    isMoving = false;
    isDead = false;
    playerScreenY = size.y - cellSize - 20;
    worldScrollY = _rowToY(playerRow) - playerScreenY;
    scoreNotifier.value = 0;
    bestNotifier.value = bestScore;
    _syncTimerNotifier(force: true);
    comboNotifier.value = 0;
    shakeNotifier.value = Offset.zero;
    _generateHazardsUntil(0);
    _generateCoinsUntil(0);
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

    _generateHazardsUntil(playerRow - totalSteps - lookAheadRows);
    _generateCoinsUntil(playerRow - totalSteps - lookAheadRows);

    var hitStep = -1;
    var c = playerCol;
    var r = playerRow;
    for (var i = 0; i < totalSteps; i++) {
      c = (c + colDelta).clamp(0, cols - 1);
      r--;
      if (hazards.contains(GridPoint(c, r))) {
        hitStep = i + 1;
        break;
      }
    }

    final steps = hitStep > 0 ? hitStep : totalSteps;
    final destCol = (playerCol + colDelta * steps).clamp(0, cols - 1);
    final destRow = playerRow - steps;
    final duration = math.max(0.16, currentSpeed * steps / totalSteps);

    _increaseCombo(moveKind);
    _playSound('move.wav');
    HapticFeedback.selectionClick();
    _placeTrailPath(playerCol, playerRow, colDelta, steps);
    _spawnParticles(
      _screenX(playerCol) + cellSize / 2,
      playerScreenY + cellSize / 2,
    );
    _refillTimer();

    final destWorldY = _rowToY(destRow);
    final camLine = size.y * 0.50;
    final destScreenNoScroll = destWorldY - worldScrollY;
    final needsScroll = destScreenNoScroll < camLine;

    isMoving = true;
    pendingCol = destCol;
    pendingRow = destRow;
    pendingSteps = steps;
    pendingDeath = hitStep > 0;
    moveElapsed = 0;
    moveDuration = duration;
    moveStartX = _screenX(playerCol);
    moveStartY = playerScreenY;
    moveEndX = _screenX(destCol);
    moveEndY = needsScroll ? camLine : destScreenNoScroll;
    scrollStartY = worldScrollY;
    scrollEndY = needsScroll ? destWorldY - camLine : worldScrollY;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateParticles(dt);
    _updateScorePopups(dt);
    _updateShake(dt);

    if (isDead) return;

    if (comboTimeLeft > 0) {
      comboTimeLeft -= dt;
      if (comboTimeLeft <= 0) _resetCombo();
    }

    timerValue = math.max(0, timerValue - currentDrain * dt);
    timerNotifyElapsed += dt;
    _syncTimerNotifier();
    if (timerValue <= 0) {
      _triggerDeath();
      return;
    }

    if (!isMoving) return;

    moveElapsed += dt;
    final t = (moveElapsed / moveDuration).clamp(0.0, 1.0);
    final eased = _ease(t);
    playerScreenY = ui.lerpDouble(moveStartY, moveEndY, eased)!;
    worldScrollY = ui.lerpDouble(scrollStartY, scrollEndY, eased)!;

    if (t >= 1) {
      isMoving = false;
      playerCol = pendingCol;
      playerRow = pendingRow;
      playerScreenY = moveEndY;
      worldScrollY = scrollEndY;
      _cleanupRowsBehind(playerRow);

      final movePoints = (pendingSteps + 1) * _comboMultiplier();
      score += movePoints;
      scoreNotifier.value = score;
      scorePopups.add(
        ScorePopup(
          position: Offset(moveEndX + cellSize / 2, moveEndY + cellSize / 2),
          points: movePoints,
        ),
      );
      _updateDifficulty();
      if (pendingDeath) _triggerDeath();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBackground(canvas);
    _renderBoard(canvas);
    _renderGridPoints(canvas, trails, _trailPaint);
    _renderHazards(canvas);
    _renderParticles(canvas);
    _renderPlayer(canvas);
    _renderScorePopups(canvas);
  }

  void _computeLayout() {
    final visibleAbove = size.y * 0.50;
    final byHeight = ((visibleAbove - gap * 8) / 7.2).floor();
    final byWidth = ((size.x * 0.96 - gap * (cols + 1)) / cols).floor();
    cellSize = math.max(math.min(byHeight, byWidth), 44).toDouble();
    rowHeight = cellSize + gap;
    gridWidth = cols * (cellSize + gap) + gap;
    gridLeft = ((size.x - gridWidth) / 2).roundToDouble();
  }

  double _cellX(int col) => gap + col * (cellSize + gap);
  double _rowToY(int row) => gap + row * rowHeight;
  double _screenX(int col) => gridLeft + _cellX(col);

  double _ease(double t) {
    if (t < 0.5) return 4 * t * t * t;
    return 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  void _renderBackground(Canvas canvas) {
    final full = Rect.fromLTWH(0, 0, size.x, size.y);
    // Gradient bg
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

    // Sparse dot grid outside the board
    for (var x = 20.0; x < size.x; x += 48) {
      for (var y = 0.0; y < size.y; y += 48) {
        if (x < gridLeft || x > gridLeft + gridWidth) {
          canvas.drawCircle(Offset(x, y), 1.2, _bgLinePaint);
        }
      }
    }

    // Board lane background
    final boardRect = Rect.fromLTWH(gridLeft, 0, gridWidth, size.y);
    canvas.drawRect(boardRect, _trackPaint);

    // Subtle vertical lines inside board lane
    for (var x = gridLeft + 32; x < gridLeft + gridWidth; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _trackLinePaint);
    }
  }

  void _renderBoard(Canvas canvas) {
    final firstRow = math.max(
      0,
      ((worldScrollY - rowHeight) / rowHeight).floor(),
    );
    final lastRow = math.min(
      totalRows - 1,
      ((worldScrollY + size.y + rowHeight) / rowHeight).ceil(),
    );

    for (var row = firstRow; row <= lastRow; row++) {
      final y = _rowToY(row) - worldScrollY;
      for (var col = 0; col < cols; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(gridLeft + _cellX(col), y, cellSize, cellSize),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, _boardCellPaint);
        canvas.drawRRect(rect, _boardBorderPaint);
      }
    }
  }

  void _renderGridPoints(Canvas canvas, Set<GridPoint> points, Paint paint) {
    final firstRow = ((worldScrollY - rowHeight) / rowHeight).floor();
    final lastRow = ((worldScrollY + size.y + rowHeight) / rowHeight).ceil();
    for (final point in points) {
      if (point.row < firstRow || point.row > lastRow) continue;
      _drawBlock(
        canvas,
        Rect.fromLTWH(
          gridLeft + _cellX(point.col),
          _rowToY(point.row) - worldScrollY,
          cellSize,
          cellSize,
        ),
        paint.color,
      );
    }
  }

  void _renderHazards(Canvas canvas) {
    final firstRow = ((worldScrollY - rowHeight) / rowHeight).floor();
    final lastRow = ((worldScrollY + size.y + rowHeight) / rowHeight).ceil();
    for (final point in hazards) {
      if (point.row < firstRow || point.row > lastRow) continue;
      _drawBlock(
        canvas,
        Rect.fromLTWH(
          gridLeft + _cellX(point.col),
          _rowToY(point.row) - worldScrollY,
          cellSize,
          cellSize,
        ),
        BlockDashColors.blockRed,
      );
    }
  }

  void _renderPlayer(Canvas canvas) {
    final t = (moveElapsed / moveDuration).clamp(0.0, 1.0);
    final x = isMoving
        ? ui.lerpDouble(moveStartX, moveEndX, _ease(t))!
        : _screenX(playerCol);
    _drawBlock(
      canvas,
      Rect.fromLTWH(x, playerScreenY, cellSize, cellSize),
      isDead ? BlockDashColors.blockRed : BlockDashColors.blockCyan,
    );
  }

  /// Glossy 3-D block — Block-Blast inspired
  void _drawBlock(Canvas canvas, Rect rect, Color color) {
    final radius = const Radius.circular(10);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // 1. Drop shadow (offset down)
    canvas.drawRRect(
      rrect.shift(const Offset(0, 5)),
      Paint()
        ..color = Color.fromARGB(
          130,
          (color.red * 0.3).round(),
          (color.green * 0.3).round(),
          (color.blue * 0.3).round(),
        ),
    );

    // 2. Bottom-face 3-D depth strip
    final bottomFace = RRect.fromRectAndRadius(
      rect.shift(const Offset(0, 3)),
      radius,
    );
    canvas.drawRRect(
      bottomFace,
      Paint()
        ..color = Color.fromARGB(
          255,
          (color.red * 0.55).round().clamp(0, 255),
          (color.green * 0.55).round().clamp(0, 255),
          (color.blue * 0.55).round().clamp(0, 255),
        ),
    );

    // 3. Main face — gradient (lighter top, slightly darker bottom)
    final lightColor = Color.fromARGB(
      255,
      math.min(255, color.red + 40),
      math.min(255, color.green + 40),
      math.min(255, color.blue + 40),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightColor, color],
        ).createShader(rect),
    );

    // 4. Inner gloss highlight (top-left quadrant)
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

    // 5. Subtle border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x44FFFFFF),
    );
  }

  void _renderParticles(Canvas canvas) {
    final paint = Paint();
    for (final p in particles) {
      final opacity = (1 - p.age / Particle.life).clamp(0.0, 1.0);
      paint.color = Color.fromARGB(
        (opacity * 255).round(),
        p.color.red,
        p.color.green,
        p.color.blue,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p.position, width: 8, height: 8),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _renderScorePopups(Canvas canvas) {
    for (final popup in scorePopups) {
      final progress = (popup.age / ScorePopup.life).clamp(0.0, 1.0);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final scale = progress < 0.35
          ? ui.lerpDouble(1, 1.28, progress / 0.35)!
          : ui.lerpDouble(1.28, 0.82, (progress - 0.35) / 0.65)!;
      final painter = TextPainter(
        text: TextSpan(
          text: '+${popup.points}',
          style: TextStyle(
            color: Color.fromARGB(
              (opacity * 255).round(),
              BlockDashColors.yellow.red,
              BlockDashColors.yellow.green,
              BlockDashColors.yellow.blue,
            ),
            fontSize: 28 * scale,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 6,
                color: Color.fromARGB((0.45 * opacity * 255).round(), 0, 0, 0),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = popup.position.dy - progress * 70;
      painter.paint(
        canvas,
        Offset(popup.position.dx - painter.width / 2, y - painter.height / 2),
      );
    }
  }

  // ── Hazard / coin generation ───────────────────────────────────────────────

  void _generateHazardsUntil(int minRow) {
    while (nextHazardRow >= minRow) {
      final side = _pickHazardSide();
      hazards.add(GridPoint(side == 0 ? 0 : cols - 1, nextHazardRow));
      nextHazardRow -= hazardPeriod;
    }
  }

  void _generateCoinsUntil(int minRow) {
    if (!coinsActive) return;
    minRow;
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

  // ── Trails ─────────────────────────────────────────────────────────────────

  void _placeTrail(int col, int row) => trails.add(GridPoint(col, row));

  void _placeTrailPath(int fromCol, int fromRow, int colDelta, int steps) {
    var c = fromCol;
    var r = fromRow;
    for (var i = 0; i < steps; i++) {
      c = (c + colDelta).clamp(0, cols - 1);
      r--;
      _placeTrail(c, r);
    }
  }

  void _cleanupRowsBehind(int row) {
    final cutoff = row + cleanupBehindRows;
    trails.removeWhere((p) => p.row > cutoff);
    hazards.removeWhere((p) => p.row > cutoff);
    coins.removeWhere((p) => p.row > cutoff);
  }

  // ── Combo ──────────────────────────────────────────────────────────────────

  void _increaseCombo(String moveKind) {
    comboCount = lastComboMove == moveKind ? comboCount + 1 : 1;
    lastComboMove = moveKind;
    maxCombo = math.max(maxCombo, comboCount);
    comboTimeLeft = comboTimeout;
    comboNotifier.value = comboCount;
    if (comboCount >= 3) _playSound('combo.wav');
  }

  int _comboMultiplier() {
    if (comboCount < 3) return 1;
    if (comboCount < 5) return 2;
    if (comboCount < 10) return 3;
    return 5;
  }

  void _resetCombo() {
    comboCount = 0;
    lastComboMove = null;
    comboTimeLeft = 0;
    comboNotifier.value = 0;
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _refillTimer() {
    timerValue = math.min(timerMax, timerValue + timerRefill);
    _syncTimerNotifier(force: true);
  }

  void _syncTimerNotifier({bool force = false}) {
    final ratio = (timerValue / timerMax).clamp(0.0, 1.0);
    final changedEnough = (ratio - lastTimerRatio).abs() >= 0.006;
    if (force || changedEnough || timerNotifyElapsed >= 1 / 30) {
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

  Future<void> _triggerDeath() async {
    if (isDead) return;
    isDead = true;
    shakeTimeLeft = 0.5;
    HapticFeedback.heavyImpact();
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
        GameResult(score: score, bestScore: bestScore, isNewBest: isNewBest),
      );
    });
  }

  // ── Particles ──────────────────────────────────────────────────────────────

  void _spawnParticles(double x, double y) {
    const colors = [
      BlockDashColors.blockRed,
      BlockDashColors.orange,
      BlockDashColors.yellow,
      BlockDashColors.blockGreen,
      BlockDashColors.blockCyan,
      BlockDashColors.blockBlue,
      BlockDashColors.blockPurple,
    ];
    for (var i = 0; i < 12; i++) {
      final angle = math.pi * 2 * i / 12;
      final speed = 70 + random.nextDouble() * 65;
      particles.add(
        Particle(
          position: Offset(x, y),
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          color: colors[random.nextInt(colors.length)],
        ),
      );
    }
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
      if (shakeNotifier.value != Offset.zero) shakeNotifier.value = Offset.zero;
      return;
    }
    shakeTimeLeft = math.max(0, shakeTimeLeft - dt);
    final strength = 12 * (shakeTimeLeft / 0.5);
    shakeNotifier.value = Offset(
      (random.nextDouble() * 2 - 1) * strength,
      (random.nextDouble() * 2 - 1) * strength * 0.35,
    );
  }

  void _playSound(String fileName) => FlameAudio.play(fileName, volume: 0.65);
}
