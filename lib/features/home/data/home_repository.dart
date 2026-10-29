import '../../../core/network/api_service.dart';
import '../../../shared/models/album_summary.dart';

class InProgressAlbum {
  const InProgressAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.rated,
    required this.total,
  });

  factory InProgressAlbum.fromJson(Map<String, dynamic> json) => InProgressAlbum(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: (json['artist'] as String?) ?? '',
        rated: asInt(json['rated']) ?? 0,
        total: asInt(json['total']) ?? 0,
      );

  final String id;
  final String title;
  final String artist;
  final int rated;
  final int total;
}

class HomeData {
  const HomeData({
    required this.trending,
    required this.inProgress,
    required this.songs,
    required this.albums,
    required this.artists,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final counts = (json['my_counts'] as Map<String, dynamic>?) ?? const {};
    return HomeData(
      trending: asMapList(json['trending']).map(AlbumSummary.fromJson).toList(),
      inProgress: asMapList(json['in_progress']).map(InProgressAlbum.fromJson).toList(),
      songs: asInt(counts['songs']) ?? 0,
      albums: asInt(counts['albums']) ?? 0,
      artists: asInt(counts['artists']) ?? 0,
    );
  }

  final List<AlbumSummary> trending;
  final List<InProgressAlbum> inProgress;
  final int songs;
  final int albums;
  final int artists;
}

class HomeRepository {
  HomeRepository(this._api);

  final ApiService _api;

  Future<HomeData> load() async => HomeData.fromJson(await _api.get('/api/home'));
}
