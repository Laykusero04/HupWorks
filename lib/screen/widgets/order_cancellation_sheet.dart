import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Bottom sheet for freelancer to request contract cancellation.
class OrderCancellationSheet extends StatefulWidget {
  const OrderCancellationSheet({super.key});

  static Future<({String reasonCode, String reasonNote})?> show(
    BuildContext context,
  ) {
    return showModalBottomSheet<({String reasonCode, String reasonNote})?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const OrderCancellationSheet(),
      ),
    );
  }

  @override
  State<OrderCancellationSheet> createState() => _OrderCancellationSheetState();
}

class _OrderCancellationSheetState extends State<OrderCancellationSheet> {
  String _reasonCode = OrderCancellationReason.scheduleConflict;
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final note = _noteController.text.trim();
    if (note.length < OrderCancellationReason.minNoteLength) {
      setState(() => _error =
          l10n.cancellationMinChars(OrderCancellationReason.minNoteLength));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    if (!mounted) return;
    Navigator.pop(
      context,
      (reasonCode: _reasonCode, reasonNote: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final noteLen = _noteController.text.trim().length;
    final min = OrderCancellationReason.minNoteLength;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorderColorTextField,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cancellationSheetTitle,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.cancellationSheetBody,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cancellationReason,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ...OrderCancellationReason.codes.map((code) {
                final selected = _reasonCode == code;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => _reasonCode = code),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? kPrimaryColor : kBorderColorTextField,
                          width: selected ? 1.5 : 1,
                        ),
                        color: selected
                            ? kPrimaryColor.withValues(alpha: 0.06)
                            : kWhite,
                      ),
                      child: Text(
                        OrderCancellationReason.label(code, l10n),
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 3,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.cancellationExplain,
                  hintText: l10n.cancellationExplainHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.cancellationCharCount(noteLen, min),
                style: kTextStyle.copyWith(
                  color: noteLen >= min
                      ? const Color(0xFF2E7D32)
                      : kLightNeutralColor,
                  fontSize: 11,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: kTextStyle.copyWith(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ButtonGlobalWithoutIcon(
                      buttontext: l10n.back,
                      buttonTextColor: kNeutralColor,
                      buttonDecoration: kButtonDecoration.copyWith(
                        color: kWhite,
                        border: Border.all(color: kBorderColorTextField),
                      ),
                      onPressed: _submitting ? () {} : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ButtonGlobalWithoutIcon(
                      buttontext: _submitting ? l10n.sending : l10n.cancellationSubmit,
                      buttonTextColor: kWhite,
                      buttonDecoration: kButtonDecoration.copyWith(
                        color: _submitting ? kLightNeutralColor : Colors.red.shade700,
                      ),
                      onPressed: _submitting ? () {} : _submit,
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
