import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets/common/financial_input_field.dart';

class TotalsCard extends StatelessWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final validationResult = notifier.validationResult;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FinancialInputField(
          label: 'Gross:',
          controller: notifier.grossController,
          difference: notifier.grossDifference,
          validationError: validationResult?.getFirstErrorForField('gross'),
          onChanged: () => notifier.onTotalsEdited('gross'),
        ),
        const SizedBox(height: 4),
        FinancialInputField(
          label: 'PatientShare:',
          controller: notifier.patientShareController,
          validationError:
              validationResult?.getFirstErrorForField('patientShare'),
          onChanged: () => notifier.onTotalsEdited('pshare'),
        ),
        const SizedBox(height: 4),
        FinancialInputField(
          label: 'Net:',
          controller: notifier.netController,
          difference: notifier.netDifference,
          validationError: validationResult?.getFirstErrorForField('net'),
          onChanged: () => notifier.onTotalsEdited('net'),
        ),
      ],
    );
  }
}
