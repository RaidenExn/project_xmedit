import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/repositories/reference_data_repository.dart';

import 'package:project_xmedit/models/validation_result.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';
import 'package:provider/provider.dart';

class ClaimDetailsCard extends StatefulWidget {
  const ClaimDetailsCard({super.key});

  @override
  State<ClaimDetailsCard> createState() => _ClaimDetailsCardState();
}

class _ClaimDetailsCardState extends State<ClaimDetailsCard> {
  final ReferenceDataRepository _referenceData = ReferenceDataRepository();
  Future<_ClaimDetailsLookup>? _lookupFuture;
  String _lookupKey = '';

  String _resolveClinicianId(ClaimData claimData) {
    final fromActivity = claimData.activities
        .map((a) => (a.clinician ?? '').trim())
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    if (fromActivity.isNotEmpty) return fromActivity;
    return (claimData.providerID ?? '').trim();
  }

  void _ensureLookupFuture(ClaimData claimData) {
    final clinicianId = _resolveClinicianId(claimData);
    final payerId = (claimData.payerID ?? '').trim();
    final receiverId = (claimData.receiverID ?? '').trim();
    final key = '$clinicianId|$payerId|$receiverId';
    if (_lookupFuture != null && key == _lookupKey) return;
    _lookupKey = key;
    _lookupFuture = _loadLookup(clinicianId, payerId, receiverId);
  }

  Future<_ClaimDetailsLookup> _loadLookup(
    String clinicianId,
    String payerId,
    String receiverId,
  ) async {
    final payerNameFuture = _referenceData.getPayerName(payerId);
    final receiverNameFuture = _referenceData.getPayerName(receiverId);
    final clinicianFuture = clinicianId.isEmpty
        ? Future.value(null)
        : _referenceData.getClinicianProfile(clinicianId);

    return _ClaimDetailsLookup(
      payerName: await payerNameFuture,
      receiverName: await receiverNameFuture,
      clinicianProfile: await clinicianFuture,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final claimData = notifier.claimData;
    final validationResult = notifier.validationResult;

    if (claimData == null) return const SizedBox.shrink();
    _ensureLookupFuture(claimData);
    final clinicianId = _resolveClinicianId(claimData);

    return FutureBuilder<_ClaimDetailsLookup>(
      future: _lookupFuture,
      builder: (context, snapshot) {
        final lookup = snapshot.data;
        final clinicianProfile = lookup?.clinicianProfile;
        return Column(
          children: [
            _DetailRow(
              label: "Claim ID",
              value: claimData.claimId,
              validationError:
                  validationResult?.getFirstErrorForField('claimId'),
              canCopy: true,
            ),
            const Divider(height: 1),
            _DetailRow(
              label: "Member ID",
              value: claimData.memberID,
              validationError:
                  validationResult?.getFirstErrorForField('memberID'),
              canCopy: true,
            ),
            const Divider(height: 1),
            _DetailRow(
              label: "Sender ID",
              value: claimData.senderID,
              validationError:
                  validationResult?.getFirstErrorForField('senderID'),
            ),
            const Divider(height: 1),
            _DetailRow(
              label: "Payer ID",
              value: claimData.payerID,
              validationError:
                  validationResult?.getFirstErrorForField('payerID'),
            ),
            const Divider(height: 1),
            _DetailRow(
              label: "Payer Name",
              value: lookup?.payerName,
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
              label: "Receiver Name",
              value: lookup?.receiverName,
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
            const Divider(height: 1),
            _DetailRow(
              label: "Doctor License",
              value: clinicianId.isEmpty ? null : clinicianId,
            ),
            const Divider(height: 1),
            _DetailRow(
              label: "Doctor Name",
              value: clinicianProfile?.professionalName,
            ),
            const Divider(height: 1),
            _DetailRow(
              label: "Specialty",
              value: clinicianProfile?.specialtyDescription ??
                  clinicianProfile?.specialtyId,
            ),
          ],
        );
      },
    );
  }
}

class _ClaimDetailsLookup {
  final String? payerName;
  final String? receiverName;
  final ClinicianProfile? clinicianProfile;

  const _ClaimDetailsLookup({
    required this.payerName,
    required this.receiverName,
    required this.clinicianProfile,
  });
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    displayValue,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                    maxLines: null,
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
