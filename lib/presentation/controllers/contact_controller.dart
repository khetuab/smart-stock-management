import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/models/store_location_model.dart';
import 'auth_controller.dart';
import 'locations_controller.dart';
import 'social_links_controller.dart';

/// Drives the Contact Us screen:
///  • Branches come from [LocationsController] (same source as the map).
///  • Phone / WhatsApp / Telegram come from [SocialLinksController].
///  • The email form composes a prefilled mailto AND archives the message
///    into a NEW 'ContactMessages' sheet (purely additive) so the owner can
///    read messages in-app from the admin inbox even without email.
class ContactController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  static ContactController get to {
    if (Get.isRegistered<ContactController>()) return Get.find<ContactController>();
    return Get.put(ContactController(), permanent: true);
  }

  var name = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var subject = ''.obs;
  var message = ''.obs;
  var isSending = false.obs;
  var isSent = false.obs;

  var nameError = ''.obs;
  var emailError = ''.obs;
  var messageError = ''.obs;

  var inbox = <ContactMessage>[].obs;
  var inboxLoading = false.obs;

  bool get isAdmin => Get.find<AuthController>().isAdmin;

  void clearForm() {
    name.value = '';
    email.value = '';
    phone.value = '';
    subject.value = '';
    message.value = '';
    isSent.value = false;
    _clearErrors();
  }

  void _clearErrors() {
    nameError.value = '';
    emailError.value = '';
    messageError.value = '';
  }

  bool validate() {
    _clearErrors();
    var ok = true;
    if (name.value.trim().isEmpty) {
      nameError.value = 'pleaseEnterYourName'.tr;
      ok = false;
    }
    final mail = email.value.trim();
    if (mail.isEmpty || !mail.contains('@') || !mail.contains('.')) {
      emailError.value = 'pleaseEnterValidEmail'.tr;
      ok = false;
    }
    if (message.value.trim().length < 5) {
      messageError.value = 'pleaseWriteMessage'.tr;
      ok = false;
    }
    return ok;
  }

  /// Main branch details (falls back to the mock flagship).
  StoreLocation? get mainBranch => LocationsController.to.mainBranch;

  Future<void> sendMessage() async {
    if (!validate()) return;
    try {
      isSending.value = true;

      // 1) Archive to the sheet (best-effort).
      await _archiveMessage();

      // 2) Open the mail client with everything prefilled.
      final mailto = Uri(
        scheme: 'mailto',
        path: 'ethiosadatapp@gmail.com',
        query: _encodeQueryParameters({
          'subject': subject.value.trim().isEmpty
              ? 'Message from ${name.value.trim()}'
              : subject.value.trim(),
          'body': '${message.value.trim()}\n\n'
              '— ${name.value.trim()}'
              '${phone.value.trim().isNotEmpty ? '\nPhone: ${phone.value.trim()}' : ''}'
              '\nEmail: ${email.value.trim()}',
        }),
      );
      try {
        if (await canLaunchUrl(mailto)) {
          await launchUrl(mailto, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // No mail app on device — the message is still archived in the sheet.
      }

      isSent.value = true;
    } catch (e) {
      Get.snackbar('Error', 'failedToSendMessage'.tr,
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _archiveMessage() async {
    try {
      await _sheets.init();
      await _sheets.createSheetIfNotExists('ContactMessages');
      final existing = await _sheets.getSheetDataWithHeaders('ContactMessages');
      if (existing.isEmpty) {
        await _sheets.writeToSheet(
          sheetName: 'ContactMessages',
          values: [
            ['id', 'name', 'email', 'phone', 'subject', 'message', 'createdAt'],
          ],
        );
      }
      await _sheets.appendToSheet(sheetName: 'ContactMessages', rowData: [
        Helpers.generateId(),
        name.value.trim(),
        email.value.trim(),
        phone.value.trim(),
        subject.value.trim(),
        message.value.trim(),
        DateTime.now().toIso8601String(),
      ]);
    } catch (e) {
      debugPrint('Failed to archive contact message: $e');
    }
  }

  Future<void> loadInbox() async {
    if (!isAdmin) return;
    try {
      inboxLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('ContactMessages');
      final data = await _sheets.getSheetDataWithHeaders('ContactMessages');
      final list = <ContactMessage>[];
      List<dynamic> col(String k) => data[k] ?? [];
      String at(List<dynamic> c, int i) => i < c.length ? (c[i]?.toString() ?? '') : '';

      final ids = col('id');
      final names = col('name');
      final emails = col('email');
      final phones = col('phone');
      final subjects = col('subject');
      final messages = col('message');
      final createdAts = col('createdAt');

      for (int i = 0; i < ids.length; i++) {
        if (at(ids, i).isEmpty) continue;
        list.add(ContactMessage(
          id: at(ids, i),
          name: at(names, i),
          email: at(emails, i),
          phone: at(phones, i),
          subject: at(subjects, i),
          message: at(messages, i),
          createdAt: at(createdAts, i),
        ));
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      inbox.assignAll(list);
    } catch (e) {
      debugPrint('Failed to load contact inbox: $e');
    } finally {
      inboxLoading.value = false;
    }
  }

  // ── Quick contact launches ──

  Future<void> callNumber(String raw) async {
    final uri = Uri(scheme: 'tel', path: raw);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> openWhatsApp(String raw) async {
    final number = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTelegram(String raw) async {
    var url = raw.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openDirections(StoreLocation loc) async {
    final uri = Uri.parse(loc.mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class ContactMessage {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String message;
  final String createdAt;

  const ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.message,
    required this.createdAt,
  });
}
