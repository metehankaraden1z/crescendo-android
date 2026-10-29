import '../../../core/network/api_service.dart';
import '../../../shared/models/album_summary.dart';

class ArtistMatch {
  const ArtistMatch({required this.id, required this.name, required this.meta});

  factory ArtistMatch.fromJson(Map<String, dynamic> json) => ArtistMatch(
        id: json['id'] as String,
        name: json['name'] as String,
        meta: [
          json['type'],
          json['country'],
          if (json['begin'] != null) 'since ${json['begin']}',
          json['disambiguation'],
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      );

  final String id;
  final String name;
  final String meta;
}

class SearchResult {
  const SearchResult({
    required this.albums,
    this.artist,
    this.artistAlbums = const [],
    this.albumsFirst = false,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    return SearchResult(
      albums: asMapList(json['results']).map(AlbumSummary.fromJson).toList(),
      artist: artist == null ? null : ArtistMatch.fromJson(artist),
      artistAlbums: asMapList(json['artist_albums']).map(AlbumSummary.fromJson).toList(),
      albumsFirst: (json['albums_first'] as bool?) ?? false,
    );
  }

  final List<AlbumSummary> albums;

  /// Set when the query names an artist ("eminem"): their discography leads the results.
  final ArtistMatch? artist;
  final List<AlbumSummary> artistAlbums;
  final bool albumsFirst;

  bool get isEmpty => albums.isEmpty && artistAlbums.isEmpty;
}

class SearchRepository {
  SearchRepository(this._api);

  final ApiService _api;

  Future<SearchResult> search(String query) async =>
      SearchResult.fromJson(await _api.get('/api/search', query: {'q': query}));
}
