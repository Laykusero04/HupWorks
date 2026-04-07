import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../widgets/review.dart';

class ServiceDetails extends StatefulWidget {
  const ServiceDetails({Key? key}) : super(key: key);

  @override
  State<ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends State<ServiceDetails> with TickerProviderStateMixin {
  PageController pageController = PageController(initialPage: 0);
  TabController? tabController;
  ScrollController? _scrollController;
  bool lastStatus = false;
  double height = 200;

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
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController?.dispose();
    super.dispose();
  }

  // final CarouselController _controller = CarouselController();
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                        child: const Icon(
                          Icons.arrow_back,
                          color: kNeutralColor,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kWhite,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: kNeutralColor,
                            ),
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
                        enableInfiniteScroll: true,
                        reverse: false,
                        autoPlay: false,
                        autoPlayCurve: Curves.fastOutSlowIn,
                        enlargeCenterPage: false,
                        onPageChanged: (i, j) {
                          pageController.nextPage(duration: const Duration(microseconds: 1), curve: Curves.bounceIn);
                        },
                        scrollDirection: Axis.horizontal,
                      ),
                      itemCount: 10,
                      itemBuilder: (BuildContext context, int index, int realIndex) {
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 300,
                              width: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                image: DecorationImage(image: AssetImage('images/bg2.png'), fit: BoxFit.fitWidth),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SmoothPageIndicator(
                                  controller: pageController,
                                  count: 3,
                                  effect: JumpingDotEffect(
                                    dotHeight: 6.0,
                                    dotWidth: 6.0,
                                    jumpScale: .7,
                                    verticalOffset: 15,
                                    activeDotColor: kPrimaryColor,
                                    dotColor: kPrimaryColor.withOpacity(0.2),
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
                                      color: kWhite),
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                actions: _isShrink
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kWhite,
                            ),
                            child: PopupMenuButton(
                              itemBuilder: (BuildContext bc) => [
                                PopupMenuItem(
                                  child: Text(
                                    'Edit',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: Text(
                                    'Pause',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: Text(
                                    'Delete',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                Navigator.pushNamed(context, '$value');
                              },
                              child: const Icon(
                                FeatherIcons.moreVertical,
                                color: kNeutralColor,
                              ),
                            ),
                          ),
                        )
                      ]
                    : [
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kWhite,
                            ),
                            child: PopupMenuButton(
                              itemBuilder: (BuildContext bc) => [
                                PopupMenuItem(
                                  child: Text(
                                    'Edit',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: Text(
                                    'Pause',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: Text(
                                    'Delete',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                Navigator.pushNamed(context, '$value');
                              },
                              child: const Icon(
                                FeatherIcons.moreVertical,
                                color: kNeutralColor,
                              ),
                            ),
                          ),
                        )
                      ],
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
                          padding: const EdgeInsets.all(15.0),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.0),
                              topRight: Radius.circular(30.0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile UI UX design or app UI UX design',
                                maxLines: 2,
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 4.0,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    IconlyBold.star,
                                    color: Colors.amber,
                                    size: 18.0,
                                  ),
                                  const SizedBox(width: 5.0),
                                  RichText(
                                    text: TextSpan(text: '5.0 ', style: kTextStyle.copyWith(color: kNeutralColor), children: [TextSpan(text: '(520 Reviews)', style: kTextStyle.copyWith(color: kLightNeutralColor))]),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 18.0,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '807',
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  )
                                ],
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                horizontalTitleGap: 10,
                                leading: const CircleAvatar(
                                  radius: 22.0,
                                  backgroundImage: AssetImage('images/profilepic.png'),
                                ),
                                title: Text(
                                  'William Liam',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                subtitle: RichText(
                                  text: TextSpan(
                                    text: 'Seller Level - 1 ',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                    children: [
                                      TextSpan(
                                        text: '(View Profile)',
                                        style: kTextStyle.copyWith(color: kPrimaryColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                thickness: 1.0,
                                color: kBorderColorTextField,
                              ),
                              const SizedBox(height: 5.0),
                              Text(
                                'Details',
                                maxLines: 1,
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5.0),
                              ReadMoreText(
                                'Lorem ipsum dolor sit amet consectetur. Tortor sapien aliquam amet elit. Quis varius amet grav ida molestie rhoncus. Lorem ipsum dolor sit amet consectetur. Tortor sapien aliquam amet elit. Quis varius amet grav ida molestie rhoncus.',
                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                                trimLines: 3,
                                colorClickableText: kPrimaryColor,
                                trimMode: TrimMode.Line,
                                trimCollapsedText: 'Read more',
                                trimExpandedText: 'Read less',
                              ),
                              const SizedBox(height: 15.0),
                              Text(
                                'Price',
                                maxLines: 1,
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10.0),
                              Container(
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  border: Border.all(color: kBorderColorTextField),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  children: [
                                    TabBar(
                                      unselectedLabelColor: kNeutralColor,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8.0),
                                            topLeft: Radius.circular(8.0),
                                          ),
                                          color: kPrimaryColor),
                                      controller: tabController,
                                      labelColor: kWhite,
                                      tabs: const [
                                        Tab(
                                          text: 'Basic',
                                        ),
                                        Tab(
                                          text: 'Standard',
                                        ),
                                        Tab(
                                          text: 'Premium',
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      height: 0,
                                      thickness: 1.0,
                                      color: kBorderColorTextField,
                                    ),
                                    SizedBox(
                                      height: 300,
                                      child: TabBarView(
                                        controller: tabController,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$currencySign${60}',
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 5.0),
                                                Text(
                                                  'I can design the website with 6 pages.',
                                                  maxLines: 2,
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 15.0),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      IconlyLight.timeCircle,
                                                      color: kPrimaryColor,
                                                      size: 18.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Text(
                                                      'Delivery days',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '5 Days ',
                                                      maxLines: 2,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.loop,
                                                      color: kPrimaryColor,
                                                      size: 18.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Text(
                                                      'Revisions',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      'Unlimited',
                                                      maxLines: 2,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 15.0),
                                                const Divider(
                                                  height: 0,
                                                  thickness: 1.0,
                                                  color: kBorderColorTextField,
                                                ),
                                                const SizedBox(height: 15.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '3 Page/Screen',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '2 Custom assets',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Responsive design',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Prototype',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Source file',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$currencySign${60}',
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 5.0),
                                                Text(
                                                  'I can design the website with 6 pages.',
                                                  maxLines: 2,
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 15.0),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      IconlyLight.timeCircle,
                                                      color: kPrimaryColor,
                                                      size: 18.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Text(
                                                      'Delivery days',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '5 Days ',
                                                      maxLines: 2,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.loop,
                                                      color: kPrimaryColor,
                                                      size: 18.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Text(
                                                      'Revisions',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      'Unlimited',
                                                      maxLines: 2,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 15.0),
                                                const Divider(
                                                  height: 0,
                                                  thickness: 1.0,
                                                  color: kBorderColorTextField,
                                                ),
                                                const SizedBox(height: 15.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '3 Page/Screen',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '2 Custom assets',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Responsive design',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Prototype',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Source file',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$currencySign${60}',
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 5.0),
                                                Text(
                                                  'I can design the website with 6 pages.',
                                                  maxLines: 2,
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 15.0),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      IconlyLight.timeCircle,
                                                      color: kPrimaryColor,
                                                      size: 18.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Text(
                                                      'Delivery days',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '5 Days ',
                                                      maxLines: 2,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.loop,
                                                      color: kPrimaryColor,
                                                      size: 18.0,
                                                    ),
                                                    const SizedBox(width: 5.0),
                                                    Text(
                                                      'Revisions',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      'Unlimited',
                                                      maxLines: 2,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 15.0),
                                                const Divider(
                                                  height: 0,
                                                  thickness: 1.0,
                                                  color: kBorderColorTextField,
                                                ),
                                                const SizedBox(height: 15.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '3 Page/Screen',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '2 Custom assets',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Responsive design',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Prototype',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Source file',
                                                      maxLines: 1,
                                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                                    ),
                                                    const Spacer(),
                                                    const Icon(
                                                      Icons.check_rounded,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15.0),
                              Text(
                                'Reviews',
                                maxLines: 1,
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 15.0),
                              const Review(),
                              const SizedBox(height: 15.0),
                              const ReviewDetails(),
                              const SizedBox(height: 10.0),
                              const ReviewDetails2(),
                              const SizedBox(height: 20.0),
                              Container(
                                height: 40.0,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), border: Border.all(color: kSubTitleColor)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View all reviews',
                                      maxLines: 1,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                    const Icon(
                                      FeatherIcons.chevronDown,
                                      color: kSubTitleColor,
                                    ),
                                  ],
                                ),
                              )
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
}
