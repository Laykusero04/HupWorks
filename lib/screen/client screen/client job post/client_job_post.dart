import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import 'create_new_job_post.dart';
import 'job_details.dart';

class JobPost extends StatefulWidget {
  const JobPost({Key? key}) : super(key: key);

  @override
  State<JobPost> createState() => _JobPostState();
}

class _JobPostState extends State<JobPost> {
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
                    builder: (context) => const CreateNewJobPost(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  'Total Job Post (5)',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
                ListView.builder(
                  itemCount: 5,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 10.0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GestureDetector(
                        onTap: () => const JobDetails().launch(context),
                        child: Container(
                          width: context.width(),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: kWhite,
                            border: Border.all(color: kBorderColorTextField),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I Need UI UX Designer',
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10.0),
                              Text(
                                'Lorem ipsum dolor sit amet consectetur. Tortor sapien aliquam amet elit. Quis varius amet grav ida molestie rhoncus. Lorem ipsum dolor sit amet consectetur. Tortor sapien aliquam amet elit. Quis varius amet grav ida molestie rhoncus',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                              const SizedBox(height: 10.0),
                              RichText(
                                text: TextSpan(
                                  text: 'Category: ',
                                  style: kTextStyle.copyWith(color: kNeutralColor),
                                  children: [
                                    TextSpan(
                                      text: 'Logo design',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 10, right: 10),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), color: kDarkWhite),
                                    child: Text(
                                      'Completed',
                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Date: 24 Jun 2022',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ],
                              )
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
        ),
      ),
    );
  }
}
