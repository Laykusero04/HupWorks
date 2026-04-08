import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_profile_details.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../welcome screen/welcome_screen.dart';
import '../../widgets/constant.dart';
import '../add payment method/seller_add_payment_method.dart';
import '../buyer request/seller_buyer_request.dart';
import '../favourite/seller_favourite_list.dart';
import '../report/seller_report.dart';
import '../setting/seller_invite.dart';
import '../setting/seller_setting.dart';
import '../transaction/seller_transaction.dart';
import '../withdraw_money/seller_withdraw_history.dart';
import '../withdraw_money/seller_withdraw_money.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({Key? key}) : super(key: key);

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.signOut();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? 'Seller';
    final balance = _profile?['balance'] ?? 0;
    final profileImageUrl = _profile?['profile_image_url'];

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor), titleSpacing: 0,
        title: _isLoading ? const SizedBox() : ListTile(
          visualDensity: const VisualDensity(vertical: -4), contentPadding: EdgeInsets.zero,
          leading: Container(height: 45, width: 45, decoration: BoxDecoration(shape: BoxShape.circle, color: kDarkWhite,
            image: DecorationImage(image: profileImageUrl != null ? NetworkImage(profileImageUrl) as ImageProvider : const AssetImage('images/profile1.png'), fit: BoxFit.cover))),
          title: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1, style: kTextStyle.copyWith(color: kNeutralColor)),
          subtitle: RichText(text: TextSpan(text: 'Balance: ', style: kTextStyle.copyWith(color: kLightNeutralColor), children: [
            TextSpan(text: '$currencySign $balance', style: kTextStyle.copyWith(color: kNeutralColor)),
          ])),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0), width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              const SizedBox(height: 20.0),
              _item(IconlyBold.profile, kPrimaryColor, const Color(0xFFE2EED8), 'My Profile', () async { await const SellerProfileDetails().launch(context); _loadProfile(); }),
              _item(IconlyBold.buy, const Color(0xFF144BD6), const Color(0xFFE3EDFF), 'Buyer Requests', () => const SellerBuyerRequest().launch(context)),
              _item(IconlyBold.wallet, const Color(0xFFFF7A00), const Color(0xFFFFEFE0), 'Payment Methods', () => const SellerAddPaymentMethod().launch(context)),
              _item(IconlyBold.heart, const Color(0xFF7E5BFF), const Color(0xFFE8E1FF), 'Favorite', () => const SellerFavList().launch(context)),
              _item(IconlyBold.ticketStar, const Color(0xFFFF3B30), const Color(0xFFFFE5E3), 'Transaction', () => const SellerTransaction().launch(context)),
              _item(IconlyBold.download, kPrimaryColor, const Color(0xFFE2EED8), 'Withdraw Money', () => const SellerWithdrawMoney().launch(context)),
              _item(IconlyBold.timeCircle, const Color(0xFF06AEF3), const Color(0xFFD0F1FF), 'Withdraw History', () => const SellerWithDrawHistory().launch(context)),
              _item(IconlyBold.document, const Color(0xFF06AEF3), const Color(0xFFD0F1FF), 'Report', () => const SellerReport().launch(context)),
              _item(IconlyBold.setting, const Color(0xFFFF298C), const Color(0xFFFFDDED), 'Setting', () => const SellerSetting().launch(context)),
              _item(IconlyBold.addUser, kPrimaryColor, const Color(0xFFE2EED8), 'Invite Friends', () => const SellerInvite().launch(context)),
              _item(IconlyBold.logout, const Color(0xFFFF7A00), const Color(0xFFFFEFE0), 'Log Out', _handleLogout),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, Color iconColor, Color bgColor, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap, visualDensity: const VisualDensity(vertical: -3), horizontalTitleGap: 10, contentPadding: const EdgeInsets.only(bottom: 15),
      leading: Container(padding: const EdgeInsets.all(10.0), decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor), child: Icon(icon, color: iconColor)),
      title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1, style: kTextStyle.copyWith(color: kNeutralColor)),
      trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
    );
  }
}
