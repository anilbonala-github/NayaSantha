import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Layout breakpoints. Mobile is the primary target; web gets a wider shell.
class Breakpoints {
  Breakpoints._();
  static const double tablet = 720;
  static const double desktop = 1100;

  static bool isMobile(BuildContext c) =>
      MediaQuery.sizeOf(c).width < tablet;
  static bool isTablet(BuildContext c) {
    final double w = MediaQuery.sizeOf(c).width;
    return w >= tablet && w < desktop;
  }

  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= desktop;
}

final NumberFormat rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String money(num v) => rupees.format(v);

String shortDate(DateTime d) => DateFormat('d MMM').format(d);
String dayTime(DateTime d) => DateFormat('d MMM, h:mm a').format(d);
String timeOnly(DateTime d) => DateFormat('h:mm a').format(d);

/// 1248 -> "1,248". Keeps large review counts readable.
String ratingCountLabel(int n) => NumberFormat.decimalPattern('en_IN').format(n);

String relative(DateTime d) {
  final Duration diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return shortDate(d);
}

/// Constrains page content on wide screens so web does not stretch to 2000px.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.maxWidth = 1080,
    this.padding = const EdgeInsets.all(Gap.lg),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Standard bordered card used everywhere in place of Material elevation.
class NsCard extends StatelessWidget {
  const NsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.lg),
      onTap: onTap,
      child: content,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Status pill used for order states, stock states and plan badges.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular produce tile used instead of photography in the mock data set.
class ProduceAvatar extends StatelessWidget {
  const ProduceAvatar({
    super.key,
    required this.emoji,
    this.size = 48,
    this.background = AppColors.surfaceMuted,
  });

  final String emoji;
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
    );
  }
}

/// Compact -/quantity/+ stepper matching the basket mock.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.compact = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double h = compact ? 32 : 38;
    return Container(
      height: h,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove,
            size: h,
            onTap: () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: compact ? 26 : 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            size: h,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: 16, color: AppColors.forest),
      ),
    );
  }
}

/// Empty states are an invitation to act, so each one carries a primary action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: Gap.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Gap.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: Gap.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Brand lockup used on splash, welcome and the web header.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.size = 28, this.showTagline = false});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: size * 1.15,
              height: size * 1.15,
              decoration: const BoxDecoration(
                gradient: AppColors.leafGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco, color: Colors.white, size: size * 0.7),
            ),
            SizedBox(width: size * 0.32),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: const <TextSpan>[
                  TextSpan(
                      text: 'Naya', style: TextStyle(color: AppColors.leaf)),
                  TextSpan(
                      text: 'Santha',
                      style: TextStyle(color: AppColors.forest)),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...<Widget>[
          SizedBox(height: size * 0.25),
          Text(
            'Your AI-Powered Weekly Market',
            style: TextStyle(
              fontSize: size * 0.45,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Inline AI framing so users always know when a suggestion is model-generated.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'AI'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.leafGradient,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple bar chart used on the budget screen — no charting dependency needed.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
  });

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double max =
        values.isEmpty ? 1 : values.reduce((double a, double b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(values.length, (int i) {
          final double ratio = max == 0 ? 0 : values[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    money(values[i]),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: (height - 46) * ratio,
                    decoration: BoxDecoration(
                      gradient: AppColors.leafGradient,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
