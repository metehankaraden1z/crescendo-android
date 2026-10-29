import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/format.dart';
import '../../../shared/models/album_summary.dart';
import '../../../shared/widgets/album_grid.dart';
import '../../../shared/widgets/feedback.dart';
import '../../album/presentation/album_screen.dart';
import '../data/search_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.focusRequest = 0});

  /// Changing this value focuses the search field (used by the Home tab's search box).
  final int focusRequest;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchRepository _repo = SearchRepository(AppScope.read(context).api);
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _seq = 0;
  String _query = '';
  SearchResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    if (widget.focusRequest != old.focusRequest) _focus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _run(text.trim()));
    setState(() {}); // show/hide the clear button
  }

  Future<void> _run(String query) async {
    final seq = ++_seq;
    if (query.length < 2) {
      setState(() {
        _query = '';
        _result = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _query = query;
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.search(query);
      if (!mounted || seq != _seq) return; // a newer search started meanwhile
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _open(AlbumSummary album) {
    _focus.unfocus();
    openAlbum(context, album.id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(CrSpace.xl, CrSpace.xl, CrSpace.xl, CrSpace.lg),
            child: Text('Search', style: CrText.display(34)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CrSpace.xl),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: CrText.body(),
              textInputAction: TextInputAction.search,
              autocorrect: false,
              onChanged: _onChanged,
              onSubmitted: (text) {
                _debounce?.cancel();
                _run(text.trim());
              },
              decoration: InputDecoration(
                hintText: 'Album or artist — try “eminem”',
                prefixIcon: const Icon(Icons.search_rounded, color: CrColors.muted),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () {
                          _controller.clear();
                          _onChanged('');
                        },
                        child: const Icon(Icons.close_rounded, color: CrColors.muted),
                      ),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(CrSpace.xl, CrSpace.md, CrSpace.xl, 0),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: CrColors.gold,
                backgroundColor: Colors.transparent,
              ),
            ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result;
    if (_error != null) return ErrorView(message: _error!, onRetry: () => _run(_query));
    if (_query.isEmpty) {
      return _Hint(text: 'Search millions of albums from MusicBrainz, then rate them song by song.');
    }
    if (result == null) return const EqLoader(label: 'Searching MusicBrainz…');
    if (result.isEmpty) return _Hint(text: 'No albums found for “$_query”. Try fewer words.');

    final artistSection = result.artist == null ? <Widget>[] : _artistSection(result);
    final otherSection = result.albums.isEmpty
        ? <Widget>[]
        : [
            if (result.artist != null)
              SectionHeader(
                eyebrow: result.albumsFirst ? 'Best matches' : 'Also matching',
                title: result.albumsFirst ? 'Albums' : 'Other results',
              ),
            AlbumGrid(albums: result.albums, onOpen: _open, showMine: false),
          ];
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(CrSpace.xl, CrSpace.lg, CrSpace.xl, CrSpace.xxxl),
      children: result.albumsFirst ? [...otherSection, ...artistSection] : [...artistSection, ...otherSection],
    );
  }

  List<Widget> _artistSection(SearchResult result) {
    final artist = result.artist!;
    final albums = result.artistAlbums.where((a) => a.type != 'EP').toList();
    final eps = result.artistAlbums.where((a) => a.type == 'EP').toList();
    return [
      Container(
        margin: const EdgeInsets.only(top: CrSpace.md),
        padding: const EdgeInsets.all(CrSpace.lg),
        decoration: BoxDecoration(
          color: CrColors.surface,
          borderRadius: BorderRadius.circular(CrRadius.md),
          border: Border.all(color: CrColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [hueColor(artist.name, lightness: 0.7), hueColor(artist.name)]),
              ),
              child: Text(artist.name.characters.first.toUpperCase(),
                  style: CrText.display(26, color: CrColors.onGold)),
            ),
            const SizedBox(width: CrSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ARTIST', style: CrText.eyebrow()),
                  const SizedBox(height: CrSpace.xs),
                  Text(artist.name, style: CrText.display(26, weight: FontWeight.w700)),
                  if (artist.meta.isNotEmpty)
                    Text(artist.meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CrText.body(size: 13, color: CrColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
      if (albums.isNotEmpty) ...[
        SectionHeader(eyebrow: 'Albums by ${artist.name}', title: '${albums.length} albums'),
        AlbumGrid(albums: albums, onOpen: _open),
      ],
      if (eps.isNotEmpty) ...[
        SectionHeader(eyebrow: 'Shorter releases', title: 'EPs'),
        AlbumGrid(albums: eps, onOpen: _open),
      ],
    ];
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CrSpace.xl),
      child: Text(text, style: CrText.body(size: 15, color: CrColors.muted)),
    );
  }
}
