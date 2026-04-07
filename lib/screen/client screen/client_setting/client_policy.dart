import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class ClientPolicy extends StatefulWidget {
  const ClientPolicy({Key? key}) : super(key: key);

  @override
  State<ClientPolicy> createState() => _ClientPolicyState();
}

class _ClientPolicyState extends State<ClientPolicy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Privacy Policy',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                Text(
                  'Disclosures of Your Information',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Food First envisions a world in which all people have access to healthy, ecologically produced, and culturally appropriate food. After 40 years of analysis of the global food system, we know that making this vision a reality involves more than tech nical solutions—it requires political tran sformation. That’s why Food First supports activists, social movements, alliances, and coalitions working for systemic change. Our work—including action-oriented rese arch, publications, and projects—gives you the tools to understand the global food system, build your local food movement, and engage with the global movement for food sovereignty.',
                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Legal Disclaimer',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'We reserve the right to disclose your persona lly identifiable information as required by law and when believe it is necessary to share infor mation in order to investigate, prevent, or take action regarding illegal activities, suspected fraud, situations involving',
                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
