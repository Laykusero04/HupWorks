import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import 'chat_inbox.dart';
import 'model/chat_model.dart';
import 'provider/data_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ignore: non_constant_identifier_names
  List<ChatModel> list_data = maanGetChatList();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: kNeutralColor),
          backgroundColor: kDarkWhite,
          elevation: 0.0,
          centerTitle: true,
          title: Text(
            'Message',
            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Container(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
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
                children: list_data.map(
                  (data) {
                    return Column(
                      children: [
                        const SizedBox(height: 10.0),
                        SettingItemWidget(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: data.title.validate(),
                          subTitle: data.subTitle.validate(),
                          leading: Image.network(data.image.validate(), height: 50, width: 50, fit: BoxFit.cover).cornerRadiusWithClipRRect(25),
                          trailing: Column(
                            children: [
                              Text('10.00 AM', style: secondaryTextStyle()),
                            ],
                          ),
                          onTap: () {
                            ChatInbox(img: data.image.validate(), name: data.title.validate()).launch(context);
                          },
                        ),
                        const Divider(
                          thickness: 1.0,
                          color: kBorderColorTextField,
                          height: 0,
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
