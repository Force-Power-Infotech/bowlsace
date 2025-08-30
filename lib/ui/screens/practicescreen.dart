import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/meta_drill_group.dart';
import '../../models/drill_group.dart';
import '../../services/drill_service.dart';
import 'meta_drill_group_detail_screen.dart';
import 'drill_group_detail_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final DrillService _drillService = DrillService();
  final TextEditingController _searchController = TextEditingController();

  List<MetaDrillGroup> _metaDrillGroups = [];
  List<DrillGroup> _drillGroups = [];
  List<MetaDrillGroup> _filteredMetaDrillGroups = [];
  List<DrillGroup> _filteredDrillGroups = [];

  bool _isLoading = true;
  String _difficultyFilter = 'All'; // All, Beginner, Intermediate, Advanced
  String _visibilityFilter = 'All'; // All, Public, Private

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final metaDrillGroups = await _drillService.getMetaDrillGroups();
      final drillGroups = await _drillService.getDrillGroups();

      _metaDrillGroups = metaDrillGroups;
      _drillGroups = drillGroups;

      _applyAllFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _applyAllFilters() {
    final query = _searchController.text.trim().toLowerCase();

    List<MetaDrillGroup> meta = _metaDrillGroups.where((g) {
      final q =
          g.name.toLowerCase().contains(query) ||
          g.description.toLowerCase().contains(query);
      // final diffOk = _difficultyFilter == 'All' ||
      //     (g.difficulty ?? '').toLowerCase() == _difficultyFilter.toLowerCase();
      // Meta may not have visibility; treat as always ok.
      return q;
      //  && diffOk;
    }).toList();

    List<DrillGroup> drills = _drillGroups.where((g) {
      final q =
          g.name.toLowerCase().contains(query) ||
          g.description.toLowerCase().contains(query);

      final diffOk = _difficultyFilter == 'All';
      // (g.difficulty).toLowerCase() == _difficultyFilter.toLowerCase();

      final visOk =
          _visibilityFilter == 'All' ||
          (_visibilityFilter == 'Public' ? g.isPublic : !g.isPublic);

      return q && diffOk && visOk;
    }).toList();

    setState(() {
      _filteredMetaDrillGroups = meta;
      _filteredDrillGroups = drills;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    // Debounce for smoother typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _applyAllFilters);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.background;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: bg,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(background: _GradientHeader()),
              titleSpacing: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: _FilterRow(
                  difficulty: _difficultyFilter,
                  visibility: _visibilityFilter,
                  onDifficulty: (v) {
                    setState(() => _difficultyFilter = v);
                    _applyAllFilters();
                  },
                  onVisibility: (v) {
                    setState(() => _visibilityFilter = v);
                    _applyAllFilters();
                  },
                ),
              ),
            ),

            // Meta Drill Groups Section
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Meta Drill Groups',
                count: _filteredMetaDrillGroups.length,
                onViewAll: _filteredMetaDrillGroups.isEmpty
                    ? null
                    : () {
                        // Optional: navigate to a dedicated meta groups page
                      },
              ),
            ),

            if (_isLoading) _MetaSkeleton(),
            if (!_isLoading && _filteredMetaDrillGroups.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No meta drill groups',
                  subtitle:
                      'Try clearing filters or adjusting your search query.',
                ),
              ),
            if (!_isLoading && _filteredMetaDrillGroups.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 210,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filteredMetaDrillGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, i) {
                      final g = _filteredMetaDrillGroups[i];
                      return MetaCard(
                        title: g.name,
                        subtitle: g.description,
                        imageUrl: g.imageUrl,
                        colorSeed: i,
                        isActive: g.isActive,
                        createdAt: g.createdAt,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MetaDrillGroupDetailScreen(id: g.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            // Drill Groups Section
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Drill Groups',
                count: _filteredDrillGroups.length,
                onViewAll: _filteredDrillGroups.isEmpty
                    ? null
                    : () {
                        // Optional: navigate to a dedicated drills page
                      },
              ),
            ),

            if (_isLoading) _DrillSkeleton(),
            if (!_isLoading && _filteredDrillGroups.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.sports_outlined,
                  title: 'No drill groups',
                  subtitle:
                      'Try different filters or refine your search keywords.',
                ),
              ),
            if (!_isLoading && _filteredDrillGroups.isNotEmpty)
              SliverList.separated(
                itemCount: _filteredDrillGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final g = _filteredDrillGroups[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: _DrillTile(
                      group: g,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DrillGroupDetailScreen(id: g.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// ---------- UI Pieces ----------

class _GradientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.primary.withOpacity(0.15),
            c.secondary.withOpacity(0.12),
            c.tertiary.withOpacity(0.08),
          ],
          stops: const [0.2, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sports_cricket, color: c.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice',
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Master your skills with guided drills',
                      style: t.bodySmall?.copyWith(
                        color: c.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Add stats/history button action
                },
                icon: Icon(Icons.insights, color: c.primary),
                tooltip: 'Practice History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search drills or meta groups...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String difficulty;
  final String visibility;
  final ValueChanged<String> onDifficulty;
  final ValueChanged<String> onVisibility;

  const _FilterRow({
    required this.difficulty,
    required this.visibility,
    required this.onDifficulty,
    required this.onVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 4),
                _FilterChip(
                  label: 'All Levels',
                  selected: difficulty == 'All',
                  onSelected: () => onDifficulty('All'),
                  icon: Icons.all_inclusive,
                  accent: c.primary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Beginner',
                  selected: difficulty == 'Beginner',
                  onSelected: () => onDifficulty('Beginner'),
                  icon: Icons.looks_one,
                  accent: c.tertiary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Intermediate',
                  selected: difficulty == 'Intermediate',
                  onSelected: () => onDifficulty('Intermediate'),
                  icon: Icons.looks_two,
                  accent: c.secondary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Advanced',
                  selected: difficulty == 'Advanced',
                  onSelected: () => onDifficulty('Advanced'),
                  icon: Icons.looks_3,
                  accent: c.error,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Visibility filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 4),
                _FilterChip(
                  label: 'All Visibility',
                  selected: visibility == 'All',
                  onSelected: () => onVisibility('All'),
                  icon: Icons.remove_red_eye_outlined,
                  accent: c.primary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Public',
                  selected: visibility == 'Public',
                  onSelected: () => onVisibility('Public'),
                  icon: Icons.public,
                  accent: c.secondary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Private',
                  selected: visibility == 'Private',
                  onSelected: () => onVisibility('Private'),
                  icon: Icons.lock_outline,
                  accent: c.tertiary,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData icon;
  final Color accent;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(0.15)
                : c.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.5)
                  : c.outlineVariant.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? accent : c.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: t.labelMedium?.copyWith(
                  color: selected ? accent : c.onSurface.withOpacity(0.8),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'item' : 'items'} available',
                style: t.bodySmall?.copyWith(
                  color: c.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (onViewAll != null)
            FilledButton.tonal(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

class MetaCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int colorSeed;
  final VoidCallback onTap;
  final bool isActive;
  final DateTime createdAt;

  const MetaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isActive,
    required this.createdAt,
    this.imageUrl,
    this.colorSeed = 0,
  });

  @override
  State<MetaCard> createState() => _MetaCardState();
}

class _MetaCardState extends State<MetaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final t = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple breakpoints
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        final isPhone = w < 360;
        final isTablet = w >= 360 && w < 640;
        final cardWidth = w.isFinite ? w : 320.0;

        final accent = _seedToColor(c, widget.colorSeed);
        final formattedDate = _formatDate(widget.createdAt);

        final titleStyle = (isPhone ? t.titleMedium : t.titleLarge)?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.2,
        );

        final subtitleStyle = t.bodyMedium?.copyWith(
          color: c.onSurface.withOpacity(0.72),
          height: 1.35,
        );

        final statusBg = widget.isActive
            ? c.primaryContainer
            : c.errorContainer;
        final statusFg = widget.isActive
            ? c.onPrimaryContainer
            : c.onErrorContainer;
        final statusIcon = widget.isActive
            ? Icons.check_circle
            : Icons.cancel_outlined;

        return Semantics(
          button: true,
          label: '${widget.title}, ${widget.isActive ? 'Active' : 'Inactive'}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: cardWidth,
            margin: const EdgeInsets.all(2),
            transform: _hovered
                ? (Matrix4.identity()..translate(0.0, -2.0))
                : Matrix4.identity(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: c.shadow.withOpacity(_hovered ? 0.14 : 0.08),
                  blurRadius: _hovered ? 24 : 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: theme.cardColor,
              surfaceTintColor: c.primary,
              elevation: 0,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onHover: (h) => setState(() => _hovered = h),
                hoverColor: c.primary.withOpacity(0.04),
                highlightColor: c.primary.withOpacity(0.06),
                splashColor: c.primary.withOpacity(0.10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image / header
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withOpacity(0.75),
                                  accent.withOpacity(0.28),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: widget.imageUrl == null
                                ? Center(
                                    child: Icon(
                                      Icons.sports_cricket,
                                      size: isPhone ? 40 : 48,
                                      color: c.surface,
                                    ),
                                  )
                                : Ink.image(
                                    image: NetworkImage(widget.imageUrl!),
                                    fit: BoxFit.cover,
                                    child: const SizedBox.expand(),
                                  ),
                          ),
                        ),

                        // Soft gradient overlay for legibility
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.10),
                                    Colors.black.withOpacity(0.00),
                                    Colors.black.withOpacity(0.12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Status pill
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: c.outlineVariant.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusFg),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isActive ? 'Active' : 'Inactive',
                                  style: t.labelSmall?.copyWith(
                                    color: statusFg,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 14 : 16,
                        vertical: isPhone ? 12 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          const SizedBox(height: 6),

                          // Subtitle with safe lines
                          Text(
                            widget.subtitle,
                            maxLines: isPhone ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle,
                          ),
                          const SizedBox(height: 12),

                          // Meta + chevron
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: c.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  formattedDate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelSmall?.copyWith(
                                    color: c.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 150),
                                turns: _hovered ? 0.25 : 0.0,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: accent,
                                ),
                              ),
                            ],
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
      },
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays < 1) {
    return 'Today';
  } else if (difference.inDays < 2) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}

