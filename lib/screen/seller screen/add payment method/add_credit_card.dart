import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../widgets/constant.dart';
import '../profile/seller_profile.dart';

class AddCreditCard extends StatefulWidget {
  const AddCreditCard({Key? key}) : super(key: key);

  @override
  State<AddCreditCard> createState() => _AddCreditCardState();
}

class _AddCreditCardState extends State<AddCreditCard> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool isChecked = false;

  void onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      cardNumber = creditCardModel!.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
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
          'Add Credit or Debit Card',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
          buttontext: 'Save',
          buttonDecoration: kButtonDecoration.copyWith(borderRadius: BorderRadius.circular(30.0), color: kPrimaryColor),
          onPressed: () {
            const SellerProfile().launch(context);
          },
          buttonTextColor: kWhite),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
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
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                CreditCardWidget(
                  textStyle: kTextStyle.copyWith(fontSize: 10.0, color: Colors.white),
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  showBackView: isCvvFocused,
                  obscureCardNumber: true,
                  obscureCardCvv: true,
                  isHolderNameVisible: true,
                  cardBgColor: kPrimaryColor,
                  isSwipeGestureEnabled: true,
                  onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
                ),
                CreditCardForm(
                  formKey: formKey,
                  // Required
                  onCreditCardModelChange: onCreditCardModelChange,
                  // Required
                  obscureCvv: true,
                  obscureNumber: true,
                  cardNumber: cardNumber,
                  cvvCode: cvvCode,
                  isHolderNameVisible: true,
                  isCardNumberVisible: true,
                  isExpiryDateVisible: true,
                  cardHolderName: cardHolderName,
                  expiryDate: expiryDate,
                  // themeColor: kNeutralColor,
                  // textColor: kNeutralColor,
                  inputConfiguration: InputConfiguration(
                    cardNumberDecoration: kInputDecoration.copyWith(
                      labelText: 'Number',
                      hintText: 'XXXX XXXX XXXX XXXX',
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                      focusColor: kNeutralColor,
                      border: const OutlineInputBorder(),
                    ),
                    expiryDateDecoration: kInputDecoration.copyWith(
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                      focusColor: kNeutralColor,
                      border: const OutlineInputBorder(),
                      labelText: 'Expired Date',
                      hintText: 'XX/XX',
                    ),
                    cvvCodeDecoration: kInputDecoration.copyWith(
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                      focusColor: kNeutralColor,
                      border: const OutlineInputBorder(),
                      labelText: 'CVV',
                      hintText: 'XXX',
                    ),
                    cardHolderDecoration: kInputDecoration.copyWith(
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                      focusColor: kNeutralColor,
                      border: const OutlineInputBorder(),
                      labelText: 'Name',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
