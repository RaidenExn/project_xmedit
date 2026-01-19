import 'package:flutter/material.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:provider/provider.dart';

class ClaimDetailsCard extends StatelessWidget {
  const ClaimDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final claimData = context.watch<ClaimDataNotifier>().claimData;

    if (claimData == null) return const SizedBox.shrink();

    return ScrollableOnHover(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataFieldWithCopy(label: "Claim ID", value: claimData.claimId ?? ''),
          const SizedBox(width: 8.0),
          DataFieldWithCopy(
              label: "Member ID", value: claimData.memberID ?? ''),
          const SizedBox(width: 8.0),
          SimpleDataField(label: "Sender ID", value: claimData.senderID ?? ''),
          const SizedBox(width: 8.0),
          SimpleDataField(label: "Payer ID", value: claimData.payerID ?? ''),
          const SizedBox(width: 8.0),
          SimpleDataField(
              label: "Receiver ID", value: claimData.receiverID ?? ''),
          const SizedBox(width: 8.0),
          SimpleDataField(
              label: "Transaction Date",
              value: claimData.transactionDate ?? ''),
          const SizedBox(width: 8.0),
          SimpleDataField(label: "Start Date", value: claimData.start ?? ''),
        ],
      ),
    );
  }
}
