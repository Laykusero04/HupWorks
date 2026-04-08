import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class CreateNewJobPost extends StatefulWidget {
  const CreateNewJobPost({Key? key}) : super(key: key);

  @override
  State<CreateNewJobPost> createState() => _CreateNewJobPostState();
}

class _CreateNewJobPostState extends State<CreateNewJobPost> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await JobPostsService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCategoriesLoading = false);
    }
  }

  Future<void> _handlePost() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job title')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await JobPostsService.createJobPost(
        title: title,
        description: description,
        categoryId: _selectedCategoryId,
        budgetMin: double.tryParse(_budgetMinController.text.trim()),
        budgetMax: double.tryParse(_budgetMaxController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
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
          'Create New Job Post',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30.0),
              topLeft: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Text(
                  'Overview',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
                TextFormField(
                  controller: _titleController,
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Job Title',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter job title',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Category dropdown
                _isCategoriesLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : FormField(
                        builder: (FormFieldState<dynamic> field) {
                          return InputDecorator(
                            decoration: kInputDecoration.copyWith(
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(7.0),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: 'Choose a Category',
                              labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategoryId,
                                hint: Text('Select category', style: kTextStyle.copyWith(color: kSubTitleColor)),
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat['id'],
                                    child: Text(cat['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20.0),

                // Budget range
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _budgetMinController,
                        keyboardType: TextInputType.number,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Min Budget',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: '\$5',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _budgetMaxController,
                        keyboardType: TextInputType.number,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Max Budget',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: '\$100',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                TextFormField(
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Describe The Job',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'I need a ui ux designer...',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isLoading ? 'Posting...' : 'Post',
          buttonDecoration: kButtonDecoration.copyWith(
            color: _isLoading ? kLightNeutralColor : kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: _isLoading ? null : _handlePost,
          buttonTextColor: kWhite,
        ),
      ),
    );
  }
}
