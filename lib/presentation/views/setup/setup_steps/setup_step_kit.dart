import 'package:flutter/material.dart';

/// Title + subtitle used at the top of every wizard step.
class StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const StepHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: scheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A rounded card container used to group a section of a step.
class SetupCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SetupCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Green (valid) / amber (needs attention) status banner shown at the
/// bottom of most steps.
class ValidationBanner extends StatelessWidget {
  final bool isValid;
  final String validText;
  final String invalidText;

  const ValidationBanner({
    super.key,
    required this.isValid,
    required this.validText,
    required this.invalidText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fg = isValid
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309));
    final Color bg = isValid
        ? (isDark ? const Color(0xFF14251A) : const Color(0xFFEFFDF3))
        : (isDark ? const Color(0xFF2A2110) : const Color(0xFFFFF7E8));
    final Color border = fg.withOpacity(isDark ? 0.35 : 0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle_rounded : Icons.info_rounded, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isValid ? validText : invalidText,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled row inside a SetupCard (e.g. "Currency" -> dropdown).
class SetupFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const SetupFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(text: text),
            if (required) TextSpan(text: '  *', style: TextStyle(color: scheme.error)),
          ],
        ),
      ),
    );
  }
}