import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../../data/models/user_model.dart';

class UserManagementScreen extends GetView<UserManagementController> {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUsername = Get.find<AuthController>().username.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                expandedHeight: 190,
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 4,
                surfaceTintColor: scheme.surface,
                backgroundColor: scheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: _handleBackNavigation,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: controller.refresh,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                  title: Text(
                    'Manage Users'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _UserManagementHeaderPainter(
                          primaryColor: scheme.primary,
                          secondaryColor: scheme.tertiary,
                          isDark: isDark,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.15), Colors.transparent, Colors.black.withOpacity(0.35)],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20, right: 20, bottom: 52,
                        child: Obx(() {
                          final total = controller.users.length;
                          final admins = controller.adminCount;
                          return Row(
                            children: [
                              Expanded(child: _HeroStat(label: 'Total Users'.tr, value: '$total', icon: Icons.people_alt_rounded)),
                              Container(width: 1, height: 34, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 14)),
                              Expanded(child: _HeroStat(label: 'Admins'.tr, value: '$admins', icon: Icons.admin_panel_settings_rounded)),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: controller.search,
                    decoration: InputDecoration(
                      hintText: 'Search by username or phone'.tr,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              Obx(() {
                if (controller.isLoading.value && controller.users.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator.adaptive()));
                }
                final users = controller.filteredUsers;
                if (users.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(icon: Icons.people_outline_rounded, title: 'No users found'.tr, subtitle: ''),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserCard(
                        user: user,
                        isSelf: user.username.toLowerCase() == currentUsername.toLowerCase(),
                      ).animate().fadeIn(delay: (30 * index).ms, duration: 250.ms);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    if (Navigator.of(Get.context!).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed('/dashboard'); // Change '/dashboard' to your primary home route if different
    }
  }
}
class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _HeroStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final bool isSelf;
  const _UserCard({required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = user.role.trim().toLowerCase() == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
       // border: Border.all(color: isAdmin ? scheme.primary.withOpacity(0.3) : Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isAdmin ? scheme.primary.withOpacity(0.15) : scheme.surfaceContainerHighest,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? scheme.primary : scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.username, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: scheme.onSurface)),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('You'.tr, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: scheme.primary)),
                      ),
                    ],
                  ],
                ),
                if ((user.phone ?? '').isNotEmpty)
                  Text(user.phone!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAdmin ? scheme.primary.withOpacity(0.12) : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAdmin ? 'Admin'.tr : 'Customer'.tr,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isAdmin ? scheme.primary : scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final busy = UserManagementController.to.updatingUsername.value == user.username;
            return SizedBox(
              width: 96,
              child: busy
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : OutlinedButton(
                onPressed: isSelf && isAdmin ? null : () => _confirm(context, user, isAdmin),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isAdmin ? scheme.error : scheme.primary,
                  side: BorderSide(color: isAdmin ? scheme.error.withOpacity(0.4) : scheme.primary.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  isAdmin ? 'Remove'.tr : 'Make Admin'.tr,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, User user, bool isAdmin) {
    Get.dialog(
      AlertDialog(
        title: Text(isAdmin ? 'Remove Admin Access'.tr : 'Grant Admin Access'.tr),
        content: Text(
          isAdmin
              ? '${'Are you sure you want to remove admin access from'.tr} ${user.username}?'
              : '${'Are you sure you want to make'.tr} ${user.username} ${'an admin? They will be able to manage products, sales, orders, and settings.'.tr}',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            onPressed: () {
              Get.back();
              UserManagementController.to.toggleAdmin(user);
            },
            child: Text(isAdmin ? 'Remove'.tr : 'Make Admin'.tr),
          ),
        ],
      ),
    );
  }
}

class _UserManagementHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;
  _UserManagementHeaderPainter({required this.primaryColor, required this.secondaryColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final gradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
    }
    glassOrb(Offset(width * 0.85, height * 0.15), 90, Colors.white, 0.15, 50);
    glassOrb(Offset(width * 0.12, height * 0.8), 70, secondaryColor, 0.28, 45);

    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
        stops: const [0.45, 1.0],
      ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _UserManagementHeaderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor || oldDelegate.isDark != isDark;
}