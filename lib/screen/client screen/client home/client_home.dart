import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../../seller screen/seller messgae/chat_list.dart';
import '../client job post/client_job_post.dart';
import '../client orders/client_orders.dart';
import '../client profile/client_profile.dart';
import 'client_home_screen.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({Key? key}) : super(key: key);

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _currentPage = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ClientHomeScreen(),
    ChatScreen(),
    JobPost(),
    ClientOrderList(),
    ClientProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: _widgetOptions.elementAt(_currentPage),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30.0),
              topLeft: Radius.circular(30.0),
            ),
            boxShadow: [BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 3.0, offset: Offset(0, -2))]),
        child: BottomNavigationBar(
          elevation: 0.0,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kLightNeutralColor,
          backgroundColor: kWhite,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.chat),
              label: "Message",
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.paperPlus),
              label: "Job Apply",
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.document),
              label: "Orders",
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.profile),
              label: "Profile",
            ),
          ],
          onTap: (int index) {
            setState(() => _currentPage = index);
          },
          currentIndex: _currentPage,
        ),
      ),
    );
  }
}
