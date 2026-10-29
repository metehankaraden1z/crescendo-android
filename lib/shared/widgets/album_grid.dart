import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../format.dart';
import '../models/album_summary.dart';
import 'cover_image.dart';
import 'pressable.dart';

/// Two-column grid of album cards that sizes itself to its content.
class AlbumGrid extends StatelessWidget {
  const AlbumGrid({super.key, required this.albums, required this.onOpen, this.showMine = true});

  final List<AlbumSummary> albums;
  final ValueChanged<AlbumSummary> onOpen;
  final bool showMine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 14.0;
      final columns = constraints.maxWidth > 600 ? 3 : 2;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: 22,
        children: [
          for (final album in albums)
            SizedBox(
              width: width,
              child: AlbumCard(album: album, showMine: showMine, onTap: () => onOpen(album)),
            ),
        ],
      );
    });
  }
}

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, required this.onTap, this.showMine = true});

  final AlbumSummary album;
  final VoidCallback onTap;
  final bool showMine;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (album.year != null) album.year!,
      if (album.type != null && album.type != 'Album') album.type!,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${album.title}${album.artist.isEmpty ? '' : ' by ${album.artist}'}',
      child: Pressable(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CoverImage(albumId: album.id, title: album.title),
                if (showMine && album.my != null)
                  Positioned(top: 6, right: 6, child: ScoreBadge(score: album.my!)),
              ],
            ),
            const SizedBox(height: CrSpace.sm),
            Text(
              album.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CrText.body(size: 15, weight: FontWeight.w600, height: 1.25),
            ),
            if (album.artist.isNotEmpty)
              Text(album.artist,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: CrText.body(size: 13, color: CrColors.muted)),
            if (album.avg != null || meta.isNotEmpty)
              Row(
                children: [
                  if (album.avg != null) ...[
                    Text('★ ${fmtScore(album.avg)}', style: CrText.score(size: 13)),
                    const SizedBox(width: CrSpace.sm),
                  ],
                  Flexible(
                    child: Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CrText.body(size: 13, color: CrColors.muted)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Small "★ 4.5" badge shown on top of a cover.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});

  final num score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xD10E0D0A), borderRadius: BorderRadius.circular(6)),
      child: Text('★ ${fmtScore(score)}', style: CrText.score(size: 12)),
    );
  }
}
