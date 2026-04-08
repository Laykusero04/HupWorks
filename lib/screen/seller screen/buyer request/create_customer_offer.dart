import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class CreateCustomerOffer extends StatefulWidget {
  final String jobPostId;
  final String jobTitle;

  const CreateCustomerOffer({Key? key, required this.jobPostId, required this.jobTitle}) : super(key: key);

  @override
  State<CreateCustomerOffer> createState() => _CreateCustomerOfferState();
}

class _CreateCustomerOfferState extends State<CreateCustomerOffer> {
  final _amountController = TextEditingController();
  final _coverLetterController = TextEditingController();
  String _selectedDeliveryTime = '3';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SellerOrdersService.createOffer(
        jobPostId: widget.jobPostId,
        price: amount,
        deliveryTime: int.tryParse(_selectedDeliveryTime) ?? 3,
        coverLetter: _coverLetterController.text.trim().isNotEmpty ? _coverLetterController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Create Offer', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isSubmitting ? 'Submitting...' : 'Submit Offer',
          buttonDecoration: kButtonDecoration.copyWith(color: _isSubmitting ? kLightNeutralColor : kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
          onPressed: _isSubmitting ? null : _handleSubmit,
          buttonTextColor: kWhite,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),

                // Job title reference
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kDarkWhite),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, color: kPrimaryColor),
                      const SizedBox(width: 10),
                      Expanded(child: Text(widget.jobTitle, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  cursorColor: kNeutralColor,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Total Offer Amount', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter amount', hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Delivery Time
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Delivery Time', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          icon: const Icon(FeatherIcons.chevronDown),
                          value: _selectedDeliveryTime,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                          items: ['3', '5', '7', '12', '15', '20'].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                          onChanged: (v) => setState(() => _selectedDeliveryTime = v!),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20.0),

                // Cover letter
                TextFormField(
                  controller: _coverLetterController,
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  maxLines: 5,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Cover Letter (optional)', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Describe why you are the best fit...', hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always, border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
