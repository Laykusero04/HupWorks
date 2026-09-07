import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Circular profile avatar with optional camera badge + tap-to-change.
class EditableProfileAvatar extends StatelessWidget {
  const EditableProfileAvatar({
    super.key,
    required this.imageUrl,
    this.size = 110,
    this.accent = kPrimaryColor,
    this.onTap,
    this.uploading = false,
    this.showCameraBadge = true,
  });

  final String? imageUrl;
  final double size;
  final Color accent;
  final VoidCallback? onTap;
  final bool uploading;
  final bool showCameraBadge;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.28;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
                image: DecorationImage(
                  image: ProfileImage.provider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (uploading)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: kWhite,
                  ),
                ),
              )
            else if (showCameraBadge && onTap != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhite, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: badgeSize * 0.5,
                    color: kWhite,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
