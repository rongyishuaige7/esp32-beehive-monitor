import 'package:flutter/material.dart';

enum BadgeStyle { ok, warn, bad, muted }

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.valueText,
    this.unit,
    this.subtitle,
    this.description,
    this.badgeText,
    this.badgeStyle = BadgeStyle.ok,
    this.fullWidth = false,
  });

  final String icon;
  final String title;
  final String valueText;
  final String? unit;
  final String? subtitle;
  final String? description;
  final String? badgeText;
  final BadgeStyle badgeStyle;
  final bool fullWidth;

  @override
  Widget build(BuildContext _) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2D8C9).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A3B2C),
                    ),
                  ),
                ),
                if (badgeText != null)
                  _Badge(text: badgeText!, style: badgeStyle),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color(0xFF2D1F11),
                  ),
                ),
                if (unit != null && unit!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E8E7A),
                    ),
                  ),
                ],
              ],
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E8E7A),
                ),
              ),
            ],
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7A66),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: card);
    }
    return card;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.style});

  final String text;
  final BadgeStyle style;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (style) {
      case BadgeStyle.ok:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
      case BadgeStyle.warn:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
      case BadgeStyle.bad:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
      case BadgeStyle.muted:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
