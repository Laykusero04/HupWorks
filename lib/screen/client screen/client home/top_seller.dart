import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/profile_service.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../client talent/freelancer_public_profile.dart';

class TopSeller extends StatefulWidget {
  const TopSeller({Key? key}) : super(key: key);

  @override
  State<TopSeller> createState() => _TopSellerState();
}

class _TopSellerState extends State<TopSeller> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get _filteredSellers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _sellers;

    return _sellers.where((seller) {
      final name = (seller['name'] as String? ?? '').toLowerCase();
      final sp = _sellerProfileRow(seller);
      final jobTitle = (sp?['job_title'] as String? ?? '').toLowerCase();
      final about = (sp?['about'] as String? ?? '').toLowerCase();
      final skillNames = ProfileService.sellerSkillsFromProfile(seller)
          .map((s) => s.name.toLowerCase())
          .join(' ');
      return name.contains(q) ||
          jobTitle.contains(q) ||
          about.contains(q) ||
          skillNames.contains(q);
    }).toList();
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
    final jobTitle = sp?['job_title'] as String?;
    if (jobTitle != null && jobTitle.trim().isNotEmpty) return jobTitle.trim();

    final topSkills = ProfileService.sellerSkillsFromProfile(seller)
        .where((s) => s.stars == 5)
        .map((s) => s.name)
        .toList();
    if (topSkills.isNotEmpty) return topSkills.take(2).join(' · ');

    final about = sp?['about'] as String?;
    if (about != null && about.trim().isNotEmpty) {
      final t = about.trim();
      return t.length > 48 ? '${t.substring(0, 48)}…' : t;
    }
    return 'Verified freelancer';
  }

  void _openSeller(Map<String, dynamic> seller) {
    final id = seller['id'] as String?;
    if (id == null) return;
    openFreelancerPublicProfile(
      context,
      sellerId: id,
      name: seller['name'] as String?,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => setState(() => _searchQuery = q),
        style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search freelancers...',
          hintStyle: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: kLightNeutralColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: kLightNeutralColor, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: kWhite,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorderColorTextField),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorderColorTextField),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> sellers) {
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _load,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: sellers.length,
        itemBuilder: (_, i) {
          final seller = sellers[i];
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSellers;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: const ClientShellAppBar(title: 'Talent'),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _sellers.isEmpty
                    ? Center(
                        child: Text(
                          'No freelancers yet',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No freelancers match your search',
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                          )
                        : _buildGrid(filtered),
          ),
        ],
      ),
    );
  }
}
