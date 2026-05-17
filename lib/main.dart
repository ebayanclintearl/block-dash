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
        scaffoldBackgroundColor: BlockDashColors.midnight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BlockDashColors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(prefs: prefs),
    );
  }
}

class BlockDashColors {
  static const midnight = Color(0xFF020A27);
  static const panel = Color(0xFF0A33B8);
  static const panelDark = Color(0xFF061756);
  static const cyan = Color(0xFF28D8F4);
  static const blue = Color(0xFF1D60F0);
  static const yellow = Color(0xFFFFD83A);
  static const orange = Color(0xFFFF9F13);
  static const red = Color(0xFFFF5147);
  static const green = Color(0xFF2EE35B);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return NeonScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Stack(
            children: [
              const FloatingBlock(
                alignment: Alignment(-0.86, -0.78),
                red: true,
              ),
              const FloatingBlock(alignment: Alignment(0.82, 0.78)),
              const FloatingBlock(alignment: Alignment(-0.82, 0.84), red: true),
              Column(
                children: [
                  const Spacer(flex: 2),
                  const BlockTitle(text: 'BLOCK\nDASH'),
                  const SizedBox(height: 20),
                  NeonTag(text: 'STACK, DODGE, AND WIN!'),
                  const Spacer(flex: 2),
                  ArcadeButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    color: BlockDashColors.orange,
                    tall: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(prefs: prefs),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SquareMenuButton(
                          label: 'SETTINGS',
                          icon: Icons.settings_rounded,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings placeholder'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingBlock extends StatelessWidget {
  const FloatingBlock({super.key, required this.alignment, this.red = false});

  final Alignment alignment;
  final bool red;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: red ? -0.28 : 0.24,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: red ? BlockDashColors.red : BlockDashColors.cyan,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (red ? BlockDashColors.red : BlockDashColors.cyan)
                    .withValues(alpha: 0.48),
                blurRadius: 20,
              ),
              const BoxShadow(
                color: Color(0xAA001343),
                blurRadius: 10,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeonTag extends StatelessWidget {
  const NeonTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF082680),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BlockDashColors.blue, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x6628D8F4), blurRadius: 14)],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          shadows: [Shadow(offset: Offset(0, 3), color: Color(0xAA001343))],
        ),
      ),
    );
  }
}

