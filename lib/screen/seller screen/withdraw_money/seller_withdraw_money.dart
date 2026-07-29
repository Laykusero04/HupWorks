import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/constant.dart';

class SellerWithdrawMoney extends StatefulWidget {
  const SellerWithdrawMoney({Key? key}) : super(key: key);

  @override
  State<SellerWithdrawMoney> createState() => _SellerWithdrawMoneyState();
}

class _SellerWithdrawMoneyState extends State<SellerWithdrawMoney> {
  final _amountController = TextEditingController();
  String _selectedGateway = 'paypal';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.pleaseEnterValidAmount)));
      return;
    }

    setState(() => _isSubmitting = true);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    try {
      if (user == null) throw Exception('Not logged in');

      await client.from('withdrawal_requests').insert({
        'seller_id': user.id,
        'amount': amount,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.withdrawalRequestSubmitted)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(l10n.withdrawMoney, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isSubmitting ? context.l10n.submitting : context.l10n.submit, buttonTextColor: kWhite,
          buttonDecoration: kButtonDecoration.copyWith(color: _isSubmitting ? kLightNeutralColor : kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
          onPressed: _isSubmitting ? null : _handleSubmit,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0), width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20.0),
            FormField(
              builder: (FormFieldState<dynamic> field) => InputDecorator(
                decoration: kInputDecoration.copyWith(
                  enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                  contentPadding: const EdgeInsets.all(7.0), floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: context.l10n.withdrawMethod, labelStyle: kTextStyle.copyWith(color: kNeutralColor)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    icon: const Icon(FeatherIcons.chevronDown), value: _selectedGateway,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                    items: [
                      DropdownMenuItem(value: 'paypal', child: Text(l10n.paymentPayPal)),
                      DropdownMenuItem(value: 'credit_card', child: Text(l10n.paymentCreditCard)),
                      DropdownMenuItem(value: 'bkash', child: Text(l10n.paymentBkash)),
                    ],
                    onChanged: (v) => setState(() => _selectedGateway = v!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _amountController, keyboardType: TextInputType.number, cursorColor: kNeutralColor,
              decoration: kInputDecoration.copyWith(labelText: context.l10n.amount, labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                hintText: context.l10n.enterAmount, hintStyle: kTextStyle.copyWith(color: kSubTitleColor), border: const OutlineInputBorder()),
            ),
          ]),
        ),
      ),
    );
  }
}
