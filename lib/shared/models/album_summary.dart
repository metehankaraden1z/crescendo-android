double? asDouble(Object? value) => value == null ? null : (value as num).toDouble();

int? asInt(Object? value) => value == null ? null : (value as num).toInt();

List<Map<String, dynamic>> asMapList(Object? value) =>
    ((value as List?) ?? const []).cast<Map<String, dynamic>>();

/// An album as it appears in grids and lists.
class AlbumSummary {
  const AlbumSummary({
    required this.id,
    required this.title,
    this.artist = '',
    this.year,
    this.type,
    this.avg,
    this.my,
  });

  factory AlbumSummary.fromJson(Map<String, dynamic> json) => AlbumSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: (json['artist'] as String?) ?? '',
        year: json['year'] as String?,
        type: json['type'] as String?,
        avg: asDouble(json['avg']),
        // Profile lists call the owner's rating "score"; everywhere else it is "my".
        my: asInt(json['my'] ?? json['score']),
      );

  final String id;
  final String title;
  final String artist;
  final String? year;
  final String? type;
  final double? avg; // community average, 1–10
  final int? my; // the viewer's rating, 1–10
}