class SquareMenuButton extends StatelessWidget {
  const SquareMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: BlockDashColors.panel,
          foregroundColor: Colors.white,
          elevation: 12,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: BlockDashColors.cyan, width: 3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58, color: BlockDashColors.cyan),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(offset: Offset(0, 3), color: Color(0xAA001343)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              GameWidget(game: _game),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      _GameHud(game: _game),
                      const SizedBox(height: 10),
                      _TimerBar(game: _game),
                      const SizedBox(height: 26),
                      _ComboPopup(game: _game),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: 42 + MediaQuery.paddingOf(context).bottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ControlButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => _game.movePlayer(Direction.left),
                    ),
                    ControlButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: () => _game.movePlayer(Direction.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key, required this.prefs, required this.result});

  final SharedPreferences prefs;
  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return NeonScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Stack(
            children: [
              const FloatingBlock(
                alignment: Alignment(-0.86, -0.78),
                red: true,
              ),
              const FloatingBlock(alignment: Alignment(0.82, 0.74)),
              Column(
                children: [
                  const Spacer(),
                  const BlockTitle(text: 'GAME\nOVER', danger: true),
                  const SizedBox(height: 22),
                  NeonPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScoreLine(label: 'SCORE', value: result.score),
                        const Divider(height: 30, color: Color(0x4428D8F4)),
                        ScoreLine(label: 'BEST SCORE', value: result.bestScore),
                        if (result.isNewBest) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'NEW HIGH SCORE!',
                            style: TextStyle(
                              color: BlockDashColors.yellow,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  ArcadeButton(
                    label: 'PLAY AGAIN',
                    icon: Icons.replay_rounded,
                    color: BlockDashColors.orange,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(prefs: prefs),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  ArcadeButton(
                    label: 'HOME',
                    icon: Icons.home_rounded,
                    color: BlockDashColors.blue,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => HomeScreen(prefs: prefs),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeonScaffold extends StatelessWidget {
  const NeonScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: GridBackgroundPainter(),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class BlockTitle extends StatelessWidget {
  const BlockTitle({super.key, required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final fontSize = (shortest * 0.18).clamp(52.0, 86.0);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          height: 0.88,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: danger ? BlockDashColors.red : BlockDashColors.yellow,
          shadows: const [
            Shadow(offset: Offset(0, 5), color: Color(0xAA001343)),
            Shadow(blurRadius: 18, color: BlockDashColors.cyan),
          ],
        ),
      ),
    );
  }
}

class ArcadeButton extends StatelessWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tall = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: tall ? 92 : 76,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: color == BlockDashColors.orange
                    ? const [
                        Color(0xFFFFE564),
                        Color(0xFFFFBA1E),
                        Color(0xFFE86900),
                      ]
                    : const [
                        Color(0xFF1B73FF),
                        BlockDashColors.blue,
                        Color(0xFF0B2B92),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color == BlockDashColors.orange
                    ? const Color(0xFFFFE985)
                    : BlockDashColors.cyan,
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA001343),
                  offset: Offset(0, 9),
                  blurRadius: 18,
                ),
                BoxShadow(color: Color(0x7728D8F4), blurRadius: 22),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 4),
                            color: Color(0xAA8A3600),
                          ),
                        ],
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

class NeonPanel extends StatelessWidget {
  const NeonPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: BlockDashColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BlockDashColors.cyan, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x7728D8F4), blurRadius: 22, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

class ScoreLine extends StatelessWidget {
  const ScoreLine({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(
            color: BlockDashColors.yellow,
            fontSize: 60,
            height: 1,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(offset: Offset(0, 4), color: Color(0xAA5B2C00))],
          ),
        ),
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  const ControlButton({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).shortestSide.clamp(64.0, 82.0);
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFD94D),
                  BlockDashColors.orange,
                  Color(0xFFE35C11),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE985), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6600145A),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Icon(icon, size: size * 0.62, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _GameHud extends StatelessWidget {
  const _GameHud({required this.game});

  final BlockDashGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: BlockDashColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xAA74A4FF), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.scoreNotifier,
              builder: (_, score, _) =>
                  HudStat(label: 'SCORE', value: score, highlight: true),
            ),
            const SizedBox(width: 24),
            ValueListenableBuilder<int>(
              valueListenable: game.bestNotifier,
              builder: (_, best, _) => HudStat(label: 'BEST', value: best),
            ),
          ],
        ),
      ),
    );
  }
}

class HudStat extends StatelessWidget {
  const HudStat({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: highlight ? BlockDashColors.yellow : Colors.white,
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
    return ValueListenableBuilder<double>(
      valueListenable: game.timerNotifier,
      builder: (_, value, _) {
        final colors = value <= 0.25
            ? const [BlockDashColors.red, Color(0xFFEE261E)]
            : value <= 0.5
            ? const [BlockDashColors.yellow, BlockDashColors.orange]
            : const [BlockDashColors.green, BlockDashColors.yellow];
        return Container(
          width: 200,
          height: 12,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0x990B1C7A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x9974A4FF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.6),
                    blurRadius: value <= 0.25 ? 18 : 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        if (combo < 3) return const SizedBox(height: 38);
        return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [BlockDashColors.yellow, BlockDashColors.orange],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Color(0xAAFF8C00), blurRadius: 15),
              BoxShadow(color: Color(0xAA001343), offset: Offset(0, 5)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${combo}x COMBO!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(offset: Offset(0, 2), color: Color(0x99000000))],
            ),
          ),
        );
      },
    );
  }
}

enum Direction { left, right }

class GridPoint {
  const GridPoint(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) {
    return other is GridPoint && other.col == col && other.row == row;
  }

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

class BlockDashGame extends FlameGame {
  BlockDashGame({required this.prefs, required this.onGameOver})
    : bestScore = prefs.getInt(_bestScoreKey) ?? 0 {
    bestNotifier.value = bestScore;
  }

