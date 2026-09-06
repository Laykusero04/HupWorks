import 'package:flutter/material.dart';
import 'package:freelancer/data/models/seller_job_alert_rule_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/map_location_picker_screen.dart';
import 'package:freelancer/screen/widgets/skill_picker_field.dart';
import 'package:freelancer/services/category_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/seller_job_alert_service.dart';
import 'package:freelancer/services/skill_service.dart';
import 'package:latlong2/latlong.dart';

import '../../widgets/constant.dart';

class SellerJobAlertEditorScreen extends StatefulWidget {
  const SellerJobAlertEditorScreen({
    super.key,
    this.existing,
    this.initialSkillName,
    this.initialSkillNames,
    this.initialJobType,
    this.initialCategoryIds,
    this.initialMaxDistanceKm,
    this.initialIncludeRemote,
  });

  final SellerJobAlertRule? existing;
  final String? initialSkillName;
  final List<String>? initialSkillNames;
  final String? initialJobType;
  final List<String>? initialCategoryIds;
  final double? initialMaxDistanceKm;
  final bool? initialIncludeRemote;

  @override
  State<SellerJobAlertEditorScreen> createState() => _SellerJobAlertEditorScreenState();
}

class _SellerJobAlertEditorScreenState extends State<SellerJobAlertEditorScreen> {
  final _nameController = TextEditingController();

  bool _enabled = true;
  bool _includeRemote = true;
  bool _useDistance = false;
  double _distanceKm = 25;
  String? _jobType;
  final Set<String> _categoryIds = {};
  final List<String> _skillNames = [];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skillCatalog = [];
  bool _loading = true;
  bool _saving = false;

  double? _profileLat;
  double? _profileLng;
  String? _profileCity;
  String? _profileCountry;

