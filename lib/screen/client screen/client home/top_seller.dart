import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../router/app_router.dart';
import '../../widgets/constant.dart';
import '../../widgets/shell_tab_header.dart';
import '../client service details/client_service_details.dart';

class TopSeller extends StatefulWidget {
  const TopSeller({Key? key}) : super(key: key);

  @override
  State<TopSeller> createState() => _TopSellerState();
}

class _TopSellerState extends State<TopSeller> {
  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ClientHomeService.getTopSellers(limit: 48);
      if (mounted) {
        setState(() {
          _sellers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading talent: $e')),
        );
      }
    }
  }

  static Map<String, dynamic>? _sellerProfileRow(Map<String, dynamic> seller) {
    final sp = seller['seller_profiles'];
    if (sp is Map<String, dynamic>) return sp;
    if (sp is List && sp.isNotEmpty && sp.first is Map<String, dynamic>) {
      return sp.first as Map<String, dynamic>;
    }
    return null;
  }

  static String _subtitle(Map<String, dynamic> seller) {
    final sp = _sellerProfileRow(seller);
    final level = sp?['skill_level'] as String?;
    if (level != null && level.trim().isNotEmpty) return level.trim();
    final about = sp?['about'] as String?;
    if (about != null && about.trim().isNotEmpty) {
      final t = about.trim();
      return t.length > 48 ? '${t.substring(0, 48)}…' : t;
    }
    return 'Verified freelancer';
  }

  Future<void> _openSeller(Map<String, dynamic> seller) async {
    final id = seller['id'] as String?;
    if (id == null) return;
    final serviceId = await ClientHomeService.getFirstActiveServiceIdForSeller(id);
    if (!mounted) return;
    if (serviceId != null) {
      await ClientServiceDetails(serviceId: serviceId).launch(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This freelancer has no active service listing yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Column(
          children: [
            ShellTabHeader(
              persona: ShellPersona.client,
              title: 'Talent',
              subtitle: Text(
                'Browse verified freelancers',
                style: kTextStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              leading: ShellTabIconButton(
                icon: Icons.menu_rounded,
                onPressed: () => clientShellScaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            Expanded(
              child: Container(
                width: context.width(),
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                decoration: const BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : _sellers.isEmpty
                        ? Center(
                            child: Text(
                              'No freelancers yet',
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                          )
                        : RefreshIndicator(
                            color: kPrimaryColor,
                            onRefresh: _load,
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.only(top: 15, bottom: 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: _sellers.length,
                              itemBuilder: (_, i) {
                                final seller = _sellers[i];
                                final profileImageUrl = seller['profile_image_url'] as String?;
                                final name = seller['name'] as String? ?? 'Freelancer';
                                final rating = double.tryParse('${seller['rating'] ?? 0}') ?? 0;
                                final reviewCount = (seller['review_count'] as num?)?.toInt();

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _openSeller(seller),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: kWhite,
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(color: kBorderColorTextField),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: kDarkWhite,
                                            blurRadius: 5.0,
                                            spreadRadius: 2.0,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: profileImageUrl != null
                                                      ? NetworkImage(profileImageUrl) as ImageProvider
                                                      : const AssetImage('images/dev1.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: kTextStyle.copyWith(
                                                    color: kNeutralColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(IconlyBold.star, color: Colors.amber, size: 16),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      rating.toStringAsFixed(1),
                                                      style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 12),
                                                    ),
                                                    if (reviewCount != null) ...[
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '($reviewCount)',
                                                          style: kTextStyle.copyWith(
                                                            color: kLightNeutralColor,
                                                            fontSize: 11,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _subtitle(seller),
                                                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
    );
  }
}
