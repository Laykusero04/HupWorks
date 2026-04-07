import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../widgets/review.dart';
import '../client home/recently_view.dart';
import 'client_order.dart';

class ClientServiceDetails extends StatefulWidget {
  const ClientServiceDetails({Key? key}) : super(key: key);

  @override
  State<ClientServiceDetails> createState() => _ClientServiceDetailsState();
}

class _ClientServiceDetailsState extends State<ClientServiceDetails> with TickerProviderStateMixin {
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
        bottomNavigationBar: ButtonGlobalWithoutIcon(
            buttontext: 'Order Now',
            buttonDecoration: kButtonDecoration.copyWith(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: () {
              setState(
                () {
                  const ClientOrder().launch(context);
                },
              );
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
                                    Text(
                                      'Mobile UI UX design or app UI UX design',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Row(
                                      children: [
                                        const Icon(
                                          IconlyBold.star,
                                          color: Colors.amber,
                                          size: 18.0,
                                        ),
                                        const SizedBox(width: 5.0),
                                        RichText(
                                          text: TextSpan(
                                            text: '5.0 ',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                            children: [
                                              TextSpan(
                                                text: '(520 Reviews)',
                                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.favorite,
                                          color: kPrimaryColor,
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
                                        backgroundImage: AssetImage('images/profilepic2.png'),
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
                                      trimCollapsedText: '..Read more',
                                      trimExpandedText: '..Read less',
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
                                            unselectedLabelColor: kSubTitleColor,
                                            indicatorSize: TabBarIndicatorSize.tab,
                                            indicator: const BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8.0),
                                                topLeft: Radius.circular(8.0),
                                              ),
                                              color: kPrimaryColor,
                                            ),
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
                                            height: 400,
                                            child: TabBarView(
                                              controller: tabController,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '$currencySign${30}',
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
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                          ),
                                                          const Spacer(),
                                                          const Icon(
                                                            Icons.check_rounded,
                                                            color: kLightNeutralColor,
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
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                          ),
                                                          const Spacer(),
                                                          const Icon(
                                                            Icons.check_rounded,
                                                            color: kLightNeutralColor,
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
                                                      const SizedBox(height: 10.0),
                                                      ButtonGlobalWithoutIcon(
                                                        buttontext: 'Select Offer',
                                                        buttonDecoration: kButtonDecoration.copyWith(
                                                          color: kPrimaryColor,
                                                          borderRadius: BorderRadius.circular(30.0),
                                                        ),
                                                        onPressed: () {},
                                                        buttonTextColor: kWhite,
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
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
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
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
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
                                                      const SizedBox(height: 10.0),
                                                      ButtonGlobalWithoutIcon(
                                                        buttontext: 'Select Offer',
                                                        buttonDecoration: kButtonDecoration.copyWith(
                                                          color: kWhite,
                                                          border: Border.all(color: kPrimaryColor),
                                                          borderRadius: BorderRadius.circular(30.0),
                                                        ),
                                                        onPressed: () {},
                                                        buttonTextColor: kPrimaryColor,
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
                                                        '$currencySign${99}',
                                                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 5.0),
                                                      Text(
                                                        'I can design the website with 100 pages.',
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
                                                            '15 Days ',
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
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
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
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
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
                                                      const SizedBox(height: 10.0),
                                                      ButtonGlobalWithoutIcon(
                                                        buttontext: 'Select Offer',
                                                        buttonDecoration: kButtonDecoration.copyWith(
                                                          color: kWhite,
                                                          border: Border.all(color: kPrimaryColor),
                                                          borderRadius: BorderRadius.circular(30.0),
                                                        ),
                                                        onPressed: () {},
                                                        buttonTextColor: kPrimaryColor,
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
                                    const SizedBox(height: 15.0),
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
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15),
                                child: Row(
                                  children: [
                                    Text(
                                      'Recent Viewed',
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => const RecentlyView().launch(context),
                                      child: Text(
                                        'View All',
                                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              HorizontalList(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(left: 15.0, bottom: 15, top: 15),
                                spacing: 10.0,
                                itemCount: 10,
                                itemBuilder: (_, i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: GestureDetector(
                                      onTap: () => const ClientServiceDetails().launch(context),
                                      child: Container(
                                        height: 120,
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
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              alignment: Alignment.topLeft,
                                              children: [
                                                Container(
                                                  height: 120,
                                                  width: 120,
                                                  decoration: const BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                      bottomLeft: Radius.circular(8.0),
                                                      topLeft: Radius.circular(8.0),
                                                    ),
                                                    image: DecorationImage(
                                                        image: AssetImage(
                                                          'images/shot5.png',
                                                        ),
                                                        fit: BoxFit.cover),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      isFavorite = !isFavorite;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: Container(
                                                      height: 25,
                                                      width: 25,
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 10.0,
                                                            spreadRadius: 1.0,
                                                            offset: Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: isFavorite
                                                          ? const Center(
                                                              child: Icon(
                                                                Icons.favorite,
                                                                color: Colors.red,
                                                                size: 16.0,
                                                              ),
                                                            )
                                                          : const Center(
                                                              child: Icon(
                                                                Icons.favorite_border,
                                                                color: kNeutralColor,
                                                                size: 16.0,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(5.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: SizedBox(
                                                      width: 190,
                                                      child: Text(
                                                        'modern unique business logo design',
                                                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5.0),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      const Icon(
                                                        IconlyBold.star,
                                                        color: Colors.amber,
                                                        size: 18.0,
                                                      ),
                                                      const SizedBox(width: 2.0),
                                                      Text(
                                                        '5.0',
                                                        style: kTextStyle.copyWith(color: kNeutralColor),
                                                      ),
                                                      const SizedBox(width: 2.0),
                                                      Text(
                                                        '(520)',
                                                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                      ),
                                                      const SizedBox(width: 40),
                                                      RichText(
                                                        text: TextSpan(
                                                          text: 'Price: ',
                                                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                          children: [
                                                            TextSpan(
                                                              text: '$currencySign${30}',
                                                              style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5.0),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        height: 32,
                                                        width: 32,
                                                        decoration: const BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          image: DecorationImage(image: AssetImage('images/profilepic2.png'), fit: BoxFit.cover),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5.0),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'William Liam',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            'Seller Level - 1',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
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
