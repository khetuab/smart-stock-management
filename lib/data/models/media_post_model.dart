// lib/data/models/media_post_model.dart

class MediaPost {
  final String id;
  final String type; // 'photo' or 'video'
  final String mediaUrl;
  final String thumbnailUrl; // same as mediaUrl for photos; a derived frame for videos
  final String caption;
  final String productId; // optional — links the post to a product
  final String productName;
  final String postedBy;
  final String createdAt;

  /// Which social platform tab this post belongs to. Older rows (and the
  /// general store feed) use 'shop'. Valid: shop, youtube, tiktok,
  /// instagram, facebook, telegram.
  final String platform;

  MediaPost({
    this.id = '',
    required this.type,
    required this.mediaUrl,
    required this.thumbnailUrl,
    this.caption = '',
    this.productId = '',
    this.productName = '',
    this.postedBy = '',
    this.createdAt = '',
    this.platform = 'shop',
  });

  bool get isVideo => type == 'video';
  bool get hasLinkedProduct => productId.isNotEmpty;

  static const List<String> knownPlatforms = [
    'shop', 'youtube', 'tiktok', 'instagram', 'facebook', 'telegram',
  ];

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'mediaUrl': mediaUrl,
    'thumbnailUrl': thumbnailUrl,
    'caption': caption,
    'productId': productId,
    'productName': productName,
    'postedBy': postedBy,
    'createdAt': createdAt,
    'platform': platform,
  };

  factory MediaPost.fromMap(Map<String, dynamic> map) => MediaPost(
    id: map['id']?.toString() ?? '',
    type: map['type']?.toString() ?? 'photo',
    mediaUrl: map['mediaUrl']?.toString() ?? '',
    thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
    caption: map['caption']?.toString() ?? '',
    productId: map['productId']?.toString() ?? '',
    productName: map['productName']?.toString() ?? '',
    postedBy: map['postedBy']?.toString() ?? '',
    createdAt: map['createdAt']?.toString() ?? '',
    platform: map['platform']?.toString() ?? 'shop',
  );
}
