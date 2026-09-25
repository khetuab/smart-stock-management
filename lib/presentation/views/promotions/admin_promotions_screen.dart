import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/promotion_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../../data/models/promotion_model.dart';

class AdminPromotionsScreen extends GetView<PromotionController> {
  const AdminPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Promotions'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('New Banner'.tr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 36,
              child: Obx(() => ListView(
                scrollDirection: Axis.horizontal,
                children: ['all', 'active', 'expired', 'inactive'].map((f) {
                  final selected = controller.filter.value == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f == 'all' ? 'All'.tr : f.tr),
                      selected: selected,
                      onSelected: (_) => controller.filter.value = f,
                      selectedColor: scheme.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  );
                }).toList(),
              )),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.promotions.isEmpty) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              final items = controller.filtered;
              if (items.isEmpty) {
                return AppEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No promotions found'.tr,
                  subtitle: 'Tap "New Banner" to create one.'.tr,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemCount: items.length,
                itemBuilder: (context, index) => _PromoCard(
                  promo: items[index],
                  onEdit: () => _showEditor(context, existing: items[index]),
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  void _showEditor(BuildContext context, {PromotionModel? existing}) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = existing != null;

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final linkUrlCtrl = TextEditingController(text: existing?.linkUrl ?? '');
    final buttonTextCtrl = TextEditingController(text: existing?.buttonText ?? 'Learn More');
    final discountCodeCtrl = TextEditingController(text: existing?.discountCode ?? '');
    final discountPctCtrl = TextEditingController(text: (existing?.discountPercentage ?? 0).toString());
    final linkType = (existing?.linkType ?? 'web').obs;
    final validFrom = (existing?.validFrom ?? DateTime.now()).obs;
    final validUntil = (existing?.validUntil ?? DateTime.now().add(const Duration(days: 14))).obs;
    final priority = (existing?.priority ?? 0).obs;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Promotion'.tr : 'Create Promotion'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title'.tr, border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: 'Description'.tr, border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              _BannerImagePicker(imageCtrl: imageCtrl),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                value: linkType.value,
                decoration: InputDecoration(labelText: 'Link Type'.tr, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'web', child: Text('Website'.tr)),
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube'.tr)),
                  DropdownMenuItem(value: 'telegram', child: Text('Telegram'.tr)),
                  DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp'.tr)),
                  DropdownMenuItem(value: 'facebook', child: Text('Facebook'.tr)),
                  DropdownMenuItem(value: 'instagram', child: Text('Instagram'.tr)),
                  DropdownMenuItem(value: 'none', child: Text('No Link'.tr)),
                ],
                onChanged: (v) => linkType.value = v!,
              )),
              const SizedBox(height: 12),
              TextField(controller: linkUrlCtrl, decoration: InputDecoration(labelText: 'Link URL'.tr, hintText: 'https://...', border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: buttonTextCtrl, decoration: InputDecoration(labelText: 'Button Text'.tr, border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: discountCodeCtrl, decoration: InputDecoration(labelText: 'Discount Code'.tr, border: const OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: discountPctCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Discount %'.tr, border: const OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _DatePickerField(
                      label: 'Valid From'.tr,
                      date: validFrom.value,
                      onPick: (d) => validFrom.value = d,
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _DatePickerField(
                      label: 'Valid Until'.tr,
                      date: validUntil.value,
                      onPick: (d) => validUntil.value = d,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<int>(
                value: priority.value,
                decoration: InputDecoration(labelText: 'Priority'.tr, border: const OutlineInputBorder()),
                items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text('${'Priority'.tr} $i'))),
                onChanged: (v) => priority.value = v!,
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: scheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    final draft = PromotionModel(
                      id: existing?.id ?? '',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      imageUrl: imageCtrl.text.trim(),
                      linkType: linkType.value,
                      linkUrl: linkUrlCtrl.text.trim(),
                      buttonText: buttonTextCtrl.text.trim().isEmpty ? 'Learn More' : buttonTextCtrl.text.trim(),
                      discountCode: discountCodeCtrl.text.trim().isEmpty ? null : discountCodeCtrl.text.trim(),
                      discountPercentage: double.tryParse(discountPctCtrl.text) ?? 0,
                      validFrom: validFrom.value,
                      validUntil: validUntil.value,
                      priority: priority.value,
                      isActive: existing?.isActive ?? true,
                      views: existing?.views ?? 0,
                      clicks: existing?.clicks ?? 0,
                      createdAt: existing?.createdAt ?? '',
                    );
                    if (isEdit) {
                      PromotionController.to.updatePromotion(draft);
                    } else {
                      PromotionController.to.createPromotion(draft);
                    }
                    Get.back();
                  },
                  child: Text(isEdit ? 'Update Promotion'.tr : 'Create Promotion'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _BannerImagePicker extends StatelessWidget {
  final TextEditingController imageCtrl;
  const _BannerImagePicker({required this.imageCtrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> pick(bool fromCamera) async {
      final url = await PromotionController.to.uploadBannerImage(fromCamera: fromCamera);
      if (url != null) imageCtrl.text = url;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: imageCtrl,
      builder: (context, value, _) {
        final hasImage = value.text.trim().isNotEmpty;

        return Obx(() {
          final uploading = PromotionController.to.isUploadingImage.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Banner Image'.tr, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 2.4,
                  child: Container(
                    color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerHighest.withOpacity(0.5),
                    child: uploading
                        ? const Center(child: CircularProgressIndicator.adaptive())
                        : hasImage
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          value.text,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant, size: 32),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Colors.black.withOpacity(0.5),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => imageCtrl.clear(),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Center(
                      child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: uploading ? null : () => pick(false),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text('Gallery'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: uploading ? null : () => pick(true),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: Text('Camera'.tr),
                    ),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DatePickerField({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(DateFormat('MMM dd, yyyy').format(date)),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromotionModel promo;
  final VoidCallback onEdit;
  const _PromoCard({required this.promo, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = promo.isLive
        ? PillTone.success
        : promo.isExpired
        ? PillTone.error
        : PillTone.warning;
    final label = promo.isLive ? 'Active'.tr : (promo.isExpired ? 'Expired'.tr : 'Inactive'.tr);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promo.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 2.4,
              child: Image.network(
                promo.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: scheme.surfaceContainerHighest),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(promo.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
                    ),
                    StatusPill(text: label, tone: tone),
                  ],
                ),
                if (promo.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(promo.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${promo.views}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(width: 14),
                    Icon(Icons.touch_app_outlined, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${promo.clicks}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const Spacer(),
                    Text(DateFormat('MMM dd').format(promo.validUntil), style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => PromotionController.to.toggleStatus(promo),
                        icon: Icon(promo.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16),
                        label: Text(promo.isActive ? 'Deactivate'.tr : 'Activate'.tr, style: const TextStyle(fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: Icon(Icons.edit_outlined, color: scheme.primary), onPressed: onEdit),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                      onPressed: () => _confirmDelete(context, promo.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Promotion'.tr),
        content: Text('Are you sure you want to delete this promotion?'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Get.back();
              PromotionController.to.deletePromotion(id);
            },
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );
  }
}