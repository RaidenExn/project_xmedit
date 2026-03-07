import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets/common/financial_input_field.dart';

class TotalsCard extends StatefulWidget {
  const TotalsCard({super.key});

  @override
  State<TotalsCard> createState() => _TotalsCardState();
}

class _TotalsCardState extends State<TotalsCard> {
  late TextEditingController _grossController;
  late TextEditingController _patientShareController;
  late TextEditingController _netController;
  late FocusNode _grossFocus;
  late FocusNode _patientShareFocus;
  late FocusNode _netFocus;

  @override
  void initState() {
    super.initState();
    _grossController = TextEditingController();
    _patientShareController = TextEditingController();
    _netController = TextEditingController();
    _grossFocus = FocusNode();
    _patientShareFocus = FocusNode();
    _netFocus = FocusNode();
  }

  @override
  void dispose() {
    _grossController.dispose();
    _patientShareController.dispose();
    _netController.dispose();
    _grossFocus.dispose();
    _patientShareFocus.dispose();
    _netFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final validationResult = notifier.validationResult;

    // Sync from notifier if needed (e.g. initial load or auto-match)
    // We check if the values are drastically different which implies external update.
    // Ideally we'd use a specific stream or "version" for this.
    // For now, we rely on the fact that when we edit, we update notifier.
    // If notifier updates us back, it should match what we just sent.
    if (notifier.claimData != null) {
      if (_grossController.text != notifier.claimData!.gross &&
          !_grossFocus.hasFocus) {
        _grossController.text = notifier.claimData!.gross ?? '';
      }
      if (_patientShareController.text != notifier.claimData!.patientShare &&
          !_patientShareFocus.hasFocus) {
        _patientShareController.text = notifier.claimData!.patientShare ?? '';
      }
      if (_netController.text != notifier.claimData!.net &&
          !_netFocus.hasFocus) {
        _netController.text = notifier.claimData!.net ?? '';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FinancialInputField(
          label: 'Gross:',
          controller: _grossController,
          focusNode: _grossFocus,
          difference: notifier.grossDifference,
          validationError: validationResult?.getFirstErrorForField('gross'),
          onChanged: () {
            _calculate('gross');
            _updateNotifier(notifier);
          },
        ),
        const SizedBox(height: 4),
        FinancialInputField(
          label: 'PatientShare:',
          controller: _patientShareController,
          focusNode: _patientShareFocus,
          validationError:
              validationResult?.getFirstErrorForField('patientShare'),
          onChanged: () {
            _calculate('pshare');
            _updateNotifier(notifier);
          },
        ),
        const SizedBox(height: 4),
        FinancialInputField(
          label: 'Net:',
          controller: _netController,
          focusNode: _netFocus,
          difference: notifier.netDifference,
          validationError: validationResult?.getFirstErrorForField('net'),
          onChanged: () {
            _calculate('net');
            _updateNotifier(notifier);
          },
        ),
      ],
    );
  }

  void _calculate(String source) {
    final g = double.tryParse(_grossController.text) ?? 0.0;
    final ps = double.tryParse(_patientShareController.text) ?? 0.0;
    final n = double.tryParse(_netController.text) ?? 0.0;

    switch (source) {
      case "gross":
        _netController.text = (g - ps).toStringAsFixed(2);
        break;
      case "pshare":
      case "net":
        _grossController.text = (n + ps).toStringAsFixed(2);
        break;
    }
  }

  void _updateNotifier(ClaimDataNotifier notifier) {
    if (notifier.claimData == null) return;
    notifier.setGross(_grossController.text);
    notifier.setPatientShare(_patientShareController.text);
    notifier.setNet(_netController.text);
  }
}
