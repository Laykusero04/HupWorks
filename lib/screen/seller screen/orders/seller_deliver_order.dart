import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/l10n/l10n.dart';
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
  static const _maxAttachmentBytes = 1024 * 1024 * 1024; // 1 GB

  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _attachment;
  bool _isSubmitting = false;
  bool _didSubmit = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _hasDraft =>
      !_didSubmit &&
      (_messageController.text.trim().isNotEmpty || _attachment != null);

  String _fileName(String path) => path.replaceAll('\\', '/').split('/').last;

  Future<void> _setAttachment(File file) async {
    final l10n = context.l10n;
    final size = await file.length();
    if (!mounted) return;
    if (size > _maxAttachmentBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.attachmentTooLarge)),
      );
      return;
    }
    setState(() => _attachment = file);
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _setAttachment(File(picked.path));
  }

  Future<void> _pickFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _setAttachment(File(picked.path));
  }

  Future<void> _pickAnyFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    await _setAttachment(File(path));
  }

  Future<void> _showAttachOptions() async {
    if (_isSubmitting) return;
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.photoGallery),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(l10n.chooseFile),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'gallery') {
      await _pickFromGallery();
    } else if (choice == 'camera') {
      await _pickFromCamera();
    } else if (choice == 'file') {
      await _pickAnyFile();
    }
  }

  Future<bool> _confirmLeaveIfNeeded() async {
    if (!_hasDraft) return true;
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveDeliveryDraftTitle),
        content: Text(l10n.leaveDeliveryDraftMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.leaveAnyway),
          ),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _handleSend() async {
    final l10n = context.l10n;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseDescribeDelivery)),
      );
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
        _didSubmit = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderDeliveredSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSubmitting) return;
        final navigator = Navigator.of(context);
        final leave = await _confirmLeaveIfNeeded();
        if (leave && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: kNeutralColor),
          title: Text(
            l10n.deliverOrderTitle,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: kWhite),
          child: ButtonGlobalWithoutIcon(
            buttontext: _isSubmitting ? l10n.sending : l10n.send,
            buttonDecoration: kButtonDecoration.copyWith(
              color: _isSubmitting ? kLightNeutralColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: _isSubmitting ? null : _handleSend,
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20.0),
                  GestureDetector(
                    onTap: _showAttachOptions,
                    child: TextFormField(
                      enabled: false,
                      decoration: kInputDecoration.copyWith(
                        labelText: l10n.uploadFileOrImage,
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                        hintText: _attachment != null
                            ? _fileName(_attachment!.path)
                            : l10n.tapToAttachFile,
                        hintStyle: kTextStyle.copyWith(
                          color: _attachment != null
                              ? kNeutralColor
                              : kSubTitleColor,
                        ),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(
                          FeatherIcons.upload,
                          color: kLightNeutralColor,
                        ),
                      ),
                    ),
                  ),
                  if (_attachment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: kPrimaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _fileName(_attachment!.path),
                              style: kTextStyle.copyWith(color: kPrimaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => setState(() => _attachment = null),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 5.0),
                  Text(
                    l10n.maxSize1Gb,
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _messageController,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.multiline,
                    cursorColor: kNeutralColor,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: kInputDecoration.copyWith(
                      labelText: l10n.describeDeliveryDetails,
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      hintText: l10n.enterDeliveryDetailsHint,
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
      ),
    );
  }
}