  static const _jobTypeValues = <String?>[null, 'gig', 'full_time', 'part_time'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name ?? '';
      _enabled = existing.enabled;
      _includeRemote = existing.includeRemote;
      _jobType = existing.jobType;
      _categoryIds.addAll(existing.categoryIds);
      _skillNames.addAll(existing.skillNames);
      if (existing.maxDistanceKm != null) {
        _useDistance = true;
        _distanceKm = existing.maxDistanceKm!.clamp(5, 100);
      }
    } else {
      final seeded = <String>[
        ...?widget.initialSkillNames,
        if (widget.initialSkillName != null) widget.initialSkillName!,
      ];
      for (final raw in seeded) {
        final name = raw.trim();
        if (name.isEmpty) continue;
        if (_skillNames.any((s) => s.toLowerCase() == name.toLowerCase())) {
          continue;
        }
        _skillNames.add(name);
      }
      _jobType = widget.initialJobType;
      if (widget.initialCategoryIds != null) {
        _categoryIds.addAll(widget.initialCategoryIds!);
      }
      if (widget.initialMaxDistanceKm != null) {
        _useDistance = true;
        _distanceKm = widget.initialMaxDistanceKm!.clamp(5, 100);
      }
      if (widget.initialIncludeRemote != null) {
        _includeRemote = widget.initialIncludeRemote!;
      }
    }
    _bootstrap();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait([
        CategoryService.listForPicker(),
        SkillService.listForPicker(),
        ProfileService.getProfile(),
      ]);
      final profile = results[2] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(results[0] as List);
          _skillCatalog = List<Map<String, dynamic>>.from(results[1] as List);
          if (profile != null) {
            _profileLat = ProfileService.latitudeFromProfile(profile);
            _profileLng = ProfileService.longitudeFromProfile(profile);
            _profileCity = profile['city'] as String?;
            _profileCountry = profile['country'] as String?;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProfileLocation() async {
    final LatLng? initial = _profileLat != null && _profileLng != null
        ? LatLng(_profileLat!, _profileLng!)
        : null;
    final result = await Navigator.of(context).push<MapLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          purpose: MapLocationPickerPurpose.profile,
          initialCity: _profileCity,
          initialCountry: _profileCountry,
          initialPosition: initial,
          accentColor: kSellerPrimary,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      await ProfileService.updateProfile({
        if (result.country != null && result.country!.isNotEmpty) 'country': result.country,
        if (result.city != null && result.city!.isNotEmpty) 'city': result.city,
        'latitude': result.latitude,
        'longitude': result.longitude,
      });
      setState(() {
        _profileLat = result.latitude;
        _profileLng = result.longitude;
        _profileCity = result.city;
        _profileCountry = result.country;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _pickCategory() async {
    final selected = Set<String>.from(_categoryIds);
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.jobAlertPickCategories),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _categories.map((c) {
                    final id = c['id'] as String;
                    final name = c['name'] as String? ?? '';
                    return CheckboxListTile(
                      value: selected.contains(id),
                      title: Text(name, style: kTextStyle.copyWith(fontSize: 14)),
                      onChanged: (v) {
                        setDialogState(() {
                          if (v == true) {
                            selected.add(id);
                          } else {
                            selected.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _categoryIds
                        ..clear()
                        ..addAll(selected);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.filterApply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addSkill() async {
    await showSkillPickerSheet(
      context: context,
      skills: _skillCatalog,
      title: context.l10n.jobAlertAddSkill,
      excludedNames: _skillNames.map((s) => s.toLowerCase()).toSet(),
      onSelected: (name) {
        if (!_skillNames.any((s) => s.toLowerCase() == name.toLowerCase())) {
          setState(() => _skillNames.add(name));
        }
      },
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_useDistance && (_profileLat == null || _profileLng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jobAlertNeedProfileLocation)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final draft = SellerJobAlertRule(
        id: widget.existing?.id ?? '',
        sellerId: widget.existing?.sellerId ?? '',
        name: _nameController.text.trim(),
        enabled: _enabled,
        categoryIds: _categoryIds.toList(),
        skillNames: List<String>.from(_skillNames),
        jobType: _jobType,
        maxDistanceKm: _useDistance ? _distanceKm : null,
        includeRemote: _includeRemote,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing != null) {
        await SellerJobAlertService.updateRule(draft);
      } else {
        await SellerJobAlertService.createRule(draft);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kSellerPrimary,
          foregroundColor: kWhite,
          title: Text(widget.existing == null ? l10n.jobAlertNew : l10n.jobAlertEdit),
        ),
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    final hasCoords = _profileLat != null && _profileLng != null;
    final locationLabel = [
      if (_profileCity?.trim().isNotEmpty == true) _profileCity,
      if (_profileCountry?.trim().isNotEmpty == true) _profileCountry,
    ].whereType<String>().join(', ');

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kSellerPrimary,
        foregroundColor: kWhite,
        title: Text(widget.existing == null ? l10n.jobAlertNew : l10n.jobAlertEdit),
      ),
      bottomNavigationBar: Container(
        color: kWhite,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: ButtonGlobalWithoutIcon(
            buttontext: _saving ? l10n.saving : l10n.save,
            buttonDecoration: kButtonDecoration.copyWith(
              color: _saving ? kLightNeutralColor : kSellerPrimary,
              borderRadius: BorderRadius.circular(30),
            ),
            onPressed: _saving ? null : _save,
            buttonTextColor: kWhite,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.jobAlertNameLabel,
              hintText: l10n.jobAlertNameHint,
              filled: true,
              fillColor: kWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: Text(l10n.jobAlertEnabled, style: kTextStyle.copyWith(color: kNeutralColor)),
            activeThumbColor: primary,
            tileColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          _sectionTitle(l10n.jobAlertSkillsSection),
          Text(
            'Match jobs that are tagged with these skills.',
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
                label: Text(l10n.jobAlertAddSkill),
                onPressed: _addSkill,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(l10n.jobAlertCategoriesSection),
          OutlinedButton(
            onPressed: _pickCategory,
            child: Text(
              _categoryIds.isEmpty
                  ? l10n.jobAlertAnyCategory
                  : l10n.jobAlertCategoriesCount(_categoryIds.length),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(l10n.jobAlertJobTypeSection),
          DropdownButtonFormField<String?>(
            key: ValueKey<String?>(_jobType),
            initialValue: _jobType,
            decoration: InputDecoration(
              filled: true,
              fillColor: kWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _jobTypeValues
                .map(
                  (value) => DropdownMenuItem<String?>(
                    value: value,
                    child: Text(
                      value == null
                          ? l10n.filterAll
                          : L10nLabels.jobType(l10n, value),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _jobType = v),
          ),
          const SizedBox(height: 16),
          _sectionTitle(l10n.jobAlertLocationSection),
          Material(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    hasCoords
                        ? (locationLabel.isNotEmpty ? locationLabel : l10n.jobAlertLocationSet)
                        : l10n.jobAlertLocationMissing,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickProfileLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.pickLocationOnMap),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _useDistance,
            onChanged: (v) => setState(() => _useDistance = v),
            title: Text(l10n.jobAlertLimitDistance, style: kTextStyle.copyWith(color: kNeutralColor)),
            activeThumbColor: primary,
            tileColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          if (_useDistance) ...[
            Slider(
              value: _distanceKm,
              min: 5,
              max: 100,
              divisions: 19,
              label: l10n.jobAlertWithinKm(_distanceKm.round()),
              onChanged: (v) => setState(() => _distanceKm = v),
            ),
          ],
          SwitchListTile(
            value: _includeRemote,
            onChanged: (v) => setState(() => _includeRemote = v),
            title: Text(l10n.jobAlertIncludeRemote, style: kTextStyle.copyWith(color: kNeutralColor)),
            activeThumbColor: primary,
            tileColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: kTextStyle.copyWith(
          color: kNeutralColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
