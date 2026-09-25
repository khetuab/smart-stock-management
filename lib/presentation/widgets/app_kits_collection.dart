import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared, theme-aware building blocks used across Products, Sales, and
/// Categories screens. Same conventions as `setup_step_kit.dart` /
/// `dashboard_kit.dart`: everything reads from `Theme.of(context)` instead
/// of hardcoding `Colors.grey` / `Colors.white` / raw hex, so these screens
/// stay correct in dark mode and follow whatever brand color the merchant
/// picks in Theme setup.

/// A rounded, bordered content container — the general-purpose equivalent
/// of `SetupCard` for non-setup screens.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
       // border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

/// Small colored info tile (icon + label + value) — used for stat rows like
/// "Stock Status", "Quantity", "Purchase Price" on Product Detail.
class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.tr,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.tr,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Label/value row inside a `SectionCard` (Sale ID, Product Name, Date, etc).
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.tr, style: TextStyle(color: scheme.onSurfaceVariant)),
          Flexible(
            child: Text(
              value.tr,
              style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum PillTone { success, warning, error, neutral }

/// Semantic status pill (e.g. "COMPLETED", "Low", "CANCELLED").
/// Reuses the same success/warning color logic as `ValidationBanner`.
class StatusPill extends StatelessWidget {
  final String text;
  final PillTone tone;

  const StatusPill({super.key, required this.text, this.tone = PillTone.neutral});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late Color fg;
    switch (tone) {
      case PillTone.success:
        fg = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
        break;
      case PillTone.warning:
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        break;
      case PillTone.error:
        fg = scheme.error;
        break;
      case PillTone.neutral:
        fg = scheme.onSurfaceVariant;
        break;
    }
    final bg = fg.withOpacity(isDark ? 0.18 : 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text.tr, style: TextStyle(fontSize: 11.5, color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

/// Full-page empty state (no products, no sales, no categories...).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle.tr,
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!.tr),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 46)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin "manage X" affordance row (used under the Add Product form).
class InlineLinkRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const InlineLinkRow({super.key, required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(text.tr, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Image / placeholder box, reused by product forms, product detail,
/// product cards, and the point-of-sale grid.
class ProductImageBox extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double borderRadius;
  final IconData placeholderIcon;
  final double placeholderSize;

  const ProductImageBox({
    super.key,
    required this.imageUrl,
    this.height = 100,
    this.borderRadius = 12,
    this.placeholderIcon = Icons.inventory_2_rounded,
    this.placeholderSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = Theme.of(context).inputDecorationTheme.fillColor ?? scheme.surfaceVariant;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        image: imageUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl.isEmpty
          ? Icon(placeholderIcon, size: placeholderSize, color: scheme.onSurfaceVariant)
          : null,
    );
  }
}