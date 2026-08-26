import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/favourite_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../buyer request/buyer_request_details.dart';

class SellerFavList extends StatefulWidget {
  const SellerFavList({Key? key}) : super(key: key);

  @override
  State<SellerFavList> createState() => _SellerFavListState();
}

class _SellerFavListState extends State<SellerFavList> {
  List<Map<String, dynamic>> _favourites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    try {
      final favs = await FavouriteService.getFavourites();
      if (mounted) {
        setState(() {
          _favourites = favs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _handleRemoveFavourite(String favId, int index) async {
    try {
      await FavouriteService.removeFavourite(favId);
      if (mounted) {
        setState(() => _favourites.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.removedFromFavourites)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  String _jobTypeLabel(String? type) {
    switch (type) {
      case 'full_time':
        return 'Full time';
      case 'part_time':
        return 'Part time';
      case 'gig':
        return 'Gig';
      default:
        return type ?? 'Job';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.favouriteList,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _favourites.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noFavouritesYet,
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadFavourites,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _favourites.length,
                        itemBuilder: (_, i) {
                          final fav = _favourites[i];
                          final job = fav['job_posts'] as Map<String, dynamic>?;
                          if (job == null) return const SizedBox.shrink();

                          final category = job['categories'] as Map<String, dynamic>?;
                          final client = (job['client'] ?? job['profiles']) as Map<String, dynamic>?;
                          final jobId = job['id'] as String? ?? fav['job_post_id'] as String?;
                          final status = (job['status'] as String?) ?? 'open';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Material(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(8.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8.0),
                                onTap: jobId == null
                                    ? null
                                    : () => BuyerRequestDetails(jobPostId: jobId).launch(context),
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: kBorderColorTextField),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              job['title'] ?? 'Job',
                                              style: kTextStyle.copyWith(
                                                color: kNeutralColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: l10n.removedFromFavourites,
                                            onPressed: () => _handleRemoveFavourite(fav['id'] as String, i),
                                            icon: Icon(
                                              Icons.bookmark,
                                              color: kPrimaryColor,
                                              size: 22,
                                            ),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      if ((job['description'] as String?)?.isNotEmpty ?? false) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          job['description'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              color: kDarkWhite,
                                            ),
                                            child: Text(
                                              category?['name'] ?? 'General',
                                              style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              color: kPrimaryColor.withValues(alpha: 0.08),
                                            ),
                                            child: Text(
                                              _jobTypeLabel(job['job_type'] as String?),
                                              style: kTextStyle.copyWith(
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              color: status == 'open'
                                                  ? const Color(0xFFE8F5E9)
                                                  : kDarkWhite,
                                            ),
                                            child: Text(
                                              status,
                                              style: kTextStyle.copyWith(
                                                color: status == 'open'
                                                    ? const Color(0xFF2E7D32)
                                                    : kSubTitleColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (job['budget_min'] != null || job['budget_max'] != null)
                                            Text(
                                              JobPostsService.formatBudgetRangeShort(
                                                job['budget_min'],
                                                job['budget_max'],
                                                job['budget_basis'],
                                              ),
                                              style: kTextStyle.copyWith(
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (client != null) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundImage: client['profile_image_url'] != null
                                                  ? NetworkImage(client['profile_image_url'] as String)
                                                  : const AssetImage('images/profilepic2.png')
                                                      as ImageProvider,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                client['name'] as String? ?? l10n.authRoleClient,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: kTextStyle.copyWith(
                                                  color: kNeutralColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
