import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/saved_talent_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../router/route_names.dart';
import '../../widgets/constant.dart';
import '../client talent/freelancer_public_profile.dart';

/// Client saved freelancers (`saved_sellers`).
class ClientFavList extends StatefulWidget {
  const ClientFavList({Key? key}) : super(key: key);

  @override
  State<ClientFavList> createState() => _ClientFavListState();
}

class _ClientFavListState extends State<ClientFavList> {
  List<Map<String, dynamic>> _saved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await SavedTalentService.getSaved();
      if (mounted) {
        setState(() {
          _saved = rows;
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

  Future<void> _handleRemove(String savedId, int index) async {
    try {
      await SavedTalentService.remove(savedId);
      if (mounted) {
        setState(() => _saved.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.removedFromSavedTalent)),
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

  String? _jobTitle(Map<String, dynamic> seller) {
    return ProfileService.sellerJobTitleFromProfile(seller);
  }

  String _location(Map<String, dynamic> seller) {
    return [
      seller['city'] as String?,
      seller['country'] as String?,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
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
          l10n.savedTalentList,
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
              : RefreshIndicator(
                  color: kPrimaryColor,
                  onRefresh: _load,
                  child: _saved.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.15,
                            ),
                            EmptyStateWidget(
                              message: l10n.noSavedTalentYet,
                              hint: l10n.noSavedTalentYetHint,
                              icon: Icons.bookmark_border,
                              actionLabel: l10n.findTalent,
                              onAction: () {
                                Navigator.of(context).pop();
                                context.go(AppRoutes.clientTalent);
                              },
                            ),
                          ],
                        )
                      : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _saved.length,
                        itemBuilder: (_, i) {
                          final row = _saved[i];
                          final sellerRaw = row['seller'];
                          final seller = sellerRaw is Map<String, dynamic>
                              ? sellerRaw
                              : sellerRaw is Map
                                  ? Map<String, dynamic>.from(sellerRaw)
                                  : null;
                          if (seller == null) return const SizedBox.shrink();

                          final sellerId =
                              seller['id'] as String? ?? row['seller_id'] as String?;
                          final name = (seller['name'] as String?)?.trim().isNotEmpty == true
                              ? seller['name'] as String
                              : l10n.talent;
                          final imageUrl = seller['profile_image_url'] as String?;
                          final rating = (seller['rating'] as num?)?.toDouble() ?? 0;
                          final reviewCount = (seller['review_count'] as num?)?.toInt() ?? 0;
                          final jobTitle = _jobTitle(seller);
                          final location = _location(seller);
                          final savedId = row['id'] as String?;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Material(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(8.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8.0),
                                onTap: sellerId == null
                                    ? null
                                    : () async {
                                        await FreelancerPublicProfile(
                                          sellerId: sellerId,
                                          initialName: name,
                                        ).launch(context);
                                        if (mounted) _load();
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: kBorderColorTextField),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: kDarkWhite,
                                        backgroundImage: ProfileImage.provider(imageUrl),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: kTextStyle.copyWith(
                                                color: kNeutralColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (jobTitle != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                jobTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: kTextStyle.copyWith(
                                                  color: kSubTitleColor,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (reviewCount > 0 || rating > 0)
                                                  '★ ${rating.toStringAsFixed(1)}'
                                                      '${reviewCount > 0 ? ' ($reviewCount)' : ''}',
                                                if (location.isNotEmpty) location,
                                              ].join(' · '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: kTextStyle.copyWith(
                                                color: kLightNeutralColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (savedId != null)
                                        IconButton(
                                          tooltip: l10n.removedFromSavedTalent,
                                          onPressed: () => _handleRemove(savedId, i),
                                          icon: const Icon(
                                            Icons.bookmark,
                                            color: kPrimaryColor,
                                            size: 22,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
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
