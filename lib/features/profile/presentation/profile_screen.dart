import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/album_grid.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/ghost_button.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../album/presentation/album_screen.dart';
import '../data/profile_repository.dart';

/// The logged-in user's profile and Taste DNA.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _repo = ProfileRepository(AppScope.read(context).api);
  ProfileData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.load(AppScope.read(context).username);
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
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null && _error != null) return ErrorView(message: _error!, onRetry: _load);
    if (data == null) return const EqLoader();
    final empty = data.songs == 0 && data.albums == 0 && data.artists == 0;

    return RefreshIndicator(
      color: CrColors.gold,
      backgroundColor: CrColors.surface2,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            CrSpace.xl, MediaQuery.paddingOf(context).top + CrSpace.xl, CrSpace.xl, CrSpace.xxxl),
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [hueColor(data.username, lightness: 0.72), hueColor(data.username, lightness: 0.5)],
                  ),
                ),
                child: Text(data.username.characters.first.toUpperCase(),
                    style: CrText.display(36, color: CrColors.onGold)),
              ),
              const SizedBox(width: CrSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LISTENER SINCE ${monthYear(data.joined).toUpperCase()}', style: CrText.eyebrow()),
                    const SizedBox(height: CrSpace.xs),
                    Text(data.username, style: CrText.display(32)),
                  ],
                ),
              ),
            ],
          ),
          if (data.bio.isNotEmpty) ...[
            const SizedBox(height: CrSpace.md),
            Text(data.bio, style: CrText.body(size: 15, color: CrColors.text2)),
          ],
          const SizedBox(height: CrSpace.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(value: data.songs, label: 'SONGS'),
              _Stat(value: data.albums, label: 'ALBUMS'),
              _Stat(value: data.artists, label: 'ARTISTS'),
              _Stat(value: data.followers, label: 'FOLLOWERS'),
            ],
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.only(top: CrSpace.xxl),
              child: Text('Your Taste DNA appears once you start rating. Search an album to begin.',
                  style: CrText.body(size: 15, color: CrColors.muted)),
            )
          else ...[
            const SectionHeader(eyebrow: 'Taste DNA', title: 'What your ears are into'),
            _GenreCard(genres: data.genres),
            const SizedBox(height: CrSpace.lg),
            _HistogramCard(distribution: data.distribution, average: data.average),
            if (data.topAlbums.isNotEmpty) ...[
              const SectionHeader(eyebrow: 'Hall of fame', title: 'Top albums'),
              AlbumGrid(albums: data.topAlbums, onOpen: (a) => _open(a.id)),
            ],
            if (data.topSongs.isNotEmpty) ...[
              const SectionHeader(eyebrow: 'On repeat', title: 'Top songs'),
              for (final (i, song) in data.topSongs.indexed)
                Pressable(
                  onTap: () => _open(song.albumId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: CrSpace.sm),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('${i + 1}', style: CrText.body(size: 14, color: CrColors.muted)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CrText.body(size: 15, weight: FontWeight.w600)),
                              Text('${song.artist} · ${song.albumTitle}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CrText.body(size: 13, color: CrColors.muted)),
                            ],
                          ),
                        ),
                        StarRating(value: song.score, size: 14),
                      ],
                    ),
                  ),
                ),
            ],
          ],
          const SizedBox(height: CrSpace.xxl),
          Center(
            child: GhostButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              danger: true,
              onPressed: () => AppScope.read(context).logout(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: CrText.display(26)),
        const SizedBox(height: CrSpace.xs),
        Text(label, style: CrText.eyebrow(color: CrColors.muted).copyWith(fontSize: 10, letterSpacing: 1.2)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CrSpace.xl),
      decoration: BoxDecoration(
        color: CrColors.surface,
        borderRadius: BorderRadius.circular(CrRadius.md),
        border: Border.all(color: CrColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CrText.display(22, weight: FontWeight.w600)),
          const SizedBox(height: CrSpace.xs),
          Text(subtitle, style: CrText.body(size: 13, color: CrColors.muted)),
          const SizedBox(height: CrSpace.lg),
          child,
        ],
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.genres});

  final List<({String name, double weight})> genres;

  @override
  Widget build(BuildContext context) {
    final shown = genres.take(8).toList();
    final total = genres.fold<double>(0, (sum, g) => sum + g.weight);
    return _Card(
      title: 'Genre fingerprint',
      subtitle: 'Share of your taste by genre, weighted toward what you rate highest.',
      child: shown.isEmpty
          ? Text('No genre data yet for the albums you rated.', style: CrText.body(size: 14, color: CrColors.muted))
          : Column(
              children: [
                for (final g in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CrText.body(size: 13, color: CrColors.text2)),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: g.weight.clamp(0.02, 1),
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                                  gradient: const LinearGradient(colors: [CrColors.goldDeep, CrColors.gold2]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 42,
                          child: Text(
                            total == 0 ? '' : '${(g.weight / total * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: CrText.body(size: 12, color: CrColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HistogramCard extends StatelessWidget {
  const _HistogramCard({required this.distribution, required this.average});

  final List<int> distribution;
  final double? average;

  @override
  Widget build(BuildContext context) {
    final total = distribution.fold<int>(0, (sum, n) => sum + n);
    final peak = distribution.fold<int>(1, (max, n) => n > max ? n : max);
    return _Card(
      title: 'Song ratings',
      subtitle: 'How your ${plural(total, 'song rating')} spread across the 5-star scale.',
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < distribution.length; i++)
                  Expanded(
                    child: Semantics(
                      label: '${fmtScore(i + 1)} stars: ${plural(distribution[i], 'song')}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FractionallySizedBox(
                          heightFactor: distribution[i] == 0 ? 0.0 : distribution[i] / peak,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: CrColors.gold,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: CrColors.line2),
          const SizedBox(height: CrSpace.xs),
          Row(
            children: [
              for (var i = 0; i < distribution.length; i++)
                Expanded(
                  child: Text(i.isOdd ? '${(i + 1) ~/ 2}★' : '',
                      textAlign: TextAlign.center, style: CrText.body(size: 11, color: CrColors.muted)),
                ),
            ],
          ),
          const SizedBox(height: CrSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Average ', style: CrText.body(size: 14, color: CrColors.text2)),
                TextSpan(text: '★ ${fmtScore(average)}', style: CrText.score(size: 14)),
              ])),
              Text(plural(total, 'song'), style: CrText.body(size: 14, color: CrColors.text2)),
            ],
          ),
        ],
      ),
    );
  }
}
