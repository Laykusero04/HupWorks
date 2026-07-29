import 'package:flutter/material.dart';

import 'profile_skeleton.dart';

/// Loading placeholder for [NotificationListScreen] (matches list tile layout).
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ProfileSkeletonHost(
      child: (context, shimmer) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          itemCount: itemCount,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileSkeletonBone(
                  listenable: shimmer,
                  width: 44,
                  height: 44,
                  circular: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileSkeletonBone(listenable: shimmer, height: 14, borderRadius: 6),
                      const SizedBox(height: 10),
                      ProfileSkeletonBone(
                        listenable: shimmer,
                        width: double.infinity,
                        height: 11,
                        borderRadius: 5,
                      ),
                      const SizedBox(height: 6),
                      ProfileSkeletonBone(
                        listenable: shimmer,
                        width: 72,
                        height: 10,
                        borderRadius: 5,
                      ),
                    ],
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

/// Compact skeleton for pagination at the bottom of the list.
class NotificationListLoadMoreSkeleton extends StatelessWidget {
  const NotificationListLoadMoreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: NotificationListSkeleton(itemCount: 2),
    );
  }
}