Color _seedToColor(ColorScheme c, int seed) {
  final palette = [
    c.primary,
    c.secondary,
    c.tertiary,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.pink,
    Colors.green,
  ];
  return palette[seed % palette.length];
}

class _DrillTile extends StatelessWidget {
  final DrillGroup group;
  final VoidCallback onTap;

  const _DrillTile({required this.group, required this.onTap});

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      default:
        return 'All Levels';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.outlineVariant.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Image section with gradient overlay
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    group.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: c.primaryContainer.withOpacity(0.3),
                      child: Center(
                        child: Icon(
                          Icons.sports_cricket,
                          color: c.primary,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          c.surface.withOpacity(0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Public/Private badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (group.isPublic
                                  ? c.primaryContainer
                                  : c.secondaryContainer)
                              .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          group.isPublic ? Icons.public : Icons.lock,
                          size: 14,
                          color: group.isPublic
                              ? c.onPrimaryContainer
                              : c.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.isPublic ? 'Public' : 'Private',
                          style: t.labelSmall?.copyWith(
                            color: group.isPublic
                                ? c.onPrimaryContainer
                                : c.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tags
                if (group.tags.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Wrap(
                      spacing: 8,
                      children: group.tags
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: c.surface.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#$tag',
                                style: t.labelSmall?.copyWith(
                                  color: c.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium?.copyWith(
                                color: c.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_forward_ios, size: 16, color: c.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Info chips
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.speed_outlined,
                        label: _getDifficultyLabel(group.difficulty),
                        color: c.primary,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label:
                            '${DateTime.now().difference(group.createdAt).inDays}d ago',
                        color: c.secondary,
                      ),
                    ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Skeletons & Empty ----------

class _MetaSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) => Container(
            width: 280,
            decoration: BoxDecoration(
              color: c.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.outlineVariant.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                _ShimmerBox(
                  height: 140,
                  color: c.primaryContainer.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      _ShimmerBox(
                        width: 160 + (i * 20),
                        height: 24,
                        color: c.primaryContainer.withOpacity(0.2),
                      ),
                      const SizedBox(height: 8),
                      // Description placeholder
                      _ShimmerBox(
                        height: 16,
                        color: c.primaryContainer.withOpacity(0.1),
                      ),
                      const SizedBox(height: 4),
                      _ShimmerBox(
                        width: 140,
                        height: 16,
                        color: c.primaryContainer.withOpacity(0.1),
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

class _DrillSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: c.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.outlineVariant.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Image placeholder
                _ShimmerBox(
                  height: 140,
                  color: c.primaryContainer.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      _ShimmerBox(
                        width: 200 + (i * 30),
                        height: 24,
                        color: c.primaryContainer.withOpacity(0.2),
                      ),
                      const SizedBox(height: 8),
                      // Description placeholders
                      _ShimmerBox(
                        height: 16,
                        color: c.primaryContainer.withOpacity(0.1),
                      ),
                      const SizedBox(height: 4),
                      _ShimmerBox(
                        width: 180,
                        height: 16,
                        color: c.primaryContainer.withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),
                      // Info chips placeholders
                      Row(
                        children: [
                          _ShimmerBox(
                            width: 100,
                            height: 24,
                            color: c.primaryContainer.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          const SizedBox(width: 8),
                          _ShimmerBox(
                            width: 80,
                            height: 24,
                            color: c.primaryContainer.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        childCount: 3,
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final Color color;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.color,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        final shimmerGradient = LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.5), widget.color],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + (2.0 * _a.value), -0.2),
          end: Alignment(1.0 + (2.0 * _a.value), 0.2),
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: shimmerGradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: c.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
