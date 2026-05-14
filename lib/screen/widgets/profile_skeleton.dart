import 'package:flutter/material.dart';

import 'constant.dart';
import 'profile_detail_theme.dart';

/// Single animated “bone” for profile skeletons (subtle shimmer on brand-neutral grays).
class ProfileSkeletonBone extends StatelessWidget {
  const ProfileSkeletonBone({
    super.key,
    required this.listenable,
    this.width,
    required this.height,
    this.borderRadius = 10,
    this.circular = false,
  });

  final Listenable listenable;
  final double? width;
  final double height;
  final double borderRadius;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (width == null || width == double.infinity) ? constraints.maxWidth : width!;
        return AnimatedBuilder(
          animation: listenable,
          builder: (context, _) {
            final t = (listenable as Animation<double>).value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(circular ? height / 2 : borderRadius),
              child: SizedBox(
                width: w,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.4 + 2.8 * t, 0),
                      end: Alignment(-0.4 + 2.8 * t, 0),
                      colors: [
                        kBorderColorTextField.withValues(alpha: 0.35),
                        kWhite.withValues(alpha: 0.92),
                        kBorderColorTextField.withValues(alpha: 0.35),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shimmer host — owns one [AnimationController] shared by all bones in the subtree.
class ProfileSkeletonHost extends StatefulWidget {
  const ProfileSkeletonHost({super.key, required this.child});

  final Widget Function(BuildContext context, Animation<double> shimmer) child;

  @override
  State<ProfileSkeletonHost> createState() => _ProfileSkeletonHostState();
}

class _ProfileSkeletonHostState extends State<ProfileSkeletonHost> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.child(context, _controller),
    );
  }
}

/// Client / seller **tab** profile: header strip + menu rows.
class ProfileTabSkeleton extends StatelessWidget {
  const ProfileTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSkeletonHost(
      child: (context, shimmer) {
        return Scaffold(
          backgroundColor: kDarkWhite,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      ProfileSkeletonBone(listenable: shimmer, width: 44, height: 44, circular: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSkeletonBone(listenable: shimmer, width: 160, height: 20, borderRadius: 8),
                            const SizedBox(height: 8),
                            ProfileSkeletonBone(listenable: shimmer, width: 120, height: 14, borderRadius: 6),
                            const SizedBox(height: 6),
                            ProfileSkeletonBone(listenable: shimmer, width: 100, height: 12, borderRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: 9,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) => ProfileSkeletonBone(
                        listenable: shimmer,
                        width: double.infinity,
                        height: 52,
                        borderRadius: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// **My profile** detail screen (avatar, stats, actions, sections).
class ProfileDetailsSkeleton extends StatelessWidget {
  const ProfileDetailsSkeleton({super.key, this.extraSection = false});

  /// Seller layout adds an extra block (e.g. reviews strip).
  final bool extraSection;

  @override
  Widget build(BuildContext context) {
    return ProfileSkeletonHost(
      child: (context, shimmer) {
        return Scaffold(
          backgroundColor: ProfileDetailTheme.scaffoldBg,
          appBar: AppBar(
            backgroundColor: ProfileDetailTheme.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(color: kNeutralColor.withValues(alpha: 0.45)),
            toolbarHeight: 52,
            title: ProfileSkeletonBone(listenable: shimmer, width: 110, height: 18, borderRadius: 8),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              children: [
                Center(
                  child: ProfileSkeletonBone(listenable: shimmer, width: 110, height: 110, circular: true),
                ),
                const SizedBox(height: 14),
                ProfileSkeletonBone(listenable: shimmer, width: 180, height: 22, borderRadius: 8),
                const SizedBox(height: 10),
                ProfileSkeletonBone(listenable: shimmer, width: 140, height: 14, borderRadius: 6),
                const SizedBox(height: 14),
                ProfileSkeletonBone(listenable: shimmer, width: 120, height: 16, borderRadius: 8),
                const SizedBox(height: 22),
                ProfileSkeletonBone(
                  listenable: shimmer,
                  width: double.infinity,
                  height: 72,
                  borderRadius: 16,
                ),
                const SizedBox(height: 20),
                ProfileSkeletonBone(
                  listenable: shimmer,
                  width: double.infinity,
                  height: 48,
                  borderRadius: 12,
                ),
                const SizedBox(height: 24),
                ProfileSkeletonBone(listenable: shimmer, width: 80, height: 4, borderRadius: 2),
                const SizedBox(height: 18),
                ProfileSkeletonBone(listenable: shimmer, width: 140, height: 16, borderRadius: 8),
                const SizedBox(height: 12),
                ProfileSkeletonBone(
                  listenable: shimmer,
                  width: double.infinity,
                  height: 88,
                  borderRadius: 14,
                ),
                const SizedBox(height: 10),
                ProfileSkeletonBone(
                  listenable: shimmer,
                  width: double.infinity,
                  height: 88,
                  borderRadius: 14,
                ),
                if (extraSection) ...[
                  const SizedBox(height: 24),
                  ProfileSkeletonBone(listenable: shimmer, width: 80, height: 4, borderRadius: 2),
                  const SizedBox(height: 18),
                  ProfileSkeletonBone(listenable: shimmer, width: 100, height: 16, borderRadius: 8),
                  const SizedBox(height: 12),
                  ProfileSkeletonBone(
                    listenable: shimmer,
                    width: double.infinity,
                    height: 96,
                    borderRadius: 14,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
