import '../../../core/network/api_service.dart';
import '../../../shared/models/album_summary.dart';

class TopSong {
  const TopSong({required this.title, required this.artist, required this.albumId, required this.albumTitle, required this.score});

  factory TopSong.fromJson(Map<String, dynamic> json) => TopSong(
        title: json['title'] as String,
        artist: (json['artist'] as String?) ?? '',
        albumId: json['album_id'] as String,
        albumTitle: (json['album_title'] as String?) ?? '',
        score: asInt(json['score']) ?? 0,
      );

  final String title;
  final String artist;
  final String albumId;
  final String albumTitle;
  final int score;
}

class ProfileData {
  const ProfileData({
    required this.username,
    required this.bio,
    required this.joined,
    required this.songs,
    required this.albums,
    required this.artists,
    required this.followers,
    required this.following,
    required this.average,
    required this.distribution,
    required this.genres,
    required this.topAlbums,
    required this.topSongs,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final counts = json['counts'] as Map<String, dynamic>;
    return ProfileData(
      username: user['username'] as String,
      bio: (user['bio'] as String?) ?? '',
      joined: asInt(user['joined']),
      songs: asInt(counts['songs']) ?? 0,
      albums: asInt(counts['albums']) ?? 0,
      artists: asInt(counts['artists']) ?? 0,
      followers: asInt(counts['followers']) ?? 0,
      following: asInt(counts['following']) ?? 0,
      average: asDouble(counts['avg']),
      distribution: ((json['distribution'] as List?) ?? const []).map((v) => asInt(v) ?? 0).toList(),
      genres: [
        for (final g in asMapList(json['genres'])) (name: g['name'] as String, weight: asDouble(g['weight']) ?? 0),
      ],
      topAlbums: asMapList(json['top_albums']).map(AlbumSummary.fromJson).toList(),
      topSongs: asMapList(json['top_songs']).map(TopSong.fromJson).toList(),
    );
  }

  final String username;
  final String bio;
  final int? joined;
  final int songs;
  final int albums;
  final int artists;
  final int followers;
  final int following;
  final double? average; // 1–10
  final List<int> distribution; // song ratings per score 1..10
  final List<({String name, double weight})> genres; // weight relative to the top genre
  final List<AlbumSummary> topAlbums;
  final List<TopSong> topSongs;
}

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiService _api;

  Future<ProfileData> load(String username) async =>
      ProfileData.fromJson(await _api.get('/api/users/${Uri.encodeComponent(username)}'));
}
