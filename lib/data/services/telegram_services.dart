import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';

class TelegramService {
  /// Opens the admin's Telegram chat with a prefilled order message.
  static Future<bool> openOrderChat({
    required String productName,
    required String category,
    required double unitPrice,
    required double quantity,
    required String customerPhone,
    required String currency,
    String? imageUrl,
  }) async {
    final total = unitPrice * quantity;

    final buffer = StringBuffer()
      ..writeln('*${AppConfig.telegramOrderIntro}*')
      ..writeln('')
      ..writeln('🛍 *Product:* $productName')
      ..writeln('📂 *Category:* ${category.isEmpty ? "General" : category}')
      ..writeln('💰 *Unit Price:* $currency ${unitPrice.toStringAsFixed(2)}')
      ..writeln('🔢 *Quantity:* ${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2)}')
      ..writeln('💵 *Total:* $currency ${total.toStringAsFixed(2)}')
      ..writeln('📞 *My Phone:* $customerPhone');

    if (imageUrl != null && imageUrl.isNotEmpty) {
      buffer.writeln('🖼 $imageUrl');
    }

    buffer
      ..writeln('')
      ..writeln('Please confirm availability and delivery.');

    final text = Uri.encodeComponent(buffer.toString());

    // Try the native app scheme FIRST. This is the only reliable way to
    // force-open the installed Telegram app directly into the chat.
    final nativeUrl = Uri.parse(
      'tg://resolve?domain=${AppConfig.adminTelegramUsername}&text=$text',
    );

    try {
      final launched = await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {
      // tg:// not handled on this device — fall through to web link.
    }

    // Fallback: universal link. This opens Telegram Web (or the browser)
    // if the app truly isn't installed or the tg:// scheme couldn't launch.
    final webUrl = Uri.parse(
      'https://t.me/${AppConfig.adminTelegramUsername}?text=$text',
    );

    try {
      return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}