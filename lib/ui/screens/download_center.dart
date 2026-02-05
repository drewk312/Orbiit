import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/download_service.dart';
import '../../services/navigation_service.dart';
import '../../services/legal_notice_service.dart';
import '../../providers/forge_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../models/game_result.dart';
import '../widgets/cover_art_widget.dart';
import '../fusion_ui/fusion_ui.dart';
import '../widgets/rocket_progress_bar.dart';

const _kStaggerCurve = Curves.easeOutCubic;

/// Download Center
/// Features: animated progress, live speed graph, glass UI, queue management
/// Integrates both DownloadService AND ForgeProvider for complete visibility
class DownloadCenterScreen extends StatefulWidget {
  const DownloadCenterScreen({super.key});

  @override
  State<DownloadCenterScreen> createState() => _DownloadCenterScreenState();
}

class _DownloadCenterScreenState extends State<DownloadCenterScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _heroEnterController;
  late Animation<double> _heroEnterAnimation;
  late AnimationController _listStaggerController;
  Timer? _statsTimer;
  late StreamSubscription<List<DownloadTask>> _queueSubscription;

  // Speed history for mini graph (last 30 samples)
  final List<double> _speedHistory = List.filled(30, 0.0);
  int _speedIndex = 0;

  // Current state from DownloadService
  List<DownloadTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _heroEnterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _heroEnterAnimation = CurvedAnimation(
      parent: _heroEnterController,
      curve: Curves.easeOutCubic,
    );

    _listStaggerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();

    final downloadService = DownloadService();
    _tasks = downloadService.queue;

    // Listen to queue updates from DownloadService
    _queueSubscription = downloadService.queueStream.listen((tasks) {
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
      });
    });

    // Update speed history every second
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final downloadService = DownloadService();
      final currentDownload = downloadService.currentDownload;
      if (currentDownload != null) {
        setState(() {
          _speedHistory[_speedIndex] =
              currentDownload.speedBytesPerSecond.toDouble();
          _speedIndex = (_speedIndex + 1) % 30;
        });
      } else {
        // Check ForgeProvider for active downloads
        final forge = context.read<ForgeProvider>();
        if (forge.isForging && forge.downloadSpeedBps != null) {
          setState(() {
            _speedHistory[_speedIndex] = forge.downloadSpeedBps!;
            _speedIndex = (_speedIndex + 1) % 30;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _heroEnterController.dispose();
    _listStaggerController.dispose();
    _statsTimer?.cancel();
    _queueSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = DownloadService();
    final forge = context.watch<ForgeProvider>();

    // Combine both download sources
    final activeTask = downloadService.currentDownload;
    final forgeActive = forge.isForging ? forge.currentGame : null;
    final queue =
        _tasks.where((t) => t.status == DownloadStatus.pending).toList();
    final forgeQueue = forge.downloadQueue;
    final completed =
        _tasks.where((t) => t.status == DownloadStatus.completed).toList();

    // Determine effective queue count
    final totalQueueCount = queue.length + forgeQueue.length;

    // Determine if there's any active download
    final hasActiveDownload = activeTask != null || forgeActive != null;
    if (hasActiveDownload &&
        _heroEnterController.status != AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _heroEnterController.status != AnimationStatus.forward) {
          _heroEnterController.forward();
        }
      });
    } else if (!hasActiveDownload) {
      _heroEnterController.reset();
    }

    return Container(
      decoration: const BoxDecoration(gradient: UiGradients.space),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(activeTask, forgeActive, totalQueueCount),
          ),

          // Active Download from DownloadService (Hero Card)
          if (activeTask != null)
            SliverToBoxAdapter(
              child: _wrapHeroEntrance(_buildHeroDownloadCard(activeTask)),
            ),

          // Active Download from ForgeProvider (Hero Card)
          if (forgeActive != null && activeTask == null)
            SliverToBoxAdapter(
              child: _wrapHeroEntrance(_buildForgeHeroCard(forge)),
            ),

          // Download Queue Section
          if (forgeQueue.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: SectionHeaderRow(
                  icon: Icons.download_rounded,
                  title: 'DOWNLOAD QUEUE',
                  count: forgeQueue.length,
                  accent: UiColors.amber,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _wrapStaggerItem(
                  _buildForgeQueueItem(forgeQueue[index], index, forge),
                  index,
                ),
                childCount: forgeQueue.length,
              ),
            ),
          ],

          // DownloadService Queue Section
          if (queue.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: SectionHeaderRow(
                  icon: Icons.queue_rounded,
                  title: 'QUEUE',
                  count: queue.length,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _wrapStaggerItem(
                  _buildQueueItem(queue[index], index),
                  index,
                ),
                childCount: queue.length,
              ),
            ),
          ],

          // Completed Section
          if (completed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: SectionHeaderRow(
                  icon: Icons.check_circle_rounded,
                  title: 'COMPLETED',
                  count: completed.length,
                  accent: UiColors.success,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _wrapStaggerItem(
                  _buildCompletedItem(completed[index]),
                  index,
                ),
                childCount: completed.length,
              ),
            ),
          ],

          // Empty State
          if (!hasActiveDownload && totalQueueCount == 0 && completed.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  /// Hero card for active ForgeProvider download
  Widget _buildForgeHeroCard(ForgeProvider forge) {
    final game = forge.currentGame;
    if (game == null) return const SizedBox.shrink();

    // Fetch cached cover path if available
    final discovery = context.read<DiscoveryProvider>();
    final cachedPath = discovery.getCoverPath(game.gameId);

    final progress = forge.progress;
    final speed = forge.formattedDownloadSpeed;
    final eta = forge.formattedEta;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GlassCard(
        borderRadius: UiRadius.xxl,
        glowColor: UiColors.amber,
        enableHover: false,
        padding: const EdgeInsets.all(24),
        blurSigma: 16,
        child: Column(
          children: [
            // Top row: Cover + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover art with glow (Increased Size)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 140, // Increased from 100
                      height: 200, // Increased from 140
                      child: CoverArtWidget(
                        gameId: game.gameId ?? 'XXXX00',
                        platform: game.platform,
                        region: 'US',
                        cachedFilePath: cachedPath,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              forge.statusMessage,
                              style: UiType.labelMedium.copyWith(
                                color: Colors.white,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        game.title,
                        style: UiType.headingLarge.copyWith(fontSize: 20),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Platform + Provider
                      Row(
                        children: [
                          _buildInfoChip(game.platform, Icons.videogame_asset),
                          const SizedBox(width: 8),
                          _buildInfoChip(game.provider, Icons.cloud_download),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress section with Rocket Animation
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: UiType.displaySmall.copyWith(fontSize: 28),
                    ),
                    Text(
                      forge.statusMessage,
                      style: UiType.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RocketProgressBar(
                  progress: progress,
                  color: UiColors.amber,
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fun Fact (Left aligned if space permits)
                Expanded(
                   child: _buildFunFact(context),
                ),
                const SizedBox(width: 16),

                // Speed & ETA (only show when available)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (speed.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.speed,
                              color: UiColors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            speed,
                            style: UiType.headingSmall.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (eta.isNotEmpty) ...[
                      Text(
                        'ETA: $eta',
                        style: UiType.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Pause / Resume Button
                OutlinedButton.icon(
                  onPressed: () {
                     if (forge.isPaused) {
                       forge.resumeForge();
                     } else {
                       forge.pauseForge();
                     }
                  },
                  icon: Icon(
                    forge.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, 
                    color: UiColors.amber,
                  ),
                  label: Text(
                    forge.isPaused ? 'Resume' : 'Pause', 
                    style: const TextStyle(color: UiColors.amber)
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: UiColors.amber),
                  ),
                ),
                const SizedBox(width: 12),
                
                ActionButton(
                  label: 'Cancel',
                  icon: Icons.stop_rounded,
                  outlined: true,
                  outlineColor: UiColors.error,
                  onPressed: () => forge.cancelForge(),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunFact(BuildContext context) {
    // Only show fun fact if less than 90%
    if (context.read<ForgeProvider>().progress > 0.9) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: UiColors.bgSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UiColors.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, color: UiColors.orbitCyan, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _getRandomSpaceFact(), 
              style: TextStyle(color: UiColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRandomSpaceFact() {
     const facts = [
       "Tip: Use Myrient sources for faster downloads.",
       "Did you know? The Wii uses a PowerPC CPU called 'Broadway'.",
       "Fun Fact: 'Dolphin' was the codename for the GameCube.",
       "Space Info: A day on Venus is longer than a year on Venus.",
       "The Wii Remote communicates via Bluetooth.",
     ];
     // Pick based on minute to change occasionally but not flicker
     return facts[DateTime.now().minute % facts.length];
  }

  /// Queue item for ForgeProvider
  Widget _buildForgeQueueItem(GameResult game, int index, ForgeProvider forge) {
    // Fetch cached cover path
    final discovery = context.read<DiscoveryProvider>();
    final cachedPath = discovery.getCoverPath(game.gameId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Queue position
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Cover art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 50,
                    height: 70,
                    child: CoverArtWidget(
                      gameId: game.gameId ?? 'XXXX00',
                      platform: game.platform,
                      region: 'US',
                      cachedFilePath: cachedPath,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.platform} • ${game.provider}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.5)),
                  onPressed: () => forge.removeFromQueueAt(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wrapHeroEntrance(Widget child) {
    return FadeTransition(
      opacity: _heroEnterAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_heroEnterAnimation),
        child: child,
      ),
    );
  }

  Widget _wrapStaggerItem(Widget child, int index) {
    final anim = CurvedAnimation(
      parent: _listStaggerController,
      curve: Interval(
        (index * 0.06).clamp(0.0, 0.94),
        1.0,
        curve: _kStaggerCurve,
      ),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  Widget _buildHeader(
      DownloadTask? activeTask, GameResult? forgeActive, int queueCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Animated download icon
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      UiColors.cyan
                          .withValues(alpha: 0.3 + _glowController.value * 0.2),
                      UiColors.indigo
                          .withValues(alpha: 0.3 + _glowController.value * 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: UiColors.cyan
                          .withValues(alpha: 0.3 * _glowController.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  activeTask != null
                      ? Icons.downloading
                      : Icons.cloud_download_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 20),

          // Title and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DOWNLOAD CENTER',
                    style: UiType.headingLarge.copyWith(letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(
                  (activeTask != null || forgeActive != null)
                      ? '1 Active • $queueCount in Queue'
                      : queueCount > 0
                          ? '$queueCount in Queue'
                          : 'Ready to download',
                  style: TextStyle(
                    color: UiColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Queue indicator
          if (queueCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: UiColors.cyan.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: UiColors.cyan.withValues(alpha: 0.40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.queue, color: UiColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$queueCount',
                    style: UiType.labelLarge.copyWith(color: UiColors.cyan),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Hero card for active download
  Widget _buildHeroDownloadCard(DownloadTask task) {
    final progress = task.progress;
    final speed = task.speedFormatted;
    final eta = task.timeRemaining;
    final downloaded = task.formattedDownloaded;
    final total = task.formattedSize;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GlassCard(
        borderRadius: UiRadius.xxl,
        glowColor: UiColors.cyan,
        enableHover: false,
        padding: const EdgeInsets.all(20),
        blurSigma: 16,
        child: Column(
          children: [
            // Top row: Cover + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover art with glow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      height: 140,
                      child: CoverArtWidget(
                        gameId: task.gameId ?? 'XXXX00',
                        platform: task.platform ?? 'Wii',
                        region: 'US',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: UiGradients.cyan,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'DOWNLOADING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        task.title,
                        style: UiType.headingLarge.copyWith(fontSize: 20),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Platform + Format
                      Row(
                        children: [
                          _buildInfoChip(
                              task.platform ?? 'Wii', Icons.videogame_asset),
                          const SizedBox(width: 8),
                          _buildInfoChip('.ISO', Icons.album),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress section
            _buildProgressBar(progress),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  'PROGRESS',
                  Icons.pie_chart_outline,
                ),
                _buildStatBox(
                  speed,
                  'SPEED',
                  Icons.speed,
                ),
                _buildStatBox(
                  eta,
                  'ETA',
                  Icons.timer_outlined,
                ),
                _buildStatBox(
                  '$downloaded / $total',
                  'SIZE',
                  Icons.storage,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mini speed graph
            _buildSpeedGraph(),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'PAUSE',
                    Icons.pause_rounded,
                    UiColors.amber,
                    () {
                      DownloadService().pauseAll();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'CANCEL',
                    Icons.close_rounded,
                    UiColors.error,
                    () {
                      final downloadService = DownloadService();
                      downloadService.cancelDownload(task.id);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, {Color? color}) {
    final baseColor = color ?? Colors.cyan;
    final barHeight = 14.0;
    final radius = barHeight / 2;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = (constraints.maxWidth * progress)
                .clamp(0.0, constraints.maxWidth);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Track
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
                // Fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  height: barHeight,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: color != null
                          ? [
                              color.withValues(alpha: 0.85),
                              color,
                              color.withValues(alpha: 0.85)
                            ]
                          : const [
                              Color(0xFF00D4FF),
                              Color(0xFF0099FF),
                              Color(0xFF7B2FFF),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                // Moving shimmer overlay on fill
                if (fillWidth > 40)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final shimmerLeft =
                          (fillWidth - 40) * _pulseController.value;
                      return Positioned(
                        left: shimmerLeft.clamp(0.0, fillWidth - 40),
                        child: IgnorePointer(
                          child: Container(
                            width: 40,
                            height: barHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.18),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Leading edge glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Positioned(
                      left: fillWidth - 16,
                      child: Container(
                        width: 24,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(
                                  alpha: 0.25 *
                                      (0.6 + 0.4 * _pulseController.value)),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpeedGraph({Color? accent}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (accent ?? UiColors.cyan).withValues(alpha: 0.12),
        ),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 50),
        painter:
            _SpeedGraphPainter(_speedHistory, accent: accent ?? UiColors.cyan),
      ),
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: UiColors.cyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: UiColors.cyan.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: UiColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: UiColors.cyan, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: UiType.labelLarge.copyWith(
              color: UiColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: UiType.caption.copyWith(
              color: UiColors.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionButton(
      label: label.toLowerCase() == 'cancel' ? 'Cancel' : 'Pause',
      icon: icon,
      outlined: true,
      outlineColor: color,
      onPressed: onTap,
    );
  }

  Widget _buildQueueItem(DownloadTask task, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        borderRadius: UiRadius.xl,
        enableHover: true,
        blurSigma: 12,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: UiColors.cyan.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: UiColors.cyan.withValues(alpha: 0.26)),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: UiType.labelMedium.copyWith(color: UiColors.cyan),
                ),
              ),
            ),
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 64,
                child: CoverArtWidget(
                  gameId: task.gameId ?? 'XXXX00',
                  platform: task.platform ?? 'Wii',
                  region: 'US',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: UiType.headingSmall.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.formattedSize,
                    style: UiType.bodySmall,
                  ),
                ],
              ),
            ),
            ActionButton(
              label: 'Remove',
              icon: Icons.close_rounded,
              outlined: true,
              outlineColor: UiColors.textSecondary,
              onPressed: () => DownloadService().cancelDownload(task.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedItem(DownloadTask task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        borderRadius: UiRadius.xl,
        glowColor: UiColors.success,
        enableHover: true,
        blurSigma: 12,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: UiColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: UiColors.success.withValues(alpha: 0.26)),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: UiColors.success,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 64,
                child: CoverArtWidget(
                  gameId: task.gameId ?? 'XXXX00',
                  platform: task.platform ?? 'Wii',
                  region: 'US',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: UiType.headingSmall.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 14,
                          color: UiColors.success.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text(
                        'Ready',
                        style: UiType.bodySmall.copyWith(
                          color: UiColors.success.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ActionButton(
              label: 'Open',
              icon: Icons.folder_open_rounded,
              outlined: true,
              outlineColor: UiColors.success,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Orb with simple glow ring (no SweepGradient to avoid paint assertion)
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: UiColors.cyan.withValues(
                              alpha: 0.25 + 0.15 * _glowController.value),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: UiColors.cyan.withValues(
                                alpha: 0.15 + 0.1 * _glowController.value),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: UiColors.indigo.withValues(
                                alpha: 0.08 + 0.05 * _glowController.value),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const LoadingOrb(color: UiColors.cyan, size: 72),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Your downloads live here',
              style: UiType.headingLarge.copyWith(
                fontSize: 26,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Add games from Discovery or your library. Progress and speed show up here.',
              style: UiType.bodyMedium.copyWith(
                color: UiColors.textSecondary.withValues(alpha: 0.95),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ActionButton(
                  label: 'Explore Discovery',
                  icon: Icons.explore_rounded,
                  gradient: UiGradients.cyan,
                  onPressed: () async {
                    final accepted =
                        await LegalNoticeService.showLegalNotice(context);
                    if (accepted) {
                      NavigationService().goToStore();
                    }
                  },
                ),
                ActionButton(
                  label: 'Library',
                  icon: Icons.folder_rounded,
                  outlined: true,
                  outlineColor: UiColors.indigo,
                  onPressed: () => NavigationService().goToLibrary(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Speed graph painter
class _SpeedGraphPainter extends CustomPainter {
  final List<double> speedHistory;
  final Color accent;

  _SpeedGraphPainter(this.speedHistory, {Color? accent})
      : accent = accent ?? UiColors.cyan;

  @override
  void paint(Canvas canvas, Size size) {
    if (speedHistory.isEmpty) return;

    final maxSpeed = speedHistory.reduce((a, b) => a > b ? a : b);
    if (maxSpeed == 0) return;

    final paint = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.35),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final segmentWidth = size.width / (speedHistory.length - 1);

    for (int i = 0; i < speedHistory.length; i++) {
      final x = i * segmentWidth;
      final y = size.height - (speedHistory[i] / maxSpeed * size.height * 0.8);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.speedHistory != speedHistory;
}
