import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/cover_image.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/ghost_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/star_rating.dart';
import '../data/album_repository.dart';
import 'rate_session_screen.dart';

/// Opens an album page; the returned future completes when the user comes back.
Future<void> openAlbum(BuildContext context, String albumId) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlbumScreen(albumId: albumId)));

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.albumId});

  final String albumId;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late final AlbumRepository _repo = AlbumRepository(AppScope.read(context).api);
  AlbumDetail? _album;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final album = await _repo.load(widget.albumId);
      if (mounted) setState(() => _album = album);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _rateSong(Track track, int? score) async {
    final album = _album!;
    final previous = track.my;
    setState(() => track.my = score);
    try {
      final result = await _repo.rateSong(song: track.id, album: album.id, score: score);
      if (mounted) {
        setState(() {
          track.avg = result.avg;
          track.count = result.count;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => track.my = previous);
      showToast(context, e.message, error: true);
    }
  }

  Future<void> _rateAlbum(int? score) async {
    final album = _album!;
    final previous = album.myScore;
    setState(() => album.myScore = score);
    try {
      final result = await _repo.rateAlbum(album: album.id, score: score, review: album.myReview);
      if (mounted) {
        setState(() {
          album.avg = result.avg;
          album.count = result.count;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => album.myScore = previous);
      showToast(context, e.message, error: true);
    }
  }

  Future<void> _startSession() async {
    final album = _album!;
    final firstUnrated = album.tracks.indexWhere((t) => t.my == null);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RateSessionScreen(album: album, repo: _repo, startIndex: firstUnrated < 0 ? 0 : firstUnrated),
    ));
    if (mounted) setState(() {}); // the session updated the shared Track objects
  }

  @override
  Widget build(BuildContext context) {
    final album = _album;
    Widget body;
    if (album == null && _error != null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (album == null) {
      body = const EqLoader(label: 'Pulling the tracklist from MusicBrainz…');
    } else {
      body = _AlbumBody(
        album: album,
        onRateSong: _rateSong,
        onRateAlbum: _rateAlbum,
        onStartSession: _startSession,
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          if (album != null) _Backdrop(albumId: album.id, title: album.title),
          body,
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(CrSpace.md),
              child: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blurred cover glow behind the top of the page.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.albumId, required this.title});

  final String albumId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 520,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.55,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40, tileMode: TileMode.clamp),
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CoverImage(albumId: albumId, title: title, radius: 0),
                  ),
                ),
              ),
            ),
            // Ends in the page colour, so the glow melts into the background with no seam.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x330E0D0A), Color(0x990E0D0A), CrColors.bg],
                  stops: [0, 0.6, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumBody extends StatelessWidget {
  const _AlbumBody({
    required this.album,
    required this.onRateSong,
    required this.onRateAlbum,
    required this.onStartSession,
  });

  final AlbumDetail album;
  final void Function(Track track, int? score) onRateSong;
  final ValueChanged<int?> onRateAlbum;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final meta = [album.type ?? 'Release', if (album.year != null) album.year!].join(' · ').toUpperCase();
    final multiDisc = album.tracks.map((t) => t.disc).toSet().length > 1;
    final rows = <Widget>[];
    int? lastDisc;
    for (final track in album.tracks) {
      if (multiDisc && track.disc != lastDisc) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: CrSpace.xl, bottom: CrSpace.sm),
          child: Text('DISC ${track.disc}', style: CrText.eyebrow()),
        ));
      }
      lastDisc = track.disc;
      rows.add(_TrackRow(track: track, onRate: (score) => onRateSong(track, score)));
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(CrSpace.xl, 64, CrSpace.xl, CrSpace.xxxl),
        children: [
          Center(
            child: Container(
              width: 240,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: CrShadow.card),
              child: CoverImage(albumId: album.id, title: album.title, size: 500, radius: 16),
            ),
          ),
          const SizedBox(height: CrSpace.xl),
          Text(meta, style: CrText.eyebrow()),
          const SizedBox(height: CrSpace.sm),
          Text(album.title, style: CrText.display(38)),
          const SizedBox(height: CrSpace.sm),
          Text('by ${album.artist}', style: CrText.body(size: 18, color: CrColors.text2)),
          if (album.genres.isNotEmpty) ...[
            const SizedBox(height: CrSpace.lg),
            Wrap(
              spacing: CrSpace.sm,
              runSpacing: CrSpace.sm,
              children: [for (final g in album.genres.take(5)) _Chip(text: g)],
            ),
          ],
          const SizedBox(height: CrSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Panel(
                  label: 'CRESCENDO AVERAGE',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fmtScore(album.avg), style: CrText.display(34, color: CrColors.gold2)),
                      const SizedBox(height: CrSpace.xs),
                      Text(plural(album.count, 'rating'), style: CrText.body(size: 13, color: CrColors.muted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: CrSpace.md),
              Expanded(
                child: _Panel(
                  label: 'YOUR ALBUM RATING',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRating(
                        value: album.myScore,
                        size: 26,
                        onChanged: onRateAlbum,
                        onClear: album.myScore == null ? null : () => onRateAlbum(null),
                      ),
                      Text(
                        album.myTrackAverage == null
                            ? (album.myScore == null ? 'Tap to rate' : fmtScore(album.myScore))
                            : 'Track avg ★ ${fmtScore(album.myTrackAverage)}',
                        style: CrText.body(size: 13, color: CrColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (album.tracks.isNotEmpty) ...[
            const SizedBox(height: CrSpace.xl),
            GoldButton(
              label: album.ratedTracks == 0
                  ? 'Rate track by track'
                  : album.ratedTracks == album.tracks.length
                      ? 'Review your track ratings'
                      : 'Continue rating (${album.ratedTracks}/${album.tracks.length})',
              onPressed: onStartSession,
            ),
            const SizedBox(height: CrSpace.xl),
            _Progress(rated: album.ratedTracks, total: album.tracks.length),
            const SizedBox(height: CrSpace.sm),
            Text('Tap or drag across the stars to rate · long-press to clear',
                style: CrText.body(size: 12, color: CrColors.muted)),
            const SizedBox(height: CrSpace.md),
            ...rows,
          ] else
            Padding(
              padding: const EdgeInsets.only(top: CrSpace.xl),
              child: Text(
                "MusicBrainz doesn't have a tracklist for this release yet. You can still rate the album.",
                style: CrText.body(size: 15, color: CrColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.onRate});

  final Track track;
  final ValueChanged<int?> onRate;

  @override
  Widget build(BuildContext context) {
    final rated = track.my != null;
    final sub = [
      if (track.credit != null) track.credit!,
      fmtLength(track.lengthMs),
      if (track.count > 0) '★ ${fmtScore(track.avg)} (${track.count})',
    ].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CrSpace.sm),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CrColors.line))),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${track.position}',
                style: CrText.body(size: 14, color: rated ? CrColors.gold : CrColors.muted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CrText.body(size: 15, weight: FontWeight.w600)),
                if (sub.isNotEmpty)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CrText.body(size: 12, color: CrColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: CrSpace.sm),
          StarRating(
            value: track.my,
            size: 20,
            onChanged: onRate,
            onClear: rated ? () => onRate(null) : null,
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.rated, required this.total});

  final int rated;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$rated / $total rated', style: CrText.body(size: 14, weight: FontWeight.w600)),
        const SizedBox(width: CrSpace.md),
        Expanded(child: ProgressBar(fraction: total == 0 ? 0 : rated / total)),
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: CrColors.starEmpty),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0, 1),
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [CrColors.goldDeep, CrColors.gold2])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CrSpace.lg),
      decoration: BoxDecoration(
        color: const Color(0xB31B1914),
        borderRadius: BorderRadius.circular(CrRadius.md),
        border: Border.all(color: CrColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CrText.eyebrow(color: CrColors.muted).copyWith(fontSize: 10, letterSpacing: 1.4)),
          const SizedBox(height: CrSpace.sm),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: CrColors.surface2,
        borderRadius: BorderRadius.circular(CrRadius.pill),
        border: Border.all(color: CrColors.line),
      ),
      child: Text(text, style: CrText.body(size: 13, weight: FontWeight.w500, color: CrColors.text2)),
    );
  }
}
