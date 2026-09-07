import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Do / Don't example cards for photo and ID guidelines.
class VerificationGuidelineExamples extends StatelessWidget {
  const VerificationGuidelineExamples({
    super.key,
    required this.doAsset,
    required this.dontAsset,
    required this.doLabel,
    required this.dontLabel,
    this.tips = const [],
  });

  final String doAsset;
  final String dontAsset;
  final String doLabel;
  final String dontLabel;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _ExampleCard(asset: doAsset, label: doLabel, good: true)),
            const SizedBox(width: 12),
            Expanded(child: _ExampleCard(asset: dontAsset, label: dontLabel, good: false)),
          ],
        ),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.asset,
    required this.label,
    required this.good,
  });

  final String asset;
  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final color = good ? kPrimaryColor : const Color(0xFFE53935);
    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              good ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
