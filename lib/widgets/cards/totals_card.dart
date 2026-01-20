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

  @override
  void initState() {
    super.initState();
    _grossController = TextEditingController();
    _patientShareController = TextEditingController();
    _netController = TextEditingController();
  }

  @override
  void dispose() {
    _grossController.dispose();
    _patientShareController.dispose();
    _netController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllers();
  }

  void _syncControllers() {
    final notifier = context.watch<ClaimDataNotifier>();
    final data = notifier.claimData;
    if (data == null) return;

    if (_grossController.text != data.gross) {
      // Only update if not focused? Or always?
      // For simplicity, we check if the value is actually different to avoid cursor jumps if possible,
      // but typically full sync on external change is needed.
      // However, context.watch triggers on every keystroke if we implement update logic in onChanged.
      // So we must check if the change originated from us.
      // We can check if the widget is focused.

      // actually, simpler: use the values from notifier for initial/external updates.
      // But if we are typing, we are the source of truth transiently.

      // Let's just set text if it differs significantly or we are not the ones editing.
      // But we don't know who is editing.
    }
  }

  // Actually, keeping controllers in Notifier was solving this sync problem.
  // The correct pattern for "Unidirectional Data Flow" with Flutter TextFields is tricky.
  // 1. Controller holds State.
  // 2. onChanged -> Action -> Store Update -> Notify.
  // 3. Widget rebuilds.
  // 4. Controller.text = Store.value.
  // This causes cursor reset to end unless carefully handled.

  // Given the complexity and "Simplification" goal, maybe just moving logic to "view_models" is better than strict UDF here.

  // BUT, let's look at `_updateControllers` in Notifier. It only sets text when loading XML.
  // It does NOT set text on every `notifyListeners`.
  // So I can replicate this.

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
          !_grossController.selection.isValid) {
        _grossController.text = notifier.claimData!.gross ?? '';
      }
      if (_patientShareController.text != notifier.claimData!.patientShare &&
          !_patientShareController.selection.isValid) {
        _patientShareController.text = notifier.claimData!.patientShare ?? '';
      }
      if (_netController.text != notifier.claimData!.net &&
          !_netController.selection.isValid) {
        _netController.text = notifier.claimData!.net ?? '';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FinancialInputField(
          label: 'Gross:',
          controller: _grossController,
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
    if (notifier.claimData != null) {
      // Direct update for now, ideally use setters
      notifier.claimData!.gross = _grossController.text;
      notifier.claimData!.patientShare = _patientShareController.text;
      notifier.claimData!.net = _netController.text;
      notifier
          .checkBalances(); // This triggers notifyListeners() which might re-trigger build
    }
  }
}
