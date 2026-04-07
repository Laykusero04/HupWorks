import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import '../seller popUp/seller_popup.dart';
import 'model/chat_model.dart';
import 'provider/data_provider.dart';

class ChatInbox extends StatefulWidget {
  final String? img;
  final String? name;

  const ChatInbox({super.key, this.img, this.name});

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  //__________Blocking_reason_popup________________________________________________
  void showBlockPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const BlockingReasonPopUp(),
            );
          },
        );
      },
    );
  }

  //__________Blocking_reason_popup________________________________________________
  void showAddFilePopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const ImportDocumentPopUp(),
            );
          },
        );
      },
    );
  }

  ScrollController scrollController = ScrollController();

  TextEditingController messageController = TextEditingController();

  FocusNode msgFocusNode = FocusNode();

  List<InboxData> data = maanInboxChatDataList();

  get kTitleColor => null;

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
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        // ignore: deprecated_member_use
        // backwardsCompatibility: true,
        leadingWidth: 24,
        iconTheme: const IconThemeData(color: kNeutralColor),
        backgroundColor: kDarkWhite,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.img.validate())),
            8.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name.validate(), style: boldTextStyle()),
                Text('Online', style: secondaryTextStyle()),
              ],
            ),
          ],
        ),
        actions: [
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
                    'Block',
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ).onTap(() => showBlockPopUp())),
                  PopupMenuItem(
                    child: Text(
                      'Report',
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
        shadowColor: kNeutralColor.withOpacity(0.5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(color: kWhite),
              child: Column(
                children: [
                  8.height,
                  Text('9:41 AM', style: secondaryTextStyle(size: 16)),
                  8.height,
                  ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    controller: scrollController,
                    scrollDirection: Axis.vertical,
                    reverse: true,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      if (data[index].id == 0) {
                        return Column(
                          children: [
                            8.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                    backgroundColor: kPrimaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(20.0),
                                      topLeft: Radius.circular(20.0),
                                      bottomLeft: Radius.circular(20.0),
                                      bottomRight: Radius.circular(0.0),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text((data[index].message).validate(), style: primaryTextStyle(color: white)),
                                ),
                                8.width,
                                CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.img.validate())),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            8.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.img.validate())),
                                8.width,
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(20.0),
                                      topLeft: Radius.circular(20.0),
                                      bottomLeft: Radius.circular(0.0),
                                      bottomRight: Radius.circular(20.0),
                                    ),
                                    backgroundColor: kDarkWhite,
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text((data[index].message).validate(), style: primaryTextStyle()),
                                ).paddingOnly(right: 42.0).expand(),
                              ],
                            ),
                          ],
                        ).paddingOnly(right: 32.0);
                      }
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ).paddingTop(8.0),
      bottomNavigationBar: Container(
        padding: MediaQuery.of(context).viewInsets,
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: context.cardColor,
          borderRadius: radius(0.0),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showAddFilePopUp();
                    });
                  },
                  child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: kDarkWhite),
                      child: const Icon(
                        FeatherIcons.link,
                        color: kNeutralColor,
                      )),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    color: kDarkWhite,
                  ),
                  child: AppTextField(
                    controller: messageController,
                    textFieldType: TextFieldType.OTHER,
                    focus: msgFocusNode,
                    autoFocus: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Message...',
                      hintStyle: secondaryTextStyle(size: 16),
                      suffixIcon: const Icon(Icons.send_outlined, size: 24, color: kPrimaryColor).paddingAll(4.0).onTap(
                        () {
                          if (messageController.text.isNotEmpty) {
                            addMessage();
                            messageController.clear();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addMessage() {
    hideKeyboard(context);
    setState(
      () {
        data.insert(0, InboxData(id: 0, message: messageController.text));
        if (mounted) scrollController.animToTop();
        FocusScope.of(context).requestFocus(msgFocusNode);
        setState(() {});
      },
    );
  }
}
