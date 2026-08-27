import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/core/utils/category_name.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/category_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/skill_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/category_picker_field.dart';
import '../../widgets/constant.dart';
import '../../widgets/attendance_mode_picker.dart';
import '../../widgets/job_location_fields.dart';
import '../../widgets/skill_picker_field.dart';

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
  final _customCategoryController = TextEditingController();
  LatLng? _locationPin;
  JobLocationType _locationType = JobLocationType.onsite;
  String _attendanceMode = AttendanceMode.qrInOut;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skillCatalog = [];
  final List<String> _skillNames = [];
  String? _selectedCategoryId;
  String? _customCategoryPreview;
  String _selectedJobType = 'gig';
  int _workersNeeded = 1;
  String _budgetBasis = JobPostsService.budgetBasisFixed;
  bool _limitHireCount = true;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  int _step = 0;

  static const _stepLabels = ['Basics', 'Details', 'Location', 'Budget'];
  static const _jobTypeOptions = <Map<String, String>>[
    {'value': 'gig', 'label': 'Gig'},
    {'value': 'full_time', 'label': 'Full-time'},
    {'value': 'part_time', 'label': 'Part-time'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await SkillService.listForPicker();
      if (mounted) setState(() => _skillCatalog = skills);
    } catch (_) {
      // Optional — posting still works without the catalog loaded.
    }
  }

  String? _catalogIdForSkillName(String name) {
    final key = name.trim().toLowerCase();
    for (final s in _skillCatalog) {
      final n = (s['name'] as String?)?.trim().toLowerCase() ?? '';
      if (n == key) return s['id'] as String?;
    }
    return null;
  }

  Future<void> _addSkill() async {
    if (_skillNames.length >= JobPostsService.maxJobSkills) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can add up to ${JobPostsService.maxJobSkills} skills.',
          ),
        ),
      );
      return;
    }
    await showSkillPickerSheet(
      context: context,
      skills: _skillCatalog,
      title: context.l10n.jobAlertAddSkill,
      allowCustomSkill: true,
      excludedNames: _skillNames.map((s) => s.toLowerCase()).toSet(),
      onSelected: (name) {
        final trimmed = name.trim();
        if (trimmed.isEmpty) return;
        if (_skillNames.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
          return;
        }
        setState(() => _skillNames.add(trimmed));
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _locationController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.listForPicker();
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

  void _updateCustomCategoryPreview() {
    if (_selectedCategoryId != CategoryService.otherCategoryOptionId) {
      setState(() => _customCategoryPreview = null);
      return;
    }
    final raw = _customCategoryController.text.trim();
    if (raw.isEmpty) {
      setState(() => _customCategoryPreview = null);
      return;
    }
    try {
      setState(() => _customCategoryPreview = CategoryName.normalize(raw));
    } catch (_) {
      setState(() => _customCategoryPreview = null);
    }
  }

  String? _jobTypeLabel() {
    for (final o in _jobTypeOptions) {
      if (o['value'] == _selectedJobType) return o['label'];
    }
    return _selectedJobType;
  }

  String? _selectedCategoryDisplayName() {
    if (_selectedCategoryId == null) return null;
    if (_selectedCategoryId == CategoryService.otherCategoryOptionId) {
      final p = _customCategoryPreview;
      if (p != null && p.isNotEmpty) return p;
      final raw = _customCategoryController.text.trim();
      return raw.isEmpty ? null : raw;
    }
    for (final c in _categories) {
      if (c['id'] == _selectedCategoryId) return c['name'] as String?;
    }
    return null;
  }

  String? _validateStep(int step) {
    final l10n = context.l10n;
    switch (step) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          return l10n.pleaseEnterJobTitle;
        }
        if (_selectedCategoryId == null) {
          return l10n.pleaseSelectCategory;
        }
        if (_selectedCategoryId == CategoryService.otherCategoryOptionId) {
          try {
            CategoryName.normalize(_customCategoryController.text);
          } catch (e) {
            return e is FormatException ? e.message : l10n.enterValidCategory;
          }
        }
        return null;
      case 1:
        if (_descriptionController.text.trim().isEmpty) {
          return l10n.pleaseEnterDescription;
        }
        return null;
      case 2:
        if (_locationController.text.trim().isEmpty) {
          return l10n.pleaseEnterLocation;
        }
        return null;
      default:
        return null;
    }
  }

  void _goNext() {
    FocusScope.of(context).unfocus();
    final err = _validateStep(_step);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (_step < _stepLabels.length - 1) {
      setState(() => _step++);
    }
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _handlePost() async {
    for (var s = 0; s < _stepLabels.length; s++) {
      final err = _validateStep(s);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        setState(() => _step = s);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final categoryId = await CategoryService.resolveCategoryId(
        selectedCategoryId: _selectedCategoryId,
        customCategoryRaw: _customCategoryController.text,
      );

      await JobPostsService.createJobPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: categoryId,
        budgetMin: double.tryParse(_budgetMinController.text.trim()),
        budgetMax: double.tryParse(_budgetMaxController.text.trim()),
        budgetBasis: _budgetBasis,
        jobType: _selectedJobType,
        location: _locationController.text.trim(),
        locationType: _locationType.label,
        latitude: _locationPin?.latitude,
        longitude: _locationPin?.longitude,
        workersNeeded: _limitHireCount
            ? _workersNeeded
            : JobPostsService.workersNeededNoLimitSentinel,
        attendanceMode: _locationType == JobLocationType.onsite
            ? _attendanceMode
            : AttendanceMode.disabled,
        skills: _skillNames
            .map(
              (n) => (
                name: n,
                catalogId: _catalogIdForSkillName(n),
              ),
            )
            .toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jobPostedSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _stepLabels.length - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _goBack();
      },
      child: Scaffold(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildStepHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey<int>(_step),
                        child: switch (_step) {
                          0 => _buildStepBasics(),
                          1 => _buildStepDetails(),
                          2 => _buildStepLocation(),
                          _ => _buildStepBudget(),
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildNavRow(isLastStep),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_step + 1} of ${_stepLabels.length} · ${_stepLabels[_step]}',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_step + 1) / _stepLabels.length,
            minHeight: 6,
            backgroundColor: kBorderColorTextField,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNavRow(bool isLastStep) {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _goBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: kNeutralColor,
                side: const BorderSide(color: kBorderColorTextField),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(context.l10n.back),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: _step > 0 ? 2 : 1,
          child: ButtonGlobalWithoutIcon(
            buttontext: _isLoading
                ? 'Posting…'
                : isLastStep
                    ? 'Post Job'
                    : 'Continue',
            buttonDecoration: kButtonDecoration.copyWith(
              color: _isLoading ? kLightNeutralColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: _isLoading ? null : (isLastStep ? _handlePost : _goNext),
            buttonTextColor: kWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildStepBasics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(IconlyBold.paper, 'Basics'),
        const SizedBox(height: 8),
        Text(
          'Title, category, skills, and job type.',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _titleController,
          keyboardType: TextInputType.text,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.next,
          decoration: kInputDecoration.copyWith(
            labelText: 'Job Title',
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: 'Short title for the work',
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        CategoryPickerField(
          categories: _categories,
          selectedCategoryId: _selectedCategoryId,
          isLoading: _isCategoriesLoading,
          onSelected: (value) => setState(() {
            _selectedCategoryId = value;
            _updateCustomCategoryPreview();
          }),
        ),
        if (_selectedCategoryId == CategoryService.otherCategoryOptionId) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: _customCategoryController,
            onChanged: (_) => _updateCustomCategoryPreview(),
            textCapitalization: TextCapitalization.words,
            cursorColor: kNeutralColor,
            decoration: kInputDecoration.copyWith(
              labelText: 'Category name',
              labelStyle: kTextStyle.copyWith(color: kNeutralColor),
              hintText: 'e.g. Janitor, Baker, Waiter',
              hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_customCategoryPreview != null) ...[
            const SizedBox(height: 6),
            Text(
              'Saved as: $_customCategoryPreview',
              style: kTextStyle.copyWith(color: kPrimaryColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
        const SizedBox(height: 18),
        _label(context.l10n.skills),
        const SizedBox(height: 4),
        Text(
          'Tag skills freelancers need for this job (optional).',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._skillNames.map(
              (s) => Chip(
                label: Text(s),
                onDeleted: () => setState(() => _skillNames.remove(s)),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.jobAlertAddSkill),
              onPressed: _addSkill,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Job Type'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
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
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: selected ? kPrimaryColor : kBorderColorTextField),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStepDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(IconlyBold.document, 'Details'),
        const SizedBox(height: 8),
        Text(
          'Describe the work and how many people you need.',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descriptionController,
          keyboardType: TextInputType.multiline,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.newline,
          maxLines: 6,
          minLines: 4,
          decoration: kInputDecoration.copyWith(
            labelText: 'Describe the job',
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: 'Scope, timeline, and expectations',
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _sectionHeader(IconlyBold.user2, 'Hiring'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
                          _limitHireCount ? 'Number to hire' : 'No cap until you close the job',
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
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStepLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(IconlyBold.location, 'Location'),
        const SizedBox(height: 8),
        Text(
          'On-site or remote, and where the work happens.',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 14),
        JobLocationFields(
          locationController: _locationController,
          pin: _locationPin,
          onPinChanged: (p) => setState(() => _locationPin = p),
          locationType: _locationType,
          onLocationTypeChanged: (t) => setState(() {
            _locationType = t;
            if (t == JobLocationType.remote) {
              _attendanceMode = AttendanceMode.disabled;
            } else if (_attendanceMode == AttendanceMode.disabled) {
              _attendanceMode = AttendanceMode.qrInOut;
            }
          }),
        ),
        if (_locationType == JobLocationType.onsite) ...[
          const SizedBox(height: 20),
          AttendanceModePicker(
            value: _attendanceMode,
            onChanged: (m) => setState(() => _attendanceMode = m),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStepBudget() {
    final cat = _selectedCategoryDisplayName();
    final loc = _locationController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(IconlyBold.wallet, 'Budget'),
        const SizedBox(height: 8),
        Text(
          'Optional pay range, then review and post.',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _budgetMinController,
                keyboardType: TextInputType.number,
                cursorColor: kNeutralColor,
                decoration: kInputDecoration.copyWith(
                  labelText: 'Min',
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: 'Min (optional)',
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
                decoration: kInputDecoration.copyWith(
                  labelText: 'Max',
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: 'Max (optional)',
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixText: '$currencySign ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Budget applies as'),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: kInputDecoration.copyWith(
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
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
                DropdownMenuItem(
                  value: JobPostsService.budgetBasisFixed,
                  child: Text(context.l10n.budgetBasisFixed, style: kTextStyle.copyWith(color: kNeutralColor)),
                ),
                DropdownMenuItem(
                  value: JobPostsService.budgetBasisPerHour,
                  child: Text(context.l10n.budgetBasisPerHour, style: kTextStyle.copyWith(color: kNeutralColor)),
                ),
                DropdownMenuItem(
                  value: JobPostsService.budgetBasisPerDay,
                  child: Text(context.l10n.budgetBasisPerDay, style: kTextStyle.copyWith(color: kNeutralColor)),
                ),
                DropdownMenuItem(
                  value: JobPostsService.budgetBasisPerMonth,
                  child: Text(context.l10n.budgetBasisPerMonth, style: kTextStyle.copyWith(color: kNeutralColor)),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _budgetBasis = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildReviewCard(
          title: _titleController.text.trim().isEmpty ? '—' : _titleController.text.trim(),
          category: cat ?? '—',
          skills: _skillNames.isEmpty ? '—' : _skillNames.join(', '),
          jobType: _jobTypeLabel() ?? '—',
          location: loc.isEmpty ? '—' : loc,
          locationType: _locationType.label,
          workers: _limitHireCount ? '$_workersNeeded' : 'No limit',
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildReviewCard({
    required String title,
    required String category,
    required String skills,
    required String jobType,
    required String location,
    required String locationType,
    required String workers,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kDarkWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _reviewLine('Title', title),
          _reviewLine('Category', category),
          _reviewLine('Skills', skills),
          _reviewLine('Job type', jobType),
          _reviewLine('Location', '$locationType · $location'),
          _reviewLine('Workers', workers),
        ],
      ),
    );
  }

  Widget _reviewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
            color: kPrimaryColor.withValues(alpha: 0.1),
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
          color: enabled ? kPrimaryColor.withValues(alpha: 0.1) : kDarkWhite,
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
