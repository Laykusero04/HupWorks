import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:freelancer/services/recently_viewed_service.dart';
import 'package:freelancer/services/service_details_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class ClientServiceDetails extends StatefulWidget {
  final String? serviceId;

  const ClientServiceDetails({Key? key, this.serviceId}) : super(key: key);

  @override
  State<ClientServiceDetails> createState() => _ClientServiceDetailsState();
}

class _ClientServiceDetailsState extends State<ClientServiceDetails> with TickerProviderStateMixin {
  PageController pageController = PageController(initialPage: 0);
  TabController? tabController;
  ScrollController? _scrollController;
  bool lastStatus = false;
  double height = 200;

  Map<String, dynamic>? _service;
  Map<String, dynamic>? _seller;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _requirements = [];
  bool _isFavourited = false;
  bool _isLoading = true;

  void _scrollListener() {
    if (_isShrink != lastStatus) {
      setState(() {
        lastStatus = _isShrink;
      });
    }
  }

  bool get _isShrink {
    return _scrollController != null && _scrollController!.hasClients && _scrollController!.offset > (height - kToolbarHeight);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    tabController = TabController(length: 3, vsync: this);
    if (widget.serviceId != null) {
      _loadData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ServiceDetailsService.getServiceDetails(widget.serviceId!),
        ServiceDetailsService.getServiceReviews(widget.serviceId!),
        ServiceDetailsService.getServiceRequirements(widget.serviceId!),
        ServiceDetailsService.isFavourited(widget.serviceId!),
      ]);

      // Track as recently viewed
      RecentlyViewedService.addServiceId(widget.serviceId!);

