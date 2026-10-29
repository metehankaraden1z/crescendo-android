import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

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

/// Full-screen "track by track" mode: one song at a time, then the album as a whole.
class RateSessionScreen extends StatefulWidget {
  const RateSessionScreen({super.key, required this.album, required this.repo, this.startIndex = 0});

  final AlbumDetail album;
  final AlbumRepository repo;
  final int startIndex;

  @override
  State<RateSessionScreen> createState() => _RateSessionScreenState();
}

class _RateSessionScreenState extends State<RateSessionScreen> {
  late int _index = widget.startIndex;
  bool _final = false;
  int? _albumScore;
  bool _saving = false;
  Timer? _advance;
  late final _review = TextEditingController(text: widget.album.myReview);

  List<Track> get _tracks => widget.album.tracks;

  @override
  void dispose() {
    _advance?.cancel();
    _review.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _advance?.cancel();
    setState(() {
      if (index >= _tracks.length) {
        _final = true;
        _albumScore = widget.album.myScore ?? widget.album.myTrackAverage?.round();
      } else {
        _final = false;
        _index = index.clamp(0, _tracks.length - 1);
      }
    });
  }

  Future<void> _rate(int? score) async {
    final track = _tracks[_index];
    final previous = track.my;
    setState(() => track.my = score);
    try {
      final result = await widget.repo.rateSong(song: track.id, album: widget.album.id, score: score);
      track
        ..avg = result.avg
        ..count = result.count;
      if (!mounted) return;
      if (score != null) {
        _advance?.cancel();
        _advance = Timer(const Duration(milliseconds: 500), () {
          if (mounted && !_final && _tracks[_index] == track) _goTo(_index + 1);
        });
      }
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => track.my = previous);
      showToast(context, e.message, error: true);
    }
  }

  Future<void> _saveAlbum() async {
    final score = _albumScore;
    if (score == null) {
      showToast(context, 'Pick a star rating for the album first.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final result =
          await widget.repo.rateAlbum(album: widget.album.id, score: score, review: _review.text.trim());
      widget.album
        ..myScore = score
        ..myReview = _review.text.trim()
        ..avg = result.avg
        ..count = result.count;
      if (!mounted) return;
      showToast(context, '${widget.album.title} is now part of your Taste DNA ✦');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.decal),
                child: CoverImage(albumId: album.id, title: album.title, radius: 0),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(CrSpace.lg, CrSpace.md, CrSpace.lg, 0),
                  child: Row(
                    children: [
                      SizedBox(width: 44, child: CoverImage(albumId: album.id, title: album.title, radius: 8)),
                      const SizedBox(width: CrSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(album.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CrText.body(size: 15, weight: FontWeight.w700)),
                            Text(album.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CrText.body(size: 13, color: CrColors.muted)),
                          ],
                        ),
                      ),
                      CircleIconButton(
                        icon: Icons.close_rounded,
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _final ? _buildFinal() : _buildTrack()),
                _Dots(
                  tracks: _tracks,
                  index: _final ? -1 : _index,
                  onTap: _goTo,
                  onFinal: () => _goTo(_tracks.length),
                  finalSelected: _final,
                ),
                const SizedBox(height: CrSpace.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrack() {
    final track = _tracks[_index];
    final meta = [
      fmtLength(track.lengthMs),
      if (track.credit != null) track.credit!,
      track.count > 0 ? 'community ★ ${fmtScore(track.avg)} (${track.count})' : 'no community ratings yet',
    ].where((s) => s.isNotEmpty).join(' · ');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CrSpace.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TRACK ${_index + 1} OF ${_tracks.length}', style: CrText.eyebrow()),
            const SizedBox(height: CrSpace.lg),
            Text(track.title, textAlign: TextAlign.center, style: CrText.display(40)),
            const SizedBox(height: CrSpace.md),
            Text(meta, textAlign: TextAlign.center, style: CrText.body(size: 14, color: CrColors.muted)),
            const SizedBox(height: CrSpace.xxl),
            StarRating(
              key: ValueKey(track.id),
              value: track.my,
              size: 54,
              onChanged: _rate,
              onClear: track.my == null ? null : () => _rate(null),
            ),
            const SizedBox(height: CrSpace.md),
            Text(
              track.my == null ? 'Tap a star, or drag across them' : '${fmtScore(track.my)} / 5',
              style: track.my == null
                  ? CrText.body(size: 15, color: CrColors.muted)
                  : CrText.display(28, weight: FontWeight.w700, color: CrColors.gold2),
            ),
            const SizedBox(height: CrSpace.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GhostButton(
                  label: 'Previous',
                  icon: Icons.chevron_left_rounded,
                  onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                ),
                const SizedBox(width: CrSpace.md),
                GhostButton(label: track.my == null ? 'Skip' : 'Next', onPressed: () => _goTo(_index + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinal() {
    final album = widget.album;
    final rated = album.ratedTracks;
    final average = album.myTrackAverage;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CrSpace.xl),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          const SizedBox(height: CrSpace.xl),
          Text(rated == _tracks.length ? 'ALBUM COMPLETE' : '$rated OF ${_tracks.length} TRACKS RATED',
              style: CrText.eyebrow()),
          const SizedBox(height: CrSpace.lg),
          Text('Now, the album as a whole.', textAlign: TextAlign.center, style: CrText.display(36)),
          const SizedBox(height: CrSpace.md),
          Text(
            average == null
                ? 'You skipped every track. You can still rate the album.'
                : 'Your track average is ★ ${fmtScore(average)}',
            textAlign: TextAlign.center,
            style: CrText.body(size: 15, color: CrColors.text2),
          ),
          const SizedBox(height: CrSpace.xl),
          StarRating(value: _albumScore, size: 54, onChanged: (v) => setState(() => _albumScore = v)),
          const SizedBox(height: CrSpace.sm),
          Text(_albumScore == null ? 'Pick a score' : fmtScore(_albumScore),
              style: CrText.display(28, weight: FontWeight.w700, color: CrColors.gold2)),
          const SizedBox(height: CrSpace.xl),
          TextField(
            controller: _review,
            maxLines: 4,
            minLines: 3,
            maxLength: 2000,
            style: CrText.body(),
            decoration: const InputDecoration(hintText: 'Add a short review (optional)', counterText: ''),
          ),
          const SizedBox(height: CrSpace.xl),
          GoldButton(label: _saving ? 'Saving…' : 'Save album rating', onPressed: _saving ? null : _saveAlbum),
          const SizedBox(height: CrSpace.md),
          GhostButton(
            label: 'Back to tracks',
            icon: Icons.chevron_left_rounded,
            onPressed: () => _goTo(_tracks.length - 1),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.tracks,
    required this.index,
    required this.onTap,
    required this.onFinal,
    required this.finalSelected,
  });

  final List<Track> tracks;
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onFinal;
  final bool finalSelected;

  Widget _dot({required bool current, required bool done, required VoidCallback onTap, double width = 22}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: current ? 10 : 7,
          decoration: BoxDecoration(
            color: current ? CrColors.gold2 : (done ? CrColors.goldDeep : CrColors.starEmpty),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CrSpace.lg),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < tracks.length; i++)
            _dot(current: i == index, done: tracks[i].my != null, onTap: () => onTap(i)),
          _dot(current: finalSelected, done: false, onTap: onFinal, width: 34),
        ],
      ),
    );
  }
}
