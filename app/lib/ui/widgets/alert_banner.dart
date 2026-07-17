import 'package:flutter/material.dart';

/// Displays a local fixed-threshold label only; it is deliberately not an alert.
class SampleLabelBanner extends StatelessWidget {
  const SampleLabelBanner({super.key, required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null || label == 'reference') return const SizedBox.shrink();
    final unavailable = label == 'unavailable';
    final high = label == 'high_threshold';
    final text = unavailable
        ? '当前响应中有字段未取得有效读数；不显示旧值，也不作状态结论。'
        : high
        ? '固定阈值标签：有输入超过源码演示区间，请按实物和实验目的自行核对。'
        : '固定阈值标签：部分输入偏离源码参考区间。';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: unavailable
            ? const Color(0xFFF3F4F6)
            : high
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unavailable
              ? const Color(0xFFD1D5DB)
              : high
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unavailable
                ? Icons.info_outline_rounded
                : high
                ? Icons.info_outline_rounded
                : Icons.tips_and_updates_outlined,
            color: unavailable
                ? const Color(0xFF4B5563)
                : high
                ? const Color(0xFF991B1B)
                : const Color(0xFF92400E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: unavailable
                    ? const Color(0xFF4B5563)
                    : high
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
