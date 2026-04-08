import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerDeliverOrder extends StatefulWidget {
  final String orderId;

  const SellerDeliverOrder({Key? key, required this.orderId}) : super(key: key);

  @override
  State<SellerDeliverOrder> createState() => _SellerDeliverOrderState();
}

class _SellerDeliverOrderState extends State<SellerDeliverOrder> {
  final _messageController = TextEditingController();
  File? _attachment;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (file != null) {
      setState(() => _attachment = File(file.path));
    }
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe your delivery')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SellerOrdersService.deliverOrder(
        orderId: widget.orderId,
        message: message,
        attachment: _attachment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order delivered successfully!')));
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
        title: Text('Deliver Order', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isSubmitting ? 'Sending...' : 'Send',
          buttonDecoration: kButtonDecoration.copyWith(color: _isSubmitting ? kLightNeutralColor : kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
          onPressed: _isSubmitting ? null : _handleSend,
          buttonTextColor: kWhite,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
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

                // File upload
                GestureDetector(
                  onTap: _pickFile,
                  child: TextFormField(
                    enabled: false,
                    decoration: kInputDecoration.copyWith(
                      labelText: 'Upload File or Image',
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      hintText: _attachment != null ? _attachment!.path.split('/').last : 'Tap to attach a file',
                      hintStyle: kTextStyle.copyWith(color: _attachment != null ? kNeutralColor : kSubTitleColor),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(FeatherIcons.upload, color: kLightNeutralColor),
                    ),
                  ),
                ),
                if (_attachment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: kPrimaryColor, size: 16),
                        const SizedBox(width: 5),
                        Expanded(child: Text(_attachment!.path.split('/').last, style: kTextStyle.copyWith(color: kPrimaryColor), overflow: TextOverflow.ellipsis)),
                        GestureDetector(
                          onTap: () => setState(() => _attachment = null),
                          child: const Icon(Icons.close, color: Colors.red, size: 18),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 5.0),
                Text('Max size 1 GB', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                const SizedBox(height: 20.0),

                // Delivery message
                TextFormField(
                  controller: _messageController,
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  maxLines: 4,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Describe your delivery in details',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter your delivery details...',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
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
