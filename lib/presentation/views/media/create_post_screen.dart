// lib/presentation/views/media/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/media_controller.dart';
import '../../controllers/product_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/bottom_nav_bar.dart';

class CreatePostScreen extends GetView<MediaController> {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final productController = Get.find<ProductController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final captionController = TextEditingController();
    final selectedType = 'photo'.obs; // 'photo' or 'video'
    final selectedProduct = Rxn<Product>();

    return Scaffold(
      bottomNavigationBar: BottomNavBar(currentIndex: 2,),
      appBar: AppBar(
        title: Text('New Post'.tr),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isUploading.value) {
          final isVideo = selectedType.value == 'video';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isVideo && controller.uploadProgress.value > 0) ...[
                    CircularProgressIndicator(value: controller.uploadProgress.value),
                    const SizedBox(height: 20),
                    Text('Compressing video... ${(controller.uploadProgress.value * 100).toStringAsFixed(0)}%'.tr),
                  ] else ...[
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 20),
                    Text(isVideo ? 'Uploading video...'.tr : 'Uploading photo...'.tr),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'This can take a moment for larger files.'.tr,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you posting?'.tr,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface),
              ),
              const SizedBox(height: 12),
              Obx(
                    () => Row(
                  children: [
                    Expanded(
                      child: _TypeCard(
                        icon: Icons.photo_rounded,
                        label: 'Photo'.tr,
                        selected: selectedType.value == 'photo',
                        onTap: () => selectedType.value = 'photo',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeCard(
                        icon: Icons.videocam_rounded,
                        label: 'Video'.tr,
                        selected: selectedType.value == 'video',
                        onTap: () => selectedType.value = 'video',
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 8),
              Obx(
                    () => selectedType.value == 'video'
                    ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Videos over ${MediaController.maxVideoSizeMb}MB are compressed automatically before posting.'.tr,
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Caption'.tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: captionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write something about this post...'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 16),

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Link a Product (optional)'.tr,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface),
                          ),
                        ),
                        Obx(
                              () => selectedProduct.value != null
                              ? TextButton(
                            onPressed: () => selectedProduct.value = null,
                            child: Text('Clear'.tr),
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Obx(
                            () => DropdownButtonFormField<Product>(
                          // isExpanded + a single-line Text item, no
                          // Expanded/Row inside — avoids the RenderFlex
                          // "hasSize" crash dropdowns are prone to.
                          isExpanded: true,
                          value: selectedProduct.value,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            prefixIcon: Icon(Icons.inventory_2_rounded, color: scheme.primary),
                          ),
                          hint: Text('None — general post'.tr),
                          items: productController.products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (product) => selectedProduct.value = product,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(
                      () => ElevatedButton.icon(
                    onPressed: () {
                      if (selectedType.value == 'photo') {
                        controller.createPhotoPost(
                          caption: captionController.text,
                          productId: selectedProduct.value?.id,
                          productName: selectedProduct.value?.name,
                        );
                      } else {
                        controller.createVideoPost(
                          caption: captionController.text,
                          productId: selectedProduct.value?.id,
                          productName: selectedProduct.value?.name,
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: Text(
                      selectedType.value == 'photo' ? 'Choose Photo & Post'.tr : 'Choose Video & Post'.tr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: 16),

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Manage Posts'.tr,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface),
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.posts.length}',
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.isLoading.value && controller.posts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator.adaptive()),
                        );
                      }
                      if (controller.posts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No posts yet.'.tr,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.posts.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.4)),
                        itemBuilder: (context, index) {
                          final post = controller.posts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: post.thumbnailUrl.isNotEmpty
                                      ? Image.network(
                                    post.thumbnailUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: scheme.surfaceContainerHighest,
                                      child: Icon(
                                        post.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                      : Container(
                                    width: 48,
                                    height: 48,
                                    color: scheme.surfaceContainerHighest,
                                    child: Icon(
                                      post.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.caption.isEmpty ? (post.isVideo ? 'Video post'.tr : 'Photo post'.tr) : post.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                                      ),
                                      if (post.productName.isNotEmpty)
                                        Text(
                                          post.productName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                                  onPressed: () => controller.deletePost(post),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withOpacity(0.12) : scheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}