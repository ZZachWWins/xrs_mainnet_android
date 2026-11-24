
class BrowserBookmark {
  final String title;
  final String url;
  final String? iconUrl;
  final bool isDefault;

  BrowserBookmark({
    required this.title,
    required this.url,
    this.iconUrl,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'iconUrl': iconUrl,
    'isDefault': isDefault,
  };

  factory BrowserBookmark.fromJson(Map<String, dynamic> json) => BrowserBookmark(
    title: json['title'],
    url: json['url'],
    iconUrl: json['iconUrl'],
    isDefault: json['isDefault'] ?? false,
  );
}
