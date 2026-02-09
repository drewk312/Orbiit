import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';

import '../providers/discovery_provider.dart';
import '../providers/forge_provider.dart';
import '../models/game_result.dart';

import '../ui/fusion/design_system.dart';
import '../widgets/fusion_app_card.dart';
import '../widgets/cascading_cover_image.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_detail_panel.dart';
import '../widgets/premium_fallback_cover.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Main Nintendo focus: Wii, GameCube, Wii U + all retro platforms grouped
  final List<String> _categories = [
    'All',
    'Wii',
    'GameCube',
    'Wii U',
    'Retro', // GBA, N64, SNES, NES, NDS, Genesis, PS1, PSP, etc.
    'Rom Hacks',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: _categories.length, vsync: this);

    _tabController.addListener(_handleTabSelection);

    // Initial load & State Sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<DiscoveryProvider>();

        // Sync provider state to controller if returning to screen
        if (provider.isSearching && provider.searchQuery.isNotEmpty) {
          _searchController.text = provider.searchQuery;
        }

        provider.loadStoreSections();
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    final category = _categories[_tabController.index];
    final query = _searchController.text;

    if (query.isNotEmpty) {
      context
          .read<DiscoveryProvider>()
          .triggerSearch(query, category: category);
    } else {
      setState(() {}); // Rebuild to filter store sections
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoveryProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. PINNED SEARCH HEADER
          SliverPersistentHeader(
            pinned: true,
            delegate: _StoreHeaderDelegate(
              searchController: _searchController,
              onSearch: (val) {
                final cat = _categories[_tabController.index];
                provider.triggerSearch(val, category: cat);
              },
              tabController: _tabController,
              categories: _categories,
            ),
          ),

          // 2. CONTENT
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: provider.isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            provider.loadingMessage ?? 'Loading...',
                            style: FusionTypography.bodyMedium
                                .copyWith(color: FusionColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : provider.isSearching
                    ? _buildSearchResults(provider)
                    : _buildStoreContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(DiscoveryProvider provider) {
    if (provider.results.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          title: 'No results found',
          subtitle: 'Try a different search term or category',
          icon: Icons.search_off_rounded,
          action: GlowButton(
            label: 'Clear Search',
            icon: Icons.clear,
            onPressed: () {
              _searchController.clear();
              provider.clearSearch();
            },
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 0.7,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = provider.results[index];
            // ⚡ Look up local cover path for instant display
            final localCover = provider.getCoverPath(game.gameId) ??
                provider.getCoverPathByTitle(game.title);

            return FusionAppCard(
              game: game,
              localCover: localCover,
              onInfo: () => _showGameDetails(context, game),
              onArchive: () => _showGameDetails(context, game),
              onForge: () => _forgeGame(context, game),
              onDownload: () => _forgeGame(context, game),
            );
          },
          childCount: provider.results.length,
        ),
      ),
    );
  }

  Widget _buildStoreContent(DiscoveryProvider provider) {
    final category = _categories[_tabController.index];

    // Filter helper - Main Nintendo consoles + Retro category for everything else
    bool match(GameResult r) {
      final p = r.platform.toLowerCase();
      if (category == 'All') return true;
      if (category == 'Wii') return p == 'wii';
      if (category == 'GameCube') return p == 'gamecube' || p == 'gc';
      if (category == 'Wii U') return p == 'wii u' || p == 'wiiu';
      if (category == 'Retro') {
        // Everything that's NOT Wii, GameCube, or Wii U goes into Retro
        return p != 'wii' &&
            p != 'gamecube' &&
            p != 'gc' &&
            p != 'wii u' &&
            p != 'wiiu' &&
            r.provider != 'Rom Hacks' &&
            r.region != 'ROM Hack';
      }
      if (category == 'Rom Hacks') {
        return r.provider == 'Rom Hacks' || r.region == 'ROM Hack';
      }
      return true;
    }

    final featured = provider.popularGames.where(match).take(1).toList();
    final trending =
        provider.popularGames.where(match).skip(1).take(10).toList();
    final newArrivals = provider.latestGames.where(match).take(10).toList();
    final randomPicks = provider.randomGames.where(match).take(10).toList();

    if (trending.isEmpty && newArrivals.isEmpty && randomPicks.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          title: '$category Store Empty',
          subtitle: 'No games found for this platform yet.',
          icon: Icons.videogame_asset_off_rounded,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // FEATURED HERO
        if (featured.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(24),
            child: _StoreHero(
              game: featured.first,
              onTap: () => _showGameDetails(context, featured.first),
              onGet: () => _forgeGame(context, featured.first),
            ),
          ),
        ],

        // SECTIONS
        if (trending.isNotEmpty) ...[
          _StoreSection(
            title: 'Trending Now',
            icon: Icons.local_fire_department_rounded,
            iconColor: FusionColors.nintendoRed,
            games: trending,
            onGameTap: (g) => _showGameDetails(context, g),
            onForgeGame: (g) => _forgeGame(context, g),
          ),
        ],

        if (newArrivals.isNotEmpty) ...[
          _StoreSection(
            title: 'New Arrivals',
            icon: Icons.new_releases_rounded,
            iconColor: FusionColors.wiiBlue,
            games: newArrivals,
            onGameTap: (g) => _showGameDetails(context, g),
            onForgeGame: (g) => _forgeGame(context, g),
          ),
        ],

        if (randomPicks.isNotEmpty) ...[
          _StoreSection(
            title: 'Discover Something New',
            icon: Icons.shuffle_rounded,
            iconColor: FusionColors.gamecube,
            games: randomPicks,
            onGameTap: (g) => _showGameDetails(context, g),
            onForgeGame: (g) => _forgeGame(context, g),
          ),
        ],
      ]),
    );
  }

  // === ACTIONS ===

  void _showGameDetails(BuildContext context, GameResult game) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => GameDetailPanel(
        game: game,
        onDownload: () {
          Navigator.pop(ctx);
          _forgeGame(context, game);
        },
      ),
    );
  }

  Future<void> _forgeGame(BuildContext context, GameResult game) async {
    // 1. Ask for location
    final String? selectedPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FusionColors.bgSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FusionRadius.xl),
            side: BorderSide(color: FusionColors.glassBorder)),
        title:
            Text('Download Location', style: FusionTypography.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where should we save ${game.title}?',
                style: FusionTypography.bodyMedium),
            const SizedBox(height: 16),
            _LocationOption(
              label: 'Use Default Library',
              desc: 'Auto-sorts to correct folder',
              icon: Icons.folder_special,
              onTap: () => Navigator.pop(context, 'DEFAULT'),
            ),
            const SizedBox(height: 8),
            _LocationOption(
              label: 'Select Custom Folder',
              desc: 'Choose specific destination',
              icon: Icons.create_new_folder,
              onTap: () async {
                final result = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: 'Select Destination',
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context, result);
              },
            ),
          ],
        ),
      ),
    );

    if (selectedPath == null) return;

    if (!context.mounted) return;
    final forge = context.read<ForgeProvider>();
    final finalPath = selectedPath == 'DEFAULT' ? null : selectedPath;

    forge.startForge(game, destinationPath: finalPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download: ${game.title}'),
        backgroundColor: FusionColors.wiiBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// === COMPONENTS ===

class _StoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final TabController tabController;
  final List<String> categories;

  _StoreHeaderDelegate({
    required this.searchController,
    required this.onSearch,
    required this.tabController,
    required this.categories,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: FusionColors.bgPrimary.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FusionSearchBar(
                      controller: searchController,
                      onSubmitted: onSearch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 🔄 Refresh Button
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        color: FusionColors.wiiBlue),
                    tooltip: 'Refresh Catalog',
                    onPressed: () {
                      context.read<DiscoveryProvider>().refreshCatalog();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Refreshing catalog...'),
                          backgroundColor: FusionColors.wiiBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                labelColor: FusionColors.wiiBlue,
                unselectedLabelColor: FusionColors.textMuted,
                indicatorColor: FusionColors.wiiBlue,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: FusionTypography.labelLarge,
                tabs: categories.map((c) => Tab(text: c)).toList(),
                tabAlignment: TabAlignment.start,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent =>
      140; // Increased to fit content (Search + Tabs + Padding)
  @override
  double get minExtent => 140;
  @override
  bool shouldRebuild(covariant _StoreHeaderDelegate old) => false;
}

class _FusionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const _FusionSearchBar({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    // Rebuild when text changes to show/hide clear button
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: FusionColors.bgSurface,
            borderRadius: BorderRadius.circular(FusionRadius.full),
            border: Border.all(color: FusionColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search, color: FusionColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: FusionTypography.bodyMedium
                      .copyWith(color: FusionColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    hintStyle: FusionTypography.bodyMedium
                        .copyWith(color: FusionColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: onSubmitted,
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: FusionColors.textMuted,
                  onPressed: () {
                    controller.clear();
                    onSubmitted(''); // Trigger clear
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StoreHero extends StatelessWidget {
  final GameResult game;
  final VoidCallback onTap;
  final VoidCallback onGet;

  const _StoreHero({
    required this.game,
    required this.onTap,
    required this.onGet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FusionRadius.xl),
          color: FusionColors.bgSecondary,
          boxShadow: FusionShadows.lg,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Error Handling
            if (game.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(FusionRadius.xl),
                child: CascadingCoverImage(
                  primaryUrl: game.coverUrl!,
                  gameId: game.gameId,
                  platform: game
                      .platform, // Pass raw platform for correct Libretro mapping
                  title: game.title,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.6),
                  colorBlendMode: BlendMode.darken,
                  fallbackBuilder: (context) => PremiumFallbackCover(
                    title: game.title,
                    platform: game.platform,
                  ),
                ),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FusionRadius.xl),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FusionColors.wiiBlue,
                      borderRadius: BorderRadius.circular(FusionRadius.sm),
                    ),
                    child: Text('FEATURED',
                        style: FusionTypography.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(game.title, style: FusionTypography.displayLarge),
                  const SizedBox(height: 8),
                  Text(game.platform.toUpperCase(),
                      style: FusionTypography.headlineMedium
                          .copyWith(color: FusionColors.textMuted)),
                  const SizedBox(height: 24),
                  GlowButton(
                    label: 'Get Now',
                    icon: Icons.download_rounded,
                    onPressed: onGet,
                    color: FusionColors.wiiBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<GameResult> games;
  final Function(GameResult) onGameTap;
  final Function(GameResult)? onForgeGame;

  const _StoreSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.games,
    required this.onGameTap,
    this.onForgeGame,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: FusionTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260, // Matches card height + padding
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 170,
                child: FusionAppCard(
                  game: games[index],
                  onInfo: () => onGameTap(games[index]),
                  onForge: onForgeGame != null
                      ? () => onForgeGame!(games[index])
                      : null,
                  // Don't set onDownload - it's a fallback when onForge is null
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _LocationOption extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final VoidCallback onTap;

  const _LocationOption({
    required this.label,
    required this.desc,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FusionRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FusionColors.bgTertiary,
          borderRadius: BorderRadius.circular(FusionRadius.md),
          border: Border.all(color: FusionColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: FusionColors.wiiBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: FusionTypography.labelLarge),
                  Text(desc, style: FusionTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
