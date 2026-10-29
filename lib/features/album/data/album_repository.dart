import '../../../core/network/api_service.dart';
import '../../../shared/models/album_summary.dart';

class Track {
  Track({
    required this.id,
    required this.title,
    required this.disc,
    required this.position,
    this.lengthMs,
    this.credit,
    this.avg,
    this.count = 0,
    this.my,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        disc: asInt(json['disc']) ?? 1,
        position: asInt(json['position']) ?? 0,
        lengthMs: asInt(json['length_ms']),
        credit: json['artist_credit'] as String?,
        avg: asDouble(json['avg']),
        count: asInt(json['count']) ?? 0,
        my: asInt(json['my']),
      );

  final String id;
  final String title;
  final int disc;
  final int position;
  final int? lengthMs;
  final String? credit; // only set when it differs from the album artist
  double? avg;
  int count;
  int? my;
}

class AlbumDetail {
  AlbumDetail({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.year,
    required this.type,
    required this.genres,
    required this.tracks,
    required this.avg,
    required this.count,
    required this.myScore,
    required this.myReview,
  });

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    final album = json['album'] as Map<String, dynamic>;
    final stats = json['stats'] as Map<String, dynamic>;
    final mine = json['mine'] as Map<String, dynamic>?;
    return AlbumDetail(
      id: album['id'] as String,
      title: album['title'] as String,
      artist: (album['artist'] as String?) ?? '',
      artistId: album['artist_id'] as String?,
      year: album['year'] as String?,
      type: album['type'] as String?,
      genres: ((album['genres'] as List?) ?? const []).cast<String>(),
      tracks: asMapList(json['tracks']).map(Track.fromJson).toList(),
      avg: asDouble(stats['avg']),
      count: asInt(stats['count']) ?? 0,
      myScore: asInt(mine?['score']),
      myReview: (mine?['review'] as String?) ?? '',
    );
  }

  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final String? year;
  final String? type;
  final List<String> genres;
  final List<Track> tracks;
  double? avg;
  int count;
  int? myScore;
  String myReview;

  int get ratedTracks => tracks.where((t) => t.my != null).length;

  double? get myTrackAverage {
    final rated = tracks.where((t) => t.my != null).toList();
    if (rated.isEmpty) return null;
    return rated.fold<int>(0, (sum, t) => sum + t.my!) / rated.length;
  }
}

class RatingResult {
  const RatingResult({required this.avg, required this.count});

  factory RatingResult.fromJson(Map<String, dynamic> json) =>
      RatingResult(avg: asDouble(json['avg']), count: asInt(json['count']) ?? 0);

  final double? avg;
  final int count;
}

class AlbumRepository {
  AlbumRepository(this._api);

  final ApiService _api;

  Future<AlbumDetail> load(String id) async => AlbumDetail.fromJson(await _api.get('/api/album/$id'));

  /// [score] 1–10, or null to clear the rating.
  Future<RatingResult> rateSong({required String song, required String album, int? score}) async =>
      RatingResult.fromJson(await _api.put('/api/ratings/song', {'song': song, 'album': album, 'score': score}));

  Future<RatingResult> rateAlbum({required String album, int? score, String review = ''}) async =>
      RatingResult.fromJson(await _api.put('/api/ratings/album', {'album': album, 'score': score, 'review': review}));
}
