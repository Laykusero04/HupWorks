import 'package:flutter/material.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class HireOnboardingEditorScreen extends StatefulWidget {
  final String orderId;
  final String? jobLocation;
  final String? jobLocationType;
  final String? attendanceMode;

  const HireOnboardingEditorScreen({
    super.key,
    required this.orderId,
    this.jobLocation,
    this.jobLocationType,
    this.attendanceMode,
  });

  @override
  State<HireOnboardingEditorScreen> createState() =>
      _HireOnboardingEditorScreenState();
}

class _HireOnboardingEditorScreenState extends State<HireOnboardingEditorScreen> {
  HireOnboardingPacket? _packet;
  List<HireOnboardingSection> _sections = HireOnboardingSection.defaultSections();
  final List<TextEditingController> _controllers = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await HireOnboardingService.ensureDraft(widget.orderId);
      var packet = await HireOnboardingService.getPacketForOrder(widget.orderId);
      if (packet != null) {
        var sections = packet.sections;
        sections = HireOnboardingService.sectionsWithLocationHint(
          sections: sections,
          location: widget.jobLocation,
          locationType: widget.jobLocationType,
          attendanceMode: widget.attendanceMode,
        );
        _bindSections(sections);
        setState(() {
          _packet = packet;
          _sections = sections;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _bindSections(List<HireOnboardingSection> sections) {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    for (final s in sections) {
      _controllers.add(TextEditingController(text: s.body));
    }
  }

  List<HireOnboardingSection> _sectionsFromControllers() {
    return List.generate(_sections.length, (i) {
      return _sections[i].copyWith(body: _controllers[i].text.trim());
    });
  }

  Future<void> _saveDraft() async {
    if (_packet == null) return;
    setState(() => _saving = true);
    try {
      final updated = _sectionsFromControllers();
      await HireOnboardingService.updateDraftSections(
        packetId: _packet!.id,
        sections: updated,
      );
      if (mounted) {
        setState(() {
          _sections = updated;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _publish() async {
    if (_packet == null) return;
    setState(() => _saving = true);
    try {
      final updated = _sectionsFromControllers();
      await HireOnboardingService.updateDraftSections(
        packetId: _packet!.id,
        sections: updated,
      );
      await HireOnboardingService.publish(_packet!.id);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instructions sent to freelancer'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'First-day instructions',
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share site details, access, and contacts so your hire knows what to do on day one.',
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            height: 1.35,
                          ),
                        ),
                        if (_packet?.isPublished == true) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kSecondaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Already sent. Saving and publishing again will notify the freelancer.',
                              style: kTextStyle.copyWith(
                                color: kSubTitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ...List.generate(_sections.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: kBorderColorTextField,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _sections[i].title,
                                    style: kTextStyle.copyWith(
                                      color: kNeutralColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _controllers[i],
                                    maxLines: 4,
                                    minLines: 2,
                                    decoration: InputDecoration(
                                      hintText: 'Add details…',
                                      hintStyle: kTextStyle.copyWith(
                                        color: kLightNeutralColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: kBorderColorTextField,
                                        ),
                                      ),
                                    ),
                                    style: kTextStyle.copyWith(
                                      color: kSubTitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: kWhite,
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                    child: Column(
                      children: [
                        ButtonGlobalWithoutIcon(
                          buttontext: _saving ? 'Saving…' : 'Save draft',
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kWhite,
                            border: Border.all(color: kPrimaryColor),
                          ),
                          buttonTextColor: kPrimaryColor,
                          onPressed: _saving ? () {} : _saveDraft,
                        ),
                        const SizedBox(height: 10),
                        ButtonGlobalWithoutIcon(
                          buttontext: _saving ? 'Please wait…' : 'Publish to freelancer',
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kPrimaryColor,
                          ),
                          onPressed: _saving ? () {} : _publish,
                          buttonTextColor: kWhite,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
