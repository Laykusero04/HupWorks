import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../seller home/my service/service_details.dart';
import 'create_new_service.dart';

class CreateService extends StatefulWidget {
  const CreateService({Key? key}) : super(key: key);

  @override
  State<CreateService> createState() => _CreateServiceState();
}

class _CreateServiceState extends State<CreateService> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Create Service',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: () {
            setState(
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateNewService(),
                  ),
                );
              },
            );
          },
          backgroundColor: kPrimaryColor,
          child: const Icon(
            FeatherIcons.plus,
            color: kWhite,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 15.0),
                Column(
                  children: [
                    const SizedBox(height: 50.0),
                    Container(
                      height: 213,
                      width: 269,
                      decoration: const BoxDecoration(
                        image: DecorationImage(image: AssetImage('images/emptyservice.png'), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Empty  Service',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 24.0),
                    ),
                  ],
                ).visible(false),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 0.8,
                  crossAxisCount: 2,
                  children: List.generate(
                    10,
                    (index) => GestureDetector(
                      onTap: () {
                        setState(() {
                          const ServiceDetails().launch(context);
                        });
                      },
                      child: Container(
                        height: 205,
                        width: 156,
                        decoration: BoxDecoration(
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
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  height: 100,
                                  width: 156,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8.0),
                                      topLeft: Radius.circular(8.0),
                                    ),
                                    image: DecorationImage(
                                        image: AssetImage(
                                          'images/shot1.png',
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
                                      height: 30,
                                      width: 30,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: isFavorite
                                          ? const Center(
                                              child: Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                                size: 18.0,
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.favorite_border,
                                                color: kNeutralColor,
                                                size: 18.0,
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
                                children: [
                                  Text(
                                    'Mobile UI UX design or app design',
                                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                        '(520 review)',
                                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5.0),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
