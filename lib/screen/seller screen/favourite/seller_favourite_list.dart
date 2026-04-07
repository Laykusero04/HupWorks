import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../seller popUp/seller_popup.dart';

class SellerFavList extends StatefulWidget {
  const SellerFavList({Key? key}) : super(key: key);

  @override
  State<SellerFavList> createState() => _SellerFavListState();
}

class _SellerFavListState extends State<SellerFavList> {
  //__________favourite_warning_popup________________________________________________
  void favouriteWarningPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const FavouriteWarningPopUp(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Favorite List',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(
            left: 15.0,
            right: 15.0,
          ),
          width: context.width(),
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
              children: [
                const SizedBox(height: 15.0),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 15.0),
                  shrinkWrap: true,
                  itemCount: 20,
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
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
                                          'images/shot4.png',
                                        ),
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFavorite = !isFavorite;
                                      favouriteWarningPopUp();
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
                                        'Mobile UI UX design or app design',
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
                                          image: DecorationImage(image: AssetImage('images/profilepic.png'), fit: BoxFit.cover),
                                        ),
                                      ),
                                      const SizedBox(width: 5.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Leslie Alexander',
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
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
