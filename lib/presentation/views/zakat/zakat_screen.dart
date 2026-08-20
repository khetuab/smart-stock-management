import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/zakat_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/bottom_nav_bar.dart';

class ZakatScreen extends GetView<ZakatController> {
  const ZakatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        if (!controller.isZakatEnabled.value) {
          return Scaffold(
            appBar: AppBar(
              title: Text('zakatCalculationTitle'.tr),
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
            ),
            body: AppEmptyState(
              icon: Icons.mosque_outlined,
              title: 'zakatFeatureDisabledTitle'.tr,
              subtitle: 'zakatFeatureDisabledSubtitle'.tr,
              actionLabel: 'goToSettingsButton'.tr,
              onAction: () => Get.toNamed('/settings'),
            ),
          );
        }

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final isAboveNisab = controller.isAboveNisab.value;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // --- Islamic Mesh Painter SliverAppBar (Height: 220) ---
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 4,
              surfaceTintColor: scheme.surface,
              backgroundColor: scheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bookmark_outline_rounded, color: Colors.white),
                  tooltip: 'saveZakatRecordTooltip'.tr,
                  onPressed: () {
                    controller.saveZakatData();
                    Get.snackbar(
                      'recordSavedTitle'.tr,
                      'recordSavedMessage'.tr,
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 16,
                      backgroundColor: scheme.primaryContainer,
                      colorText: scheme.onPrimaryContainer,
                      icon: Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Row(
                  children: [
                    Text(
                      'zakatCalculationTitle'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Dynamic Mesh Header Painter with Islamic Geometry
                    CustomPaint(
                      painter: _IslamicMeshHeaderPainter(
                        primaryColor: scheme.primary,
                        secondaryColor: scheme.tertiary,
                        isDark: isDark,
                      ),
                    ),

                    // Dark Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),

                    // Crescent Motif Accent
                    Positioned(
                      right: -10,
                      top: 15,
                      child: Icon(
                        Icons.nights_stay_rounded,
                        size: 130,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),

                    // Calligraphic Header Details
                    Positioned(
                      left: 20,
                      bottom: 48,
                      right: 20,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFBBF24).withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFFBBF24),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'زكاة المال • Purify Your Wealth',
                                  style: TextStyle(
                                    color: const Color(0xFFFEF08A).withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const Text(
                                  'Islamic Asset & Nisab Calculator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Main Content ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Hero Zakat Summary Card (Emerald / Gold Aesthetics) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAboveNisab
                              ? [
                            scheme.primary,
                            scheme.primary.withOpacity(0.85),
                          ]
                              : [
                            isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest,
                            isDark
                                ? scheme.surfaceContainerHighest
                                : scheme.surfaceContainerHigh,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isAboveNisab
                                ? scheme.primary.withOpacity(0.25)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Background Star Motif
                          Positioned(
                            right: -15,
                            bottom: -15,
                            child: Icon(
                              Icons.star_outline_rounded,
                              size: 110,
                              color: isAboveNisab
                                  ? Colors.white.withOpacity(0.08)
                                  : scheme.onSurface.withOpacity(0.03),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.balance_rounded,
                                        size: 16,
                                        color: isAboveNisab
                                            ? const Color(0xFFFBBF24)
                                            : scheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'zakatPayableLabel'.tr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isAboveNisab
                                              ? scheme.onPrimary.withOpacity(0.85)
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAboveNisab
                                          ? const Color(0xFFFBBF24).withOpacity(0.2)
                                          : scheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isAboveNisab
                                          ? Border.all(
                                        color: const Color(0xFFFBBF24).withOpacity(0.4),
                                      )
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAboveNisab
                                              ? Icons.check_circle_rounded
                                              : Icons.info_outline_rounded,
                                          size: 12,
                                          color: isAboveNisab
                                              ? const Color(0xFFFEF08A)
                                              : scheme.onErrorContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAboveNisab
                                              ? 'aboveNisabStatus'.tr
                                              : 'belowNisabStatus'.tr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isAboveNisab
                                                ? const Color(0xFFFEF08A)
                                                : scheme.onErrorContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dashboardController.formatCurrency(controller.zakatDue.value),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isAboveNisab ? scheme.onPrimary : scheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Divider(
                                color: isAboveNisab
                                    ? scheme.onPrimary.withOpacity(0.2)
                                    : scheme.outlineVariant.withOpacity(0.5),
                                height: 1,
                              ),
                              const SizedBox(height: 14),

                              // Metrics row inside hero
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _HeroStatColumn(
                                    label: 'totalNetAssetsLabel'.tr,
                                    value: dashboardController
                                        .formatCurrency(controller.totalAssets.value),
                                    isAboveNisab: isAboveNisab,
                                    scheme: scheme,
                                  ),
                                  _HeroStatColumn(
                                    label: 'nisabThresholdLabel'.tr,
                                    value: dashboardController
                                        .formatCurrency(controller.nisabThreshold.value),
                                    isAboveNisab: isAboveNisab,
                                    scheme: scheme,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Inventory Value Readonly Card ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: scheme.primary.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: scheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'currentStockInventoryValueLabel'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  dashboardController
                                      .formatCurrency(controller.inventoryValue.value),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'autoCalcBadge'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: Color(0xFFD97706), // Gold Accent
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'liquidAssetsAndValuationsTitle'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Input Fields List ---
                    _ZakatInputField(
                      label: 'cashInHandLabel'.tr,
                      value: controller.cashInput.value,
                      icon: Icons.payments_outlined,
                      onChanged: controller.updateCash,
                      isDark: isDark,
                      scheme: scheme,
                    ),

                    const SizedBox(height: 12),

                    _ZakatInputField(
                      label: 'bankAccountBalanceLabel'.tr,
                      value: controller.bankInput.value,
                      icon: Icons.account_balance_outlined,
                      onChanged: controller.updateBank,
                      isDark: isDark,
                      scheme: scheme,
                    ),

                    const SizedBox(height: 12),

                    _ZakatInputField(
                      label: 'goldValuationLabel'.tr,
                      value: controller.goldInput.value,
                      icon: Icons.savings_outlined,
                      onChanged: controller.updateGold,
                      isDark: isDark,
                      scheme: scheme,
                    ),

                    const SizedBox(height: 12),

                    _ZakatInputField(
                      label: 'silverValuationLabel'.tr,
                      value: controller.silverInput.value,
                      icon: Icons.diamond_outlined,
                      onChanged: controller.updateSilver,
                      isDark: isDark,
                      scheme: scheme,
                    ),

                    const SizedBox(height: 12),

                    _ZakatInputField(
                      label: 'otherAssetsLabel'.tr,
                      value: controller.otherAssetsInput.value,
                      icon: Icons.pie_chart_outline_rounded,
                      onChanged: controller.updateOtherAssets,
                      isDark: isDark,
                      scheme: scheme,
                    ),

                    const SizedBox(height: 24),

                    // --- Informational Note Banner ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHigh
                            : const Color(0xFFFEF3C7).withOpacity(0.5), // Subtle Amber Background
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome_outlined,
                            size: 20,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'aboutZakatCalculationTitle'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'aboutZakatCalculationDescription'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 7),
    );
  }
}

// --- Dashboard Style Custom Painter with Islamic Geometric Ring Motifs ---
class _IslamicMeshHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _IslamicMeshHeaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final meshGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
        HSLColor.fromColor(secondaryColor).withLightness(isDark ? 0.14 : 0.30).toColor(),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = meshGradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    glassOrb(Offset(width * 0.88, height * 0.10), 130, Colors.white, 0.14, 70);
    glassOrb(Offset(width * 0.15, height * 0.85), 100, secondaryColor, 0.30, 60);
    glassOrb(Offset(width * 0.55, height * 0.05), 70, const Color(0xFFFBBF24), 0.15, 40);

    final sheenPath = Path()
      ..moveTo(width * 0.35, -20)
      ..lineTo(width * 0.55, -20)
      ..lineTo(width * 0.05, height + 20)
      ..lineTo(width * -0.15, height + 20)
      ..close();
    canvas.drawPath(
      sheenPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect),
    );

    // Islamic Concentric Geometric Rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(Offset(width * 0.88, height * 0.30), 34, ringPaint);
    canvas.drawCircle(Offset(width * 0.88, height * 0.30), 52, ringPaint..color = Colors.white.withOpacity(0.08));
    canvas.drawCircle(Offset(width * 0.88, height * 0.30), 70, ringPaint..color = const Color(0xFFFBBF24).withOpacity(0.05));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _IslamicMeshHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}

class _HeroStatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool isAboveNisab;
  final ColorScheme scheme;

  const _HeroStatColumn({
    required this.label,
    required this.value,
    required this.isAboveNisab,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isAboveNisab
                ? scheme.onPrimary.withOpacity(0.75)
                : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isAboveNisab ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ZakatInputField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Function(String) onChanged;
  final bool isDark;
  final ColorScheme scheme;

  const _ZakatInputField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    required this.isDark,
    required this.scheme,
  });

  @override
  State<_ZakatInputField> createState() => _ZakatInputFieldState();
}

class _ZakatInputFieldState extends State<_ZakatInputField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ZakatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _textController.text && widget.value != oldWidget.value) {
      _textController.text = widget.value;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? widget.scheme.surfaceContainerHigh
            : widget.scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _textController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: widget.scheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: widget.scheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(widget.icon, size: 20, color: widget.scheme.primary),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}