import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_profile.dart';
import 'package:freelancer/screen/seller%20screen/seller%20home/my%20service/service_details.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/seller_home_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/chart.dart';
import '../../widgets/data.dart';
import '../notification/seller_notification.dart';
import 'my service/my_service.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _performance = {};
  Map<String, double> _statistics = {};
  Map<String, dynamic> _earnings = {};
  List<Map<String, dynamic>> _myServices = [];
  bool _isLoading = true;

  String _selectedPerformancePeriod = 'This Month';
  String _selectedStatsPeriod = 'This Month';
  String _selectedEarningPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SellerHomeService.getSellerProfile(),
        SellerHomeService.getPerformance(isLastMonth: _selectedPerformancePeriod == 'Last Month'),
        SellerHomeService.getStatistics(),
        SellerHomeService.getEarnings(isLastMonth: _selectedEarningPeriod == 'Last Month'),
        SellerHomeService.getMyServices(),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _performance = results[1] as Map<String, dynamic>;
          _statistics = results[2] as Map<String, double>;
          _earnings = results[3] as Map<String, dynamic>;
          _myServices = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reloadPerformance() async {
    final perf = await SellerHomeService.getPerformance(
      isLastMonth: _selectedPerformancePeriod == 'Last Month',
    );
    if (mounted) setState(() => _performance = perf);
  }

  Future<void> _reloadEarnings() async {
    final earn = await SellerHomeService.getEarnings(
      isLastMonth: _selectedEarningPeriod == 'Last Month',
    );
    if (mounted) setState(() => _earnings = earn);
  }

  Widget _buildPeriodDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      height: 30,
      child: Container(
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: kLightNeutralColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            icon: const Icon(FeatherIcons.chevronDown),
            value: value,
            style: kTextStyle.copyWith(color: kSubTitleColor),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: kTextStyle.copyWith(color: kSubTitleColor)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Scaffold(
          backgroundColor: kDarkWhite,
          body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
        ),
      );
    }

    final name = _profile?['name'] ?? 'Seller';
    final profileImageUrl = _profile?['profile_image_url'];
    final completedOrders = _performance['completed_orders'] ?? 0;
    final avgRating = _performance['avg_rating'] ?? 0.0;
    final totalServices = _performance['total_services'] ?? 0;
    final totalEarnings = _earnings['total_earnings'] ?? 0.0;
    final totalWithdrawals = _earnings['total_withdrawals'] ?? 0.0;
    final currentBalance = _earnings['current_balance'] ?? 0.0;
    final activeOrdersValue = _earnings['active_orders_value'] ?? 0.0;

    // Ensure statistics has non-zero values for the pie chart
    final statsForChart = _statistics.isEmpty || _statistics.values.every((v) => v == 0)
        ? {'Impressions': 1.0, 'Interaction': 1.0, 'Reached-Out': 1.0}
        : _statistics;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: GestureDetector(
                onTap: () => const SellerProfile().launch(context),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: profileImageUrl != null
                          ? NetworkImage(profileImageUrl) as ImageProvider
                          : const AssetImage('images/profilepic.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(name, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
            subtitle: Text('Seller', style: kTextStyle.copyWith(color: kLightNeutralColor)),
            trailing: GestureDetector(
              onTap: () => const SellerNotification().launch(context),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: const Icon(IconlyLight.notification, color: kNeutralColor),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 15.0),
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
            child: RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15.0),

                    // Performance Card
                    _buildCard(
                      title: 'Performance',
                      dropdown: _buildPeriodDropdown(
                        _selectedPerformancePeriod,
                        ['Last Month', 'This Month'],
                        (v) {
                          setState(() => _selectedPerformancePeriod = v!);
                          _reloadPerformance();
                        },
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Summary(title: '$completedOrders Orders', subtitle: 'Order Completions')),
                              const SizedBox(width: 10.0),
                              Expanded(child: Summary2(title1: '${avgRating.toStringAsFixed(1)}/', title2: '5.0', subtitle: 'Positive Ratings')),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              Expanded(child: Summary(title: 'Services: $totalServices', subtitle: 'Total Services')),
                              const SizedBox(width: 10.0),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Statistics Card
                    _buildCard(
                      title: 'Statistics',
                      dropdown: _buildPeriodDropdown(
                        _selectedStatsPeriod,
                        ['Last Month', 'This Month'],
                        (v) => setState(() => _selectedStatsPeriod = v!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RecordStatistics(dataMap: statsForChart, colorList: colorList),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                ChartLegend(iconColor: const Color(0xFF69B22A), title: 'Impressions', value: '${(_statistics['Impressions'] ?? 0).toInt()}'),
                                ChartLegend(iconColor: const Color(0xFF144BD6), title: 'Interaction', value: '${(_statistics['Interaction'] ?? 0).toInt()}'),
                                ChartLegend(iconColor: const Color(0xFFFF3B30), title: 'Reached-Out', value: '${(_statistics['Reached-Out'] ?? 0).toInt()}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Earnings Card
                    _buildCard(
                      title: 'Earnings',
                      dropdown: _buildPeriodDropdown(
                        _selectedEarningPeriod,
                        ['Last Month', 'This Month'],
                        (v) {
                          setState(() => _selectedEarningPeriod = v!);
                          _reloadEarnings();
                        },
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Summary(title: '$currencySign${totalEarnings.toStringAsFixed(2)}', subtitle: 'Total Earnings')),
                              const SizedBox(width: 10.0),
                              Expanded(child: Summary(title: '$currencySign${totalWithdrawals.toStringAsFixed(2)}', subtitle: 'Withdraw Earnings')),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              Expanded(child: Summary(title: '$currencySign${currentBalance.toStringAsFixed(2)}', subtitle: 'Current Balance')),
                              const SizedBox(width: 10.0),
                              Expanded(child: Summary(title: '$currencySign${activeOrdersValue.toStringAsFixed(2)}', subtitle: 'Active Orders')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // My Services
                    Row(
                      children: [
                        Text('My Services', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => const MyServices().launch(context),
                          child: Text('view All', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15.0),
                    _myServices.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(child: Text('No services yet', style: kTextStyle.copyWith(color: kLightNeutralColor))),
                          )
                        : HorizontalList(
                            spacing: 10.0,
                            padding: const EdgeInsets.only(bottom: 10.0),
                            itemCount: _myServices.length,
                            itemBuilder: (_, i) {
                              final service = _myServices[i];
                              final images = service['images'] as List<dynamic>?;
                              final imageUrl = (images != null && images.isNotEmpty) ? images[0] : null;

                              return GestureDetector(
                                onTap: () => const ServiceDetails().launch(context),
                                child: Container(
                                  height: 205,
                                  width: 156,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: kBorderColorTextField),
                                    boxShadow: const [
                                      BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 2.0, offset: Offset(0, 5)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 100,
                                        width: 156,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8.0),
                                            topLeft: Radius.circular(8.0),
                                          ),
                                          image: DecorationImage(
                                            image: imageUrl != null
                                                ? NetworkImage(imageUrl) as ImageProvider
                                                : const AssetImage('images/shot1.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service['title'] ?? 'Service',
                                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5.0),
                                            Row(
                                              children: [
                                                const Icon(IconlyBold.star, color: Colors.amber, size: 18.0),
                                                const SizedBox(width: 2.0),
                                                Text('${service['rating'] ?? 0}', style: kTextStyle.copyWith(color: kNeutralColor)),
                                                const SizedBox(width: 2.0),
                                                Text('(${service['review_count'] ?? 0})', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                              ],
                                            ),
                                            const SizedBox(height: 5.0),
                                            RichText(
                                              text: TextSpan(
                                                text: 'Price: ',
                                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                children: [
                                                  TextSpan(
                                                    text: '$currencySign${service['price'] ?? 0}',
                                                    style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget dropdown, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: kBorderColorTextField),
        boxShadow: const [BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 2.0, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(title, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
              const Spacer(),
              dropdown,
            ],
          ),
          const SizedBox(height: 15.0),
          child,
        ],
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    Key? key,
    required this.iconColor,
    required this.title,
    required this.value,
  }) : super(key: key);

  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 16.0, color: iconColor),
        const SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: kTextStyle.copyWith(color: kSubTitleColor)),
            const SizedBox(height: 5.0),
            Text(value, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
