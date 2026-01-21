import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/notifiers.dart';

import 'package:project_xmedit/models/validation_result.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';
import 'package:provider/provider.dart';

class ClaimDetailsCard extends StatelessWidget {
  const ClaimDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final claimData = notifier.claimData;
    final validationResult = notifier.validationResult;

    if (claimData == null) return const SizedBox.shrink();

    return Column(
      children: [
        _DetailRow(
          label: "Claim ID",
          value: claimData.claimId,
          validationError: validationResult?.getFirstErrorForField('claimId'),
          canCopy: true,
        ),
        const Divider(height: 1),
        _DetailRow(
          label: "Member ID",
          value: claimData.memberID,
          validationError: validationResult?.getFirstErrorForField('memberID'),
          canCopy: true,
        ),
        const Divider(height: 1),
        _DetailRow(
          label: "Sender ID",
          value: claimData.senderID,
          validationError: validationResult?.getFirstErrorForField('senderID'),
        ),
        const Divider(height: 1),
        _DetailRow(
          label: "Payer ID",
          value: claimData.payerID,
          validationError: validationResult?.getFirstErrorForField('payerID'),
        ),
        const Divider(height: 1),
        _DetailRow(
          label: "Receiver ID",
          value: claimData.receiverID,
          validationError:
              validationResult?.getFirstErrorForField('receiverID'),
        ),
        const Divider(height: 1),
        _DetailRow(
          label: "Transaction Date",
          value: claimData.transactionDate,
        ),
        const Divider(height: 1),
        _DetailRow(
          label: "Start Date",
          value: claimData.start,
          validationError:
              validationResult?.getFirstErrorForField('encounterStart'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final ValidationError? validationError;
  final bool canCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.validationError,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = (value == null || value!.isEmpty) ? 'N/A' : value!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (validationError != null) ...[
                  const SizedBox(width: 4),
                  ValidationIndicator(error: validationError!, size: 14),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    displayValue,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      if (value != null && value!.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: value!));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1),
                        ));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.copy,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