  static const _bestScoreKey = 'blockDashBest';
  static const cols = 5;
  static const gap = 4.0;
  static const totalRows = 400;
  static const baseMoveSeconds = 0.20;
  static const hazardPeriod = 5;
  static const hazardOffset = 6;
  static const lookAheadRows = 80;
  static const cleanupBehindRows = 80;
  static const timerMax = 100.0;
  static const baseTimerDrain = 22.0;
  static const maxTimerDrain = 62.0;
  static const timerRefill = 35.0;
  static const comboTimeout = 1.5;

  // Coins are intentionally dormant: retained as data-path capacity only.
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

  final boardPaint = Paint()..color = const Color(0xFF101C4A);
  final trackPaint = Paint()..color = const Color(0xFF0B1647);
  final trailPaint = Paint()..color = BlockDashColors.blue;
  final playerPaint = Paint()..color = const Color(0xFF23C7EB);
  final hazardPaint = Paint()..color = BlockDashColors.red;

  @override
  Color backgroundColor() => BlockDashColors.midnight;

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
    currentSpeed = baseMoveSeconds;
    currentDrain = baseTimerDrain;
    isMoving = false;
    isDead = false;
    playerScreenY = size.y - cellSize - 20;
    worldScrollY = _rowToY(playerRow) - playerScreenY;
    scoreNotifier.value = 0;
    bestNotifier.value = bestScore;
    timerNotifier.value = 1;
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
    final duration = currentSpeed * steps / totalSteps;

    _increaseCombo(moveKind);
    _playSound('move.wav');
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
    timerNotifier.value = timerValue / timerMax;
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
    _renderGridPoints(canvas, trails, trailPaint);
    _renderGridPoints(canvas, hazards, hazardPaint);
    _renderParticles(canvas);
    _renderPlayer(canvas);
    _renderScorePopups(canvas);
  }

  void _computeLayout() {
    final visibleAbove = size.y * 0.50;
    final byHeight = (visibleAbove / 22).floor() - gap;
    final byWidth = ((size.x * 0.86 - gap * (cols + 1)) / cols).floor();
    cellSize = math.max(math.min(byHeight, byWidth), 30).toDouble();
    rowHeight = cellSize + gap;
    gridWidth = cols * (cellSize + gap) + gap;
    gridLeft = ((size.x - gridWidth) / 2).roundToDouble();
  }

  double _cellX(int col) => gap + col * (cellSize + gap);
  double _rowToY(int row) => gap + row * rowHeight;
  double _screenX(int col) => gridLeft + _cellX(col);

  double _ease(double t) => 1 - math.pow(1 - t, 3).toDouble();

