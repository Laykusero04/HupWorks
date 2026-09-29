import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/profile_image.dart';

/// Full-screen view of a profile photo. Pinch to zoom.
void showProfilePhoto(
  BuildContext context, {
  required String? imageUrl,
}) {
  final url = ProfileImage.normalize(imageUrl);
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    pageBuilder: (dialogContext, _, __) {
      return SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image(
                  image: url != null
                      ? NetworkImage(url)
                      : const AssetImage(ProfileImage.fallbackAsset)
                          as ImageProvider,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    ProfileImage.fallbackAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}
