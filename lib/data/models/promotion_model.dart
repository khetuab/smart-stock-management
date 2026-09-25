import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PromotionModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String linkType; // web | youtube | telegram | whatsapp | facebook | instagram | none
  final String linkUrl;
  final String buttonText;
  final String? discountCode;
  final double discountPercentage;
  final DateTime validFrom;
  final DateTime validUntil;
  final int priority;
  final bool isActive;
  final int views;
  final int clicks;
  final String createdAt;

  PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.linkType,
    required this.linkUrl,
    required this.buttonText,
    this.discountCode,
    required this.discountPercentage,
    required this.validFrom,
    required this.validUntil,
    required this.priority,
    required this.isActive,
    this.views = 0,
    this.clicks = 0,
    required this.createdAt,
  });

  bool get hasDiscount => (discountCode?.isNotEmpty ?? false) && discountPercentage > 0;
  bool get isExpired => validUntil.isBefore(DateTime.now());
  bool get isLive => isActive && !isExpired && validFrom.isBefore(DateTime.now().add(const Duration(days: 1)));

  PromotionModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? linkType,
    String? linkUrl,
    String? buttonText,
    String? discountCode,
    double? discountPercentage,
    DateTime? validFrom,
    DateTime? validUntil,
    int? priority,
    bool? isActive,
    int? views,
    int? clicks,
  }) {
    return PromotionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      linkType: linkType ?? this.linkType,
      linkUrl: linkUrl ?? this.linkUrl,
      buttonText: buttonText ?? this.buttonText,
      discountCode: discountCode ?? this.discountCode,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      createdAt: createdAt,
    );
  }

  // Platform brand icons/colors are the one place this app intentionally
  // uses fixed colors instead of scheme.primary — these represent the
  // external platform's own identity (WhatsApp green, Telegram blue,
  // etc.), not app chrome, so they should stay recognizable regardless
  // of the shop's brand color.
  Object get linkIcon {
    switch (linkType) {
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      case 'whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'none':
        return Icons.campaign_rounded;
      default:
        return Icons.open_in_browser_rounded;
    }
  }

  Color get linkColor {
    switch (linkType) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'telegram':
        return const Color(0xFF229ED9);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE1306C);
      default:
        return Colors.grey;
    }
  }
}