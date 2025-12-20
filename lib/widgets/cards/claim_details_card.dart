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
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: [
          DataFieldWithCopy(label: "Claim ID", value: claimData.claimId ?? ''),
          DataFieldWithCopy(
              label: "Member ID", value: claimData.memberID ?? ''),
          SimpleDataField(label: "Sender ID", value: claimData.senderID ?? ''),
          SimpleDataField(label: "Payer ID", value: claimData.payerID ?? ''),
          SimpleDataField(
              label: "Receiver ID", value: claimData.receiverID ?? ''),
          SimpleDataField(
              label: "Transaction Date",
              value: claimData.transactionDate ?? ''),
          SimpleDataField(label: "Start Date", value: claimData.start ?? ''),
        ],
      ),
    );
  }
}
