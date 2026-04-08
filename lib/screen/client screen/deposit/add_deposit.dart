import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/transaction_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class AddDeposit extends StatefulWidget {
  const AddDeposit({Key? key}) : super(key: key);

  @override
  State<AddDeposit> createState() => _AddDepositState();
}

class _AddDepositState extends State<AddDeposit> {
  final _amountController = TextEditingController();
  String _selectedGateway = 'paypal';
  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  final List<String> _gateways = ['paypal', 'credit_card', 'bkash'];
  final List<String> _gatewayLabels = ['PayPal', 'Credit Card', 'Bkash'];
  final List<String> _currencies = ['USD', 'BDT'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await TransactionService.createDeposit(
        amount: amount,
        gateway: _selectedGateway,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Add Deposit',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isLoading ? 'Submitting...' : 'Submit',
          buttonDecoration: kButtonDecoration.copyWith(
            color: _isLoading ? kLightNeutralColor : kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: _isLoading ? null : _handleSubmit,
          buttonTextColor: kWhite,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              FormField(
                builder: (FormFieldState<dynamic> field) {
                  return InputDecorator(
                    decoration: kInputDecoration.copyWith(
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(7.0),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: 'Select Payment Method',
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        icon: const Icon(FeatherIcons.chevronDown),
                        value: _selectedGateway,
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                        items: List.generate(_gateways.length, (i) {
                          return DropdownMenuItem(value: _gateways[i], child: Text(_gatewayLabels[i]));
                        }),
                        onChanged: (value) => setState(() => _selectedGateway = value!),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      cursorColor: kNeutralColor,
                      textInputAction: TextInputAction.done,
                      decoration: kInputDecoration.copyWith(
                        labelText: 'Amount',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                        hintText: '\$5000.00',
                        hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                        focusColor: kNeutralColor,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: kInputDecoration.copyWith(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.all(6.0),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: 'Currency',
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              icon: const Icon(FeatherIcons.chevronDown),
                              value: _selectedCurrency,
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (value) => setState(() => _selectedCurrency = value!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
