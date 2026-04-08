import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/seller_service_management.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../widgets/constant.dart';

class CreateNewService extends StatefulWidget {
  const CreateNewService({Key? key}) : super(key: key);

  @override
  State<CreateNewService> createState() => _CreateNewServiceState();
}

class _CreateNewServiceState extends State<CreateNewService> {
  PageController pageController = PageController(initialPage: 0);
  int currentIndexPage = 0;
  bool _isSubmitting = false;

  // Step 1 fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _selectedServiceType = 'online';
  String _selectedDeliveryTime = '3';
  String _selectedRevisions = '0';
  bool _isCategoriesLoading = true;

  // Step 2 fields — images
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Step 3 fields — requirements
  final List<TextEditingController> _requirementControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (final c in _requirementControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await SellerServiceManagement.getCategories();
      if (mounted) setState(() { _categories = cats; _isCategoriesLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isCategoriesLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 3 images')));
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedImages.add(File(image.path)));
    }
  }

  void _addRequirementField() {
    setState(() => _requirementControllers.add(TextEditingController()));
  }

  void _removeRequirementField(int index) {
    if (_requirementControllers.length > 1) {
      setState(() {
        _requirementControllers[index].dispose();
        _requirementControllers.removeAt(index);
      });
    }
  }

  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a service title')));
      return false;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a price')));
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      // Upload images
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await SellerServiceManagement.uploadServiceImages(_selectedImages);
      }

      // Create service
      final service = await SellerServiceManagement.createService(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        serviceType: _selectedServiceType,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        deliveryTime: int.tryParse(_selectedDeliveryTime) ?? 3,
        revisionCount: int.tryParse(_selectedRevisions) ?? 0,
        imageUrls: imageUrls,
      );

      // Add requirements
      final requirements = _requirementControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => {'question': c.text.trim(), 'is_required': true})
          .toList();

      if (requirements.isNotEmpty) {
        await SellerServiceManagement.addServiceRequirements(service['id'], requirements);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service created successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleNext() {
    if (currentIndexPage == 0 && !_validateStep1()) return;
    if (currentIndexPage < 2) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _handleSubmit();
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
        title: Text('Create New Service', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: (int index) => setState(() => currentIndexPage = index),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        buttontext: _isSubmitting
            ? 'Creating...'
            : currentIndexPage < 2
                ? 'Next'
                : 'Create Service',
        buttonDecoration: kButtonDecoration.copyWith(
          color: _isSubmitting ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: _isSubmitting ? null : _handleNext,
        buttonTextColor: kWhite,
      ),
    );
  }

  Widget _buildStepHeader() {
    return Column(
      children: [
        const SizedBox(height: 20.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step ${currentIndexPage + 1} of 3',
              style: kTextStyle.copyWith(color: kNeutralColor),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: StepProgressIndicator(
                totalSteps: 3,
                currentStep: currentIndexPage + 1,
                size: 8,
                padding: 0,
                selectedColor: kPrimaryColor,
                unselectedColor: kPrimaryColor.withOpacity(0.2),
                roundedEdges: const Radius.circular(10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(topRight: Radius.circular(30.0), topLeft: Radius.circular(30.0)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(),
              const SizedBox(height: 20.0),
              Text('Overview', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15.0),

              // Title
              TextFormField(
                controller: _titleController,
                keyboardType: TextInputType.name,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                maxLength: 60,
                decoration: kInputDecoration.copyWith(
                  labelText: 'Service Title', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: 'Enter service title', hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15.0),

              // Category
              _isCategoriesLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: kInputDecoration.copyWith(
                            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                            contentPadding: const EdgeInsets.all(7.0),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: 'Category', labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              icon: const Icon(FeatherIcons.chevronDown),
                              value: _selectedCategoryId,
                              hint: Text('Select category', style: kTextStyle.copyWith(color: kSubTitleColor)),
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              items: _categories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['name']))).toList(),
                              onChanged: (v) => setState(() => _selectedCategoryId = v),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 15.0),

              // Service Type
              FormField(
                builder: (FormFieldState<dynamic> field) {
                  return InputDecorator(
                    decoration: kInputDecoration.copyWith(
                      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                      contentPadding: const EdgeInsets.all(7.0),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: 'Service Type', labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        icon: const Icon(FeatherIcons.chevronDown),
                        value: _selectedServiceType,
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                        items: const [
                          DropdownMenuItem(value: 'online', child: Text('Online')),
                          DropdownMenuItem(value: 'offline', child: Text('Offline')),
                        ],
                        onChanged: (v) => setState(() => _selectedServiceType = v!),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15.0),

              // Description
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                cursorColor: kNeutralColor,
                maxLines: 4,
                maxLength: 800,
                decoration: kInputDecoration.copyWith(
                  labelText: 'Service Description', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: 'Briefly describe your service...', hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  floatingLabelBehavior: FloatingLabelBehavior.always, border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15.0),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                cursorColor: kNeutralColor,
                decoration: kInputDecoration.copyWith(
                  labelText: 'Price (\$)', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: '\$5 minimum', hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15.0),

              // Delivery Time + Revisions
              Row(
                children: [
                  Expanded(
                    child: FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: kInputDecoration.copyWith(
                            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                            contentPadding: const EdgeInsets.all(7.0),
                            labelText: 'Delivery (days)', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              icon: const Icon(FeatherIcons.chevronDown, size: 18),
                              value: _selectedDeliveryTime,
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              items: ['3', '5', '7', '12', '15', '20'].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                              onChanged: (v) => setState(() => _selectedDeliveryTime = v!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: kInputDecoration.copyWith(
                            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                            contentPadding: const EdgeInsets.all(7.0),
                            labelText: 'Revisions', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              icon: const Icon(FeatherIcons.chevronDown, size: 18),
                              value: _selectedRevisions,
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                              items: const [
                                DropdownMenuItem(value: '0', child: Text('Unlimited')),
                                DropdownMenuItem(value: '1', child: Text('1')),
                                DropdownMenuItem(value: '2', child: Text('2')),
                                DropdownMenuItem(value: '3', child: Text('3')),
                                DropdownMenuItem(value: '5', child: Text('5')),
                              ],
                              onChanged: (v) => setState(() => _selectedRevisions = v!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(topRight: Radius.circular(30.0), topLeft: Radius.circular(30.0)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(),
              const SizedBox(height: 20.0),
              Text('Images (Up to 3)', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15.0),

              // Selected images
              ..._selectedImages.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: kWhite, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Add image button
              if (_selectedImages.length < 3)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        const Icon(IconlyBold.image, color: kLightNeutralColor, size: 50),
                        const SizedBox(height: 10.0),
                        Text('Tap to Upload Image', style: kTextStyle.copyWith(color: kSubTitleColor)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(topRight: Radius.circular(30.0), topLeft: Radius.circular(30.0)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Text('Service Requirements', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _addRequirementField,
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: kPrimaryColor, size: 20),
                        const SizedBox(width: 4),
                        Text('Add', style: kTextStyle.copyWith(color: kPrimaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Text('Questions buyers must answer when ordering', style: kTextStyle.copyWith(color: kLightNeutralColor)),
              const SizedBox(height: 15.0),

              ..._requirementControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          keyboardType: TextInputType.text,
                          cursorColor: kNeutralColor,
                          decoration: kInputDecoration.copyWith(
                            hintText: 'e.g. What style do you prefer?',
                            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_requirementControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeRequirementField(entry.key),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
