import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/album_grid.dart';
import '../../../shared/widgets/cover_image.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/pressable.dart';
import '../../album/presentation/album_screen.dart';
import '../data/home_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRepository _repo = HomeRepository(AppScope.read(context).api);
  HomeData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.load();
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(String albumId) async {
    await openAlbum(context, albumId);
    _load(); // ratings may have changed
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'LATE NIGHT';
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 18) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null && _error != null) return ErrorView(message: _error!, onRetry: _load);
    if (data == null) return const EqLoader();
    final username = AppScope.of(context).username;
    final fresh = data.songs == 0 && data.albums == 0;

    return RefreshIndicator(
      color: CrColors.gold,
      backgroundColor: CrColors.surface2,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            CrSpace.xl, MediaQuery.paddingOf(context).top + CrSpace.xl, CrSpace.xl, CrSpace.xxxl),
        children: [
          Text(_greeting, style: CrText.eyebrow()),
          const SizedBox(height: CrSpace.md),
          Text.rich(TextSpan(style: CrText.display(36), children: [
            TextSpan(text: fresh ? 'Let\'s rate your ' : 'What are we rating '),
            TextSpan(
              text: fresh ? 'first album' : 'today',
              style: CrText.display(36, weight: FontWeight.w400, style: FontStyle.italic, color: CrColors.gold2),
            ),
            TextSpan(text: ', $username${fresh ? '.' : '?'}'),
          ])),
          const SizedBox(height: CrSpace.xl),
          Pressable(
            onTap: widget.onOpenSearch,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: CrSpace.lg),
              decoration: BoxDecoration(
                color: CrColors.surface,
                borderRadius: BorderRadius.circular(CrRadius.pill),
                border: Border.all(color: CrColors.line2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: CrColors.muted),
                  const SizedBox(width: CrSpace.md),
                  Text('Search an album to rate…', style: CrText.body(color: CrColors.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: CrSpace.lg),
          Wrap(
            spacing: CrSpace.sm,
            runSpacing: CrSpace.sm,
            children: [
              _StatChip(value: data.songs, label: 'songs rated'),
              _StatChip(value: data.albums, label: 'albums'),
              _StatChip(value: data.artists, label: 'artists'),
            ],
          ),
          if (data.inProgress.isNotEmpty) ...[
            const SectionHeader(eyebrow: 'Pick up where you left off', title: 'Continue rating'),
            for (final album in data.inProgress)
              Padding(
                padding: const EdgeInsets.only(bottom: CrSpace.md),
                child: _ProgressCard(album: album, onTap: () => _open(album.id)),
              ),
          ],
          const SectionHeader(eyebrow: 'Trending', title: 'Hot on Crescendo'),
          if (data.trending.isEmpty)
            Text('Nothing trending yet. Your ratings could start it.',
                style: CrText.body(size: 15, color: CrColors.muted))
          else
            AlbumGrid(albums: data.trending, onOpen: (a) => _open(a.id)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CrColors.surface2,
        borderRadius: BorderRadius.circular(CrRadius.pill),
        border: Border.all(color: CrColors.line),
      ),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$value ', style: CrText.score(size: 14)),
        TextSpan(text: label, style: CrText.body(size: 14, color: CrColors.text2)),
      ])),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.album, required this.onTap});

  final InProgressAlbum album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(CrSpace.md),
        decoration: BoxDecoration(
          color: CrColors.surface,
          borderRadius: BorderRadius.circular(CrRadius.md),
          border: Border.all(color: CrColors.line),
        ),
        child: Row(
          children: [
            SizedBox(width: 60, child: CoverImage(albumId: album.id, title: album.title, radius: 8)),
            const SizedBox(width: CrSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CrText.body(size: 15, weight: FontWeight.w600)),
                  Text('${album.artist} · ${album.rated}/${album.total} tracks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CrText.body(size: 13, color: CrColors.muted)),
                  const SizedBox(height: CrSpace.sm),
                  ProgressBar(fraction: album.total == 0 ? 0 : album.rated / album.total),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
