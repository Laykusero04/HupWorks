import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer/screen/client%20screen/client%20service%20details/client_service_details.dart';
import 'package:freelancer/screen/client%20screen/client%20talent/freelancer_public_profile.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';

class CustomSearchDelegate extends SearchDelegate<void> {
  CustomSearchDelegate({String? searchHint})
      : _searchHint = searchHint ?? 'Search services or freelancers';

  final String _searchHint;

  @override
  String get searchFieldLabel => _searchHint;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          onPressed: () {
            if (query.isEmpty) {
              close(context, null);
            } else {
              query = '';
              showSuggestions(context);
            }
          },
          icon: const Icon(Icons.clear, color: kNeutralColor),
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      color: kNeutralColor,
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back, color: kNeutralColor),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _MarketplaceSearchBody(query: query.trim(), mode: _SearchMode.results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _MarketplaceSearchBody(query: query.trim(), mode: _SearchMode.suggestions);
  }
}

enum _SearchMode { suggestions, results }

class _MarketplaceSearchBody extends StatefulWidget {
  const _MarketplaceSearchBody({
    required this.query,
    required this.mode,
  });

  final String query;
  final _SearchMode mode;

  @override
  State<_MarketplaceSearchBody> createState() => _MarketplaceSearchBodyState();
}

class _MarketplaceSearchBodyState extends State<_MarketplaceSearchBody> {
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _sellers = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  String _lastFetchedKey = '';

  @override
  void initState() {
    super.initState();
    _scheduleFetch(immediate: true);
  }

  @override
  void didUpdateWidget(covariant _MarketplaceSearchBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query || oldWidget.mode != widget.mode) {
      _scheduleFetch(immediate: widget.mode == _SearchMode.results);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleFetch({required bool immediate}) {
    _debounce?.cancel();
    if (immediate) {
      _fetch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  Future<void> _fetch() async {
    final q = widget.query;
    final key = '${widget.mode.name}|$q';
    if (key == _lastFetchedKey && (_services.isNotEmpty || _sellers.isNotEmpty) && !_loading) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      late final List<Map<String, dynamic>> services;
      late final List<Map<String, dynamic>> sellers;

      if (q.isEmpty) {
        final results = await Future.wait([
          ClientHomeService.getPopularServices(limit: 12),
          ClientHomeService.getTopSellers(limit: 12),
        ]);
        services = results[0];
        sellers = results[1];
      } else {
        final results = await Future.wait([
          ClientHomeService.searchServices(q),
          ClientHomeService.searchSellers(q),
        ]);
        services = results[0];
        sellers = results[1];
      }

      if (!mounted) return;
      setState(() {
        _services = services;
        _sellers = sellers;
        _lastFetchedKey = key;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openService(Map<String, dynamic> service) {
    final id = service['id']?.toString();
    if (id == null || id.isEmpty) return;
    ClientServiceDetails(serviceId: id).launch(context);
  }

  void _openSeller(Map<String, dynamic> seller) {
    final id = seller['id']?.toString();
    if (id == null || id.isEmpty) return;
    openFreelancerPublicProfile(
      context,
      sellerId: id,
      name: seller['name'] as String?,
    );
  }

  String _priceLabel(dynamic price) {
    if (price == null) return '';
    if (price is num) {
      if (price == price.roundToDouble()) {
        return '$currencySign${price.toInt()}';
      }
      return '$currencySign${price.toStringAsFixed(2)}';
    }
    return '$currencySign$price';
  }

  String _sellerName(Map<String, dynamic> service) {
    final profiles = service['profiles'];
    if (profiles is Map) {
      return (profiles['name'] as String?)?.trim().isNotEmpty == true
          ? profiles['name'] as String
          : 'Seller';
    }
    return 'Seller';
  }

  String? _sellerImage(Map<String, dynamic> service) {
    final profiles = service['profiles'];
    if (profiles is Map) {
      return profiles['profile_image_url'] as String?;
    }
    return null;
  }

  String? _jobTitle(Map<String, dynamic> seller) {
    final sp = seller['seller_profiles'];
    if (sp is Map) {
      final title = (sp['job_title'] as String?)?.trim();
      if (title != null && title.isNotEmpty) return title;
    }
    if (sp is List && sp.isNotEmpty && sp.first is Map) {
      final title = (sp.first['job_title'] as String?)?.trim();
      if (title != null && title.isNotEmpty) return title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.couldNotLoadResults, style: kTextStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(height: 16),
              TextButton(onPressed: () => _scheduleFetch(immediate: true), child: Text(context.l10n.retry)),
            ],
          ),
        ),
      );
    }

    final empty = _services.isEmpty && _sellers.isEmpty;
    if (empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.query.isEmpty
                ? context.l10n.noPopularResults
                : context.l10n.noSearchResults(widget.query),
            style: kTextStyle.copyWith(color: kSubTitleColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (_services.isNotEmpty) ...[
          _sectionHeader(widget.query.isEmpty ? context.l10n.popularServices : context.l10n.services),
          ..._services.map(_serviceTile),
        ],
        if (_sellers.isNotEmpty) ...[
          _sectionHeader(widget.query.isEmpty ? context.l10n.topFreelancers : context.l10n.freelancers),
          ..._sellers.map(_sellerTile),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _serviceTile(Map<String, dynamic> service) {
    final title = (service['title'] as String?)?.trim().isNotEmpty == true
        ? service['title'] as String
        : 'Untitled service';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0;
    final price = _priceLabel(service['price']);
    final seller = _sellerName(service);
    final imageUrl = _sellerImage(service);

    return ListTile(
      onTap: () => _openService(service),
      leading: CircleAvatar(
        backgroundColor: kDarkWhite,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : const AssetImage('images/profile3.png') as ImageProvider,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          seller,
          if (rating > 0) '★ ${rating.toStringAsFixed(1)}',
          if (price.isNotEmpty) price,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: kLightNeutralColor),
    );
  }

  Widget _sellerTile(Map<String, dynamic> seller) {
    final name = (seller['name'] as String?)?.trim().isNotEmpty == true
        ? seller['name'] as String
        : 'Freelancer';
    final imageUrl = seller['profile_image_url'] as String?;
    final rating = (seller['rating'] as num?)?.toDouble() ?? 0;
    final jobTitle = _jobTitle(seller);
    final location = [
      seller['city'] as String?,
      seller['country'] as String?,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

    return ListTile(
      onTap: () => _openSeller(seller),
      leading: CircleAvatar(
        backgroundColor: kDarkWhite,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : const AssetImage('images/profile3.png') as ImageProvider,
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (jobTitle != null) jobTitle,
          if (rating > 0) '★ ${rating.toStringAsFixed(1)}',
          if (location.isNotEmpty) location,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: kLightNeutralColor),
    );
  }
}
