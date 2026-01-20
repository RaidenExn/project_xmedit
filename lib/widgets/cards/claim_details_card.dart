import 'package:flutter/material.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:provider/provider.dart';

class ClaimDetailsCard extends StatelessWidget {
  const ClaimDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final claimData = notifier.claimData;
    final validationResult = notifier.validationResult;

    if (claimData == null) return const SizedBox.shrink();

    return ScrollableOnHover(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataFieldWithCopy(
            label: "Claim ID",
            value: claimData.claimId ?? '',
            validationError: validationResult?.getFirstErrorForField('claimId'),
          ),
          const SizedBox(width: 8.0),
          DataFieldWithCopy(
            label: "Member ID",
            value: claimData.memberID ?? '',
            validationError:
                validationResult?.getFirstErrorForField('memberID'),
          ),
          const SizedBox(width: 8.0),
          SimpleDataField(
            label: "Sender ID",
            value: claimData.senderID ?? '',
            validationError:
                validationResult?.getFirstErrorForField('senderID'),
          ),
          const SizedBox(width: 8.0),
          SimpleDataField(
            label: "Payer ID",
            value: claimData.payerID ?? '',
            validationError: validationResult?.getFirstErrorForField('payerID'),
          ),
          const SizedBox(width: 8.0),
          SimpleDataField(
            label: "Receiver ID",
            value: claimData.receiverID ?? '',
            validationError:
                validationResult?.getFirstErrorForField('receiverID'),
          ),
          const SizedBox(width: 8.0),
          SimpleDataField(
            label: "Transaction Date",
            value: claimData.transactionDate ?? '',
          ),
          const SizedBox(width: 8.0),
          SimpleDataField(
            label: "Start Date",
            value: claimData.start ?? '',
            validationError:
                validationResult?.getFirstErrorForField('encounterStart'),
          ),
        ],
      ),
    );
  }
}
