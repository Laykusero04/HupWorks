import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_edit_profile_details.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/data.dart';

class SellerProfileDetails extends StatefulWidget {
  const SellerProfileDetails({Key? key}) : super(key: key);

  @override
  State<SellerProfileDetails> createState() => _SellerProfileDetailsState();
}

class _SellerProfileDetailsState extends State<SellerProfileDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'My Profile',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('images/profile3.png'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shaidulislam',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                        ),
                        Text(
                          'shaidulislamma@gmail.com',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Text(
                      'About Us',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(
                      IconlyLight.edit,
                      size: 18.0,
                      color: kSubTitleColor,
                    ),
                    const SizedBox(width: 2.0),
                    GestureDetector(
                      onTap: () => const SellerEditProfile().launch(context),
                      child: Text(
                        'Edit',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.0), border: Border.all(color: kBorderColorTextField)),
                  child: ReadMoreText(
                    'Hello there, This is Ibne Riead! A professional UI/UX Design experience with 2+ years in this field. I specialize in Mobile Apps and Website Design. I always try to meet the needs of my client. I specialize in Mobile Apps and Website Design. I always try to meet the needs of my client.',
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                    trimLines: 4,
                    colorClickableText: kPrimaryColor,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: '..Read more',
                    trimExpandedText: '..Read less',
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Text(
                      'Information',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(
                      IconlyLight.edit,
                      size: 18.0,
                      color: kSubTitleColor,
                    ),
                    const SizedBox(width: 2.0),
                    GestureDetector(
                      onTap: () => const SellerEditProfile().launch(context),
                      child: Text(
                        'Edit',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'First Name',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'Shahidul',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Last Name',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'Islam',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'User Name',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'shaidulislam',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Email',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'shaidulislam@gmail.com',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Phone Number',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              '(+1) 3635 654454 548',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Country',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'United States',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Address',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              '5205 North Kierland Blvd. Suite 100',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'City',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'Scottsdale',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'State',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'AZ',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'ZIP/Post Code',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              '12365',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Language',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'English',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Gender',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ':',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                          const SizedBox(width: 10.0),
                          Flexible(
                            child: Text(
                              'Male',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Text(
                      'languages',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(
                      IconlyLight.edit,
                      size: 18.0,
                      color: kSubTitleColor,
                    ),
                    const SizedBox(width: 2.0),
                    GestureDetector(
                      onTap: () => const SellerEditProfile().launch(context),
                      child: Text(
                        'Edit',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const InfoShowCaseWithoutIcon(
                  title: 'English',
                  subTitle: 'Fluent',
                ),
                const SizedBox(height: 10.0),
                const InfoShowCaseWithoutIcon(
                  title: 'Bangla',
                  subTitle: 'Fluent',
                ),
                const SizedBox(height: 25.0),
                Row(
                  children: [
                    Text(
                      'Skills',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(
                      IconlyLight.edit,
                      size: 18.0,
                      color: kSubTitleColor,
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      'Edit',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const InfoShowCaseWithoutIcon(
                  title: 'Ui Design',
                  subTitle: 'Expert',
                ),
                const SizedBox(height: 10.0),
                const InfoShowCaseWithoutIcon(
                  title: 'Visual Design',
                  subTitle: 'Expert',
                ),
                const SizedBox(height: 25.0),
                Row(
                  children: [
                    Text(
                      'Education',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(
                      IconlyLight.edit,
                      size: 18.0,
                      color: kSubTitleColor,
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      'Edit',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const SummaryWithoutIcon(
                  title: 'B.Sc. - grapich design',
                  subtitle: 'Khilgaon model university, Bangladesh,, Bangladesh, Graduated 2018',
                ),
                const SizedBox(height: 25.0),
                Row(
                  children: [
                    Text(
                      'Certification',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(
                      IconlyLight.edit,
                      size: 18.0,
                      color: kSubTitleColor,
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      'Edit',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const SummaryWithoutIcon(
                  title: 'UI/UX Design',
                  subtitle: 'Shikhbe Shobai Institute 2018',
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