  void _renderBackground(Canvas canvas) {
    final full = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3422B8), Color(0xFF2F57D4), Color(0xFF2368DF)],
        ).createShader(full),
    );

    final bgLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.x; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), bgLinePaint);
    }
    for (var y = 0.0; y < size.y; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), bgLinePaint);
    }

    final rect = Rect.fromLTWH(gridLeft, 0, gridWidth, size.y);
    canvas.drawRect(
      rect.inflate(4),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawRect(rect, trackPaint);
    canvas.drawRect(
      rect.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF263777),
    );

    final linePaint = Paint()
      ..color = const Color(0x223F72EB)
      ..strokeWidth = 1;
    for (var x = gridLeft; x < gridLeft + gridWidth; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), linePaint);
    }
    for (var y = 0.0; y < size.y; y += 64) {
      canvas.drawLine(
        Offset(gridLeft, y),
        Offset(gridLeft + gridWidth, y),
        linePaint,
      );
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
    final border = Paint()
      ..color = const Color(0x1474A4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var row = firstRow; row <= lastRow; row++) {
      final y = _rowToY(row) - worldScrollY;
      for (var col = 0; col < cols; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(gridLeft + _cellX(col), y, cellSize, cellSize),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, boardPaint);
        canvas.drawRRect(rect, border);
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

  void _renderPlayer(Canvas canvas) {
    final x = isMoving
        ? ui.lerpDouble(
            moveStartX,
            moveEndX,
            _ease((moveElapsed / moveDuration).clamp(0, 1)),
          )!
        : _screenX(playerCol);
    _drawBlock(
      canvas,
      Rect.fromLTWH(x, playerScreenY, cellSize, cellSize),
      isDead ? BlockDashColors.red : playerPaint.color,
    );
  }

  void _drawBlock(Canvas canvas, Rect rect, Color color) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      rrect.shift(const Offset(0, 6)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.24)!,
          color,
          Color.lerp(color, Colors.black, 0.22)!,
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Color.lerp(color, Colors.white, 0.52)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(cellSize * 0.18),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawLine(
      rect.bottomLeft - const Offset(0, 2),
      rect.bottomRight - const Offset(0, 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26)
        ..strokeWidth = 5,
    );
  }

  void _renderParticles(Canvas canvas) {
    for (final particle in particles) {
      final opacity = (1 - particle.age / Particle.life).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: particle.position, width: 8, height: 8),
          const Radius.circular(2),
        ),
        Paint()..color = particle.color.withValues(alpha: opacity),
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
            color: BlockDashColors.yellow.withValues(alpha: opacity),
            fontSize: 28 * scale,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.45 * opacity),
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

  void _generateHazardsUntil(int minRow) {
    while (nextHazardRow >= minRow) {
      final side = _pickHazardSide();
      hazards.add(GridPoint(side == 0 ? 0 : cols - 1, nextHazardRow));
      nextHazardRow -= hazardPeriod;
    }
  }

  void _generateCoinsUntil(int minRow) {
    if (!coinsActive) return;
    // Reserved for later reactivation. Kept inactive by request.
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

  void _placeTrail(int col, int row) {
    trails.add(GridPoint(col, row));
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

  void _cleanupRowsBehind(int row) {
    final cutoff = row + cleanupBehindRows;
    trails.removeWhere((point) => point.row > cutoff);
    hazards.removeWhere((point) => point.row > cutoff);
    coins.removeWhere((point) => point.row > cutoff);
  }

  void _increaseCombo(String moveKind) {
    if (lastComboMove == moveKind) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    lastComboMove = moveKind;
    maxCombo = math.max(maxCombo, comboCount);
    comboTimeLeft = comboTimeout;
    comboNotifier.value = comboCount;
    if (comboCount >= 3) {
      _playSound('combo.wav');
    }
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

  void _refillTimer() {
    timerValue = math.min(timerMax, timerValue + timerRefill);
    timerNotifier.value = timerValue / timerMax;
  }

  void _updateDifficulty() {
    currentSpeed = math.max(0.12, baseMoveSeconds - (score ~/ 20) * 0.01);
    currentDrain = math.min(maxTimerDrain, baseTimerDrain + (score ~/ 30) * 3);
  }

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

  void _spawnParticles(double x, double y) {
    const colors = [
      BlockDashColors.red,
      BlockDashColors.orange,
      BlockDashColors.yellow,
      BlockDashColors.green,
      BlockDashColors.cyan,
      BlockDashColors.blue,
    ];
    for (var i = 0; i < 10; i++) {
      final angle = math.pi * 2 * i / 10;
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
    for (final particle in particles) {
      particle.age += dt;
      particle.position += particle.velocity * dt;
    }
    particles.removeWhere((particle) => particle.age >= Particle.life);
  }

  void _updateScorePopups(double dt) {
    for (final popup in scorePopups) {
      popup.age += dt;
    }
    scorePopups.removeWhere((popup) => popup.age >= ScorePopup.life);
  }

  void _updateShake(double dt) {
    if (shakeTimeLeft <= 0) {
      if (shakeNotifier.value != Offset.zero) {
        shakeNotifier.value = Offset.zero;
      }
      return;
    }

    shakeTimeLeft = math.max(0, shakeTimeLeft - dt);
    final strength = 12 * (shakeTimeLeft / 0.5);
    shakeNotifier.value = Offset(
      (random.nextDouble() * 2 - 1) * strength,
      (random.nextDouble() * 2 - 1) * strength * 0.35,
    );
  }

  void _playSound(String fileName) {
    FlameAudio.play(fileName, volume: 0.65);
  }
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF061044), Color(0xFF0A2B88), Color(0xFF0B49BE)],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 58) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