      if (mounted) {
        final serviceData = results[0] as Map<String, dynamic>;
        setState(() {
          _service = serviceData;
          _seller = serviceData['profiles'] as Map<String, dynamic>?;
          _reviews = results[1] as List<Map<String, dynamic>>;
          _requirements = results[2] as List<Map<String, dynamic>>;
          _isFavourited = results[3] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading service: $e')),
        );
      }
    }
  }

  Future<void> _handleFavouriteToggle() async {
    if (widget.serviceId == null) return;
    try {
      final result = await ServiceDetailsService.toggleFavourite(widget.serviceId!);
      if (mounted) {
        setState(() => _isFavourited = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ? 'Added to favourites' : 'Removed from favourites')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Calculate review stats
  Map<int, int> get _reviewCounts {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      final rating = review['rating'] as int? ?? 0;
      if (counts.containsKey(rating)) {
        counts[rating] = counts[rating]! + 1;
      }
    }
    return counts;
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(0, (sum, r) => sum + (r['rating'] as int? ?? 0));
    return total / _reviews.length;
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController?.dispose();
    super.dispose();
  }

  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final title = _service?['title'] ?? 'Service Details';
    final description = _service?['description'] ?? 'No description available.';
    final price = _service?['price'] ?? 0;
    final deliveryTime = _service?['delivery_time'] ?? 0;
    final revisionCount = _service?['revision_count'] ?? 0;
    final rating = _service?['rating'] ?? _averageRating;
    final reviewCount = _service?['review_count'] ?? _reviews.length;
    final images = (_service?['images'] as List<dynamic>?) ?? [];
    final sellerName = _seller?['name'] ?? 'Seller';
    final sellerImage = _seller?['profile_image_url'];

    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: ButtonGlobalWithoutIcon(
            buttontext: 'Order Now',
            buttonDecoration: kButtonDecoration.copyWith(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: () async {
              if (widget.serviceId == null || _service == null || _seller == null) return;
              try {
                await OrdersService.createOrder(
                  serviceId: widget.serviceId!,
                  sellerId: _seller!['id'],
                  price: double.tryParse(_service!['price'].toString()) ?? 0,
                  deliveryDays: _service!['delivery_time'] ?? 7,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed successfully!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error placing order: $e')),
                  );
                }
              }
            },
            buttonTextColor: kWhite),
        backgroundColor: kWhite,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                elevation: 0,
                backgroundColor: _isShrink ? kWhite : Colors.transparent,
                pinned: true,
                expandedHeight: 290,
                titleSpacing: 10,
                automaticallyImplyLeading: false,
                forceElevated: innerBoxIsScrolled,
                leading: _isShrink
                    ? GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: kNeutralColor),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: kWhite),
                            child: const Icon(Icons.arrow_back, color: kNeutralColor),
                          ),
                        ),
                      ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: SafeArea(
                    child: CarouselSlider.builder(
                      carouselController: _controller,
                      options: CarouselOptions(
                        height: 300,
                        aspectRatio: 18 / 18,
                        viewportFraction: 1,
                        initialPage: 0,
                        enableInfiniteScroll: images.length > 1,
                        reverse: false,
                        autoPlay: false,
                        enlargeCenterPage: false,
                        onPageChanged: (i, j) {
                          if (pageController.hasClients) {
                            pageController.jumpToPage(i);
                          }
                        },
                        scrollDirection: Axis.horizontal,
                      ),
                      itemCount: images.isEmpty ? 1 : images.length,
                      itemBuilder: (BuildContext context, int index, int realIndex) {
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 300,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: images.isNotEmpty
                                      ? NetworkImage(images[index]) as ImageProvider
                                      : const AssetImage('images/bg2.png'),
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SmoothPageIndicator(
                                  controller: pageController,
                                  count: images.isEmpty ? 1 : images.length,
                                  effect: JumpingDotEffect(
                                    dotHeight: 6.0,
                                    dotWidth: 6.0,
                                    jumpScale: .7,
                                    verticalOffset: 15,
                                    activeDotColor: kNeutralColor,
                                    dotColor: kNeutralColor.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Container(
                                  height: 20,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(30.0),
                                      topLeft: Radius.circular(30.0),
                                    ),
                                    color: kWhite,
                                  ),
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ];
          },
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: 1,
                  (BuildContext context, int index) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.0),
                              topRight: Radius.circular(30.0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Text(
                                      title,
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5.0),

                                    // Rating + Favourite
                                    Row(
                                      children: [
                                        const Icon(IconlyBold.star, color: Colors.amber, size: 18.0),
                                        const SizedBox(width: 5.0),
                                        RichText(
                                          text: TextSpan(
                                            text: '${rating is double ? rating.toStringAsFixed(1) : rating} ',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                            children: [
                                              TextSpan(
                                                text: '($reviewCount Reviews)',
                                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: _handleFavouriteToggle,
                                          child: Icon(
                                            _isFavourited ? Icons.favorite : Icons.favorite_border,
                                            color: _isFavourited ? Colors.red : kLightNeutralColor,
                                            size: 22.0,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Seller info
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      horizontalTitleGap: 10,
                                      leading: CircleAvatar(
                                        radius: 22.0,
                                        backgroundImage: sellerImage != null
                                            ? NetworkImage(sellerImage) as ImageProvider
                                            : const AssetImage('images/profilepic2.png'),
                                      ),
                                      title: Text(
                                        sellerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'View Profile',
                                        style: kTextStyle.copyWith(color: kPrimaryColor),
                                      ),
                                    ),
                                    const Divider(thickness: 1.0, color: kBorderColorTextField),
                                    const SizedBox(height: 5.0),

                                    // Description
                                    Text(
                                      'Details',
                                      maxLines: 1,
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5.0),
                                    ReadMoreText(
                                      description,
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                      trimLines: 3,
                                      colorClickableText: kPrimaryColor,
                                      trimMode: TrimMode.Line,
                                      trimCollapsedText: '..Read more',
                                      trimExpandedText: '..Read less',
                                    ),
                                    const SizedBox(height: 15.0),

                                    // Price section
                                    Text(
                                      'Price',
                                      maxLines: 1,
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Container(
                                      padding: const EdgeInsets.all(15.0),
                                      decoration: BoxDecoration(
                                        color: kWhite,
                                        border: Border.all(color: kBorderColorTextField),
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$currencySign$price',
                                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                          const SizedBox(height: 15.0),
                                          Row(
                                            children: [
                                              const Icon(IconlyLight.timeCircle, color: kPrimaryColor, size: 18.0),
                                              const SizedBox(width: 5.0),
                                              Text('Delivery days', style: kTextStyle.copyWith(color: kSubTitleColor)),
                                              const Spacer(),
                                              Text('$deliveryTime Days', style: kTextStyle.copyWith(color: kNeutralColor)),
                                            ],
                                          ),
                                          const SizedBox(height: 10.0),
                                          Row(
                                            children: [
                                              const Icon(Icons.loop, color: kPrimaryColor, size: 18.0),
                                              const SizedBox(width: 5.0),
                                              Text('Revisions', style: kTextStyle.copyWith(color: kSubTitleColor)),
                                              const Spacer(),
                                              Text(
                                                revisionCount == 0 ? 'Unlimited' : '$revisionCount',
                                                style: kTextStyle.copyWith(color: kNeutralColor),
                                              ),
                                            ],
                                          ),

                                          // Requirements
                                          if (_requirements.isNotEmpty) ...[
                                            const SizedBox(height: 15.0),
                                            const Divider(height: 0, thickness: 1.0, color: kBorderColorTextField),
                                            const SizedBox(height: 15.0),
                                            ..._requirements.map((req) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 5.0),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          req['question'] ?? '',
                                                          style: kTextStyle.copyWith(color: kNeutralColor),
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.check_rounded,
                                                        color: req['is_required'] == true ? kPrimaryColor : kLightNeutralColor,
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ],
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 15.0),

                                    // Reviews section
                                    Text(
                                      'Reviews',
                                      maxLines: 1,
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 15.0),

                                    // Review summary
                                    if (_reviews.isNotEmpty) ...[
                                      _buildReviewSummary(),
                                      const SizedBox(height: 15.0),
                                      ..._reviews.take(3).map((review) => Padding(
                                            padding: const EdgeInsets.only(bottom: 15.0),
                                            child: _buildReviewCard(review),
                                          )),
                                    ] else
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text('No reviews yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSummary() {
    final counts = _reviewCounts;
    final total = _reviews.length;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(40)),
                  border: Border.all(width: 2, color: kPrimaryColor),
                ),
                child: Center(
                  child: Text(
                    _averageRating.toStringAsFixed(1),
                    style: kTextStyle.copyWith(fontSize: 30, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('Total $total Reviews', style: kTextStyle.copyWith(color: kNeutralColor)),
            ],
          ),
          Positioned(
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (i) {
                final stars = 5 - i;
                final count = counts[stars] ?? 0;
                final percent = total > 0 ? count / total : 0.0;
                return Row(
                  children: [
                    ...List.generate(stars, (_) => const Icon(Icons.star, size: 18, color: ratingBarColor)),
                    LinearPercentIndicator(
                      width: 130,
                      lineHeight: 8.0,
                      percent: percent,
                      progressColor: kPrimaryColor,
                      backgroundColor: Colors.transparent,
                      barRadius: const Radius.circular(15),
                    ),
                    SizedBox(width: 30, child: Center(child: Text('$count'))),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final reviewer = review['profiles'] as Map<String, dynamic>?;
    final reviewerName = reviewer?['name'] ?? 'Anonymous';
    final reviewerImage = reviewer?['profile_image_url'];
    final reviewRating = review['rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final createdAt = review['created_at'] != null ? DateTime.tryParse(review['created_at']) : null;
    final dateStr = createdAt != null
        ? '${createdAt.day}, ${_monthName(createdAt.month)} ${createdAt.year}'
        : '';

    return Container(
      padding: const EdgeInsets.all(10.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: kBorderColorTextField),
        boxShadow: const [BoxShadow(color: kBorderColorTextField, spreadRadius: 1.0, blurRadius: 5.0, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40.0,
                width: 40.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: reviewerImage != null
                        ? NetworkImage(reviewerImage) as ImageProvider
                        : const AssetImage('images/profilepic.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewerName, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(IconlyBold.star, color: ratingBarColor, size: 18.0),
                        const SizedBox(width: 5.0),
                        Text('$reviewRating', style: kTextStyle.copyWith(color: kNeutralColor)),
                        const Spacer(),
                        Text(dateStr, style: kTextStyle.copyWith(color: kLightNeutralColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Text(comment, style: kTextStyle.copyWith(color: kSubTitleColor)),
          ],
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
