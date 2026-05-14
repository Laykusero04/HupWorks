import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class CreateNewJobPost extends StatefulWidget {
  const CreateNewJobPost({super.key});

  @override
  State<CreateNewJobPost> createState() => _CreateNewJobPostState();
}

class _CreateNewJobPostState extends State<CreateNewJobPost> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _locationController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _selectedJobType = 'gig';
  int _workersNeeded = 1;
  String _budgetBasis = JobPostsService.budgetBasisFixed;
  /// When false, post uses [JobPostsService.workersNeededNoLimitSentinel] (DB has no nullable column).
  bool _limitHireCount = true;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;

  static const _jobTypeOptions = <Map<String, String>>[
    {'value': 'gig', 'label': 'Gig'},
    {'value': 'full_time', 'label': 'Full-time'},
    {'value': 'part_time', 'label': 'Part-time'},
  ];

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
    _locationController.dispose();
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
      final locationText = _locationController.text.trim();
      await JobPostsService.createJobPost(
        title: title,
        description: description,
        categoryId: _selectedCategoryId,
        budgetMin: double.tryParse(_budgetMinController.text.trim()),
        budgetMax: double.tryParse(_budgetMaxController.text.trim()),
        budgetBasis: _budgetBasis,
        jobType: _selectedJobType,
        location: locationText.isEmpty ? null : locationText,
        workersNeeded: _limitHireCount
            ? _workersNeeded
            : JobPostsService.workersNeededNoLimitSentinel,
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
          'Post a Job',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                const SizedBox(height: 24.0),

                // ───── Section 1: Basics ─────
                _sectionHeader(IconlyBold.paper, 'Basics'),
                const SizedBox(height: 12.0),

                TextFormField(
                  controller: _titleController,
                  keyboardType: TextInputType.text,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Job Title',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Example: one clear line describing the work you need',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),

                _isCategoriesLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : InputDecorator(
                        decoration: kInputDecoration.copyWith(
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: 'Category',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            hint: Text('Choose the category that best fits this job', style: kTextStyle.copyWith(color: kSubTitleColor)),
                            style: kTextStyle.copyWith(color: kNeutralColor),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['id'] as String?,
                                child: Text(cat['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCategoryId = value),
                          ),
                        ),
                      ),
                const SizedBox(height: 20.0),

                _label('Job Type'),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: _jobTypeOptions.map((opt) {
                    final selected = _selectedJobType == opt['value'];
                    return ChoiceChip(
                      label: Text(opt['label']!),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedJobType = opt['value']!),
                      selectedColor: kPrimaryColor,
                      backgroundColor: kDarkWhite,
                      labelStyle: kTextStyle.copyWith(color: selected ? kWhite : kNeutralColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: BorderSide(color: selected ? kPrimaryColor : kBorderColorTextField),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28.0),

                // ───── Section 2: Hiring ─────
                _sectionHeader(IconlyBold.user2, 'Hiring'),
                const SizedBox(height: 12.0),

                // Workers needed: optional cap (DB stores a sentinel when uncapped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: kBorderColorTextField, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Workers needed',
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _limitHireCount
                                      ? 'How many freelancers will you hire?'
                                      : 'No fixed cap — hire until you close the job. Turn the switch on to set a maximum.',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _limitHireCount,
                            onChanged: (v) => setState(() => _limitHireCount = v),
                          ),
                        ],
                      ),
                      if (_limitHireCount) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Spacer(),
                            _stepperButton(
                              icon: Icons.remove,
                              enabled: _workersNeeded > 1,
                              onTap: () => setState(() => _workersNeeded--),
                            ),
                            Container(
                              width: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '$_workersNeeded',
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            _stepperButton(
                              icon: Icons.add,
                              enabled: _workersNeeded < 99,
                              onTap: () => setState(() => _workersNeeded++),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // Location
                TextFormField(
                  controller: _locationController,
                  keyboardType: TextInputType.text,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Location (optional)',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Example: Remote, hybrid, or general region (street address not required)',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: const Icon(Icons.location_on_outlined, color: kLightNeutralColor),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 28.0),

                // ───── Section 3: Budget ─────
                _sectionHeader(IconlyBold.wallet, 'Budget'),
                const SizedBox(height: 12.0),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _budgetMinController,
                        keyboardType: TextInputType.number,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Min',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Lowest budget (optional)',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixText: '$currencySign ',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _budgetMaxController,
                        keyboardType: TextInputType.number,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Max',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Highest budget (optional)',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixText: '$currencySign ',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _label('Budget applies as'),
                const SizedBox(height: 8.0),
                InputDecorator(
                  decoration: kInputDecoration.copyWith(
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Rate type',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _budgetBasis,
                      style: kTextStyle.copyWith(color: kNeutralColor),
                      items: [
                        DropdownMenuItem(value: JobPostsService.budgetBasisFixed, child: Text('Fixed — total project', style: kTextStyle.copyWith(color: kNeutralColor))),
                        DropdownMenuItem(value: JobPostsService.budgetBasisPerHour, child: Text('Per hour', style: kTextStyle.copyWith(color: kNeutralColor))),
                        DropdownMenuItem(value: JobPostsService.budgetBasisPerDay, child: Text('Per day', style: kTextStyle.copyWith(color: kNeutralColor))),
                        DropdownMenuItem(value: JobPostsService.budgetBasisPerMonth, child: Text('Per month', style: kTextStyle.copyWith(color: kNeutralColor))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _budgetBasis = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  _budgetBasis == JobPostsService.budgetBasisFixed
                      ? 'Min and max describe the overall budget range for completing this job.'
                      : 'Min and max are the rate range for each hour, day, or month (depending on your choice).',
                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.35),
                ),

                const SizedBox(height: 28.0),

                // ───── Section 4: Description ─────
                _sectionHeader(IconlyBold.document, 'Description'),
                const SizedBox(height: 12.0),

                TextFormField(
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.newline,
                  maxLines: 5,
                  minLines: 4,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Describe the job',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Describe scope, expected deliverables, timeline, and skills or tools you need. Keep requests clear and work-related.',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: ButtonGlobalWithoutIcon(
            buttontext: _isLoading ? 'Posting…' : 'Post Job',
            buttonDecoration: kButtonDecoration.copyWith(
              color: _isLoading ? kLightNeutralColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: _isLoading ? null : _handlePost,
            buttonTextColor: kWhite,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          child: Icon(icon, color: kPrimaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text, style: kTextStyle.copyWith(color: kNeutralColor));
  }

  Widget _stepperButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? kPrimaryColor.withOpacity(0.1) : kDarkWhite,
        ),
        child: Icon(
          icon,
          color: enabled ? kPrimaryColor : kLightNeutralColor,
          size: 20,
        ),
      ),
    );
  }
}
