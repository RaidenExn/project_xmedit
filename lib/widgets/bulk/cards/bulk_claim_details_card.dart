import 'package:flutter/material.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/repositories/reference_data_repository.dart';

/// Simplified claim details card for bulk editor (read-only for now)
class BulkClaimDetailsCard extends StatefulWidget {
  final ClaimData claim;

  const BulkClaimDetailsCard({super.key, required this.claim});

  @override
  State<BulkClaimDetailsCard> createState() => _BulkClaimDetailsCardState();
}

class _BulkClaimDetailsCardState extends State<BulkClaimDetailsCard> {
  final ReferenceDataRepository _referenceData = ReferenceDataRepository();
  late Future<ClinicianProfile?> _clinicianFuture;

  @override
  void initState() {
    super.initState();
    _clinicianFuture = _loadClinician();
  }

  @override
  void didUpdateWidget(covariant BulkClaimDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.claim != widget.claim) {
      _clinicianFuture = _loadClinician();
    }
  }

  String _resolveClinicianId(ClaimData claimData) {
    final fromActivity = claimData.activities
        .map((a) => (a.clinician ?? '').trim())
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    if (fromActivity.isNotEmpty) return fromActivity;
    return (claimData.providerID ?? '').trim();
  }

  Future<ClinicianProfile?> _loadClinician() {
    final id = _resolveClinicianId(widget.claim);
    if (id.isEmpty) return Future.value(null);
    return _referenceData.getClinicianProfile(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinicianId = _resolveClinicianId(widget.claim);
    final resubmission = widget.claim.resubmission;

    return FutureBuilder<ClinicianProfile?>(
      future: _clinicianFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Claim Info', theme),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Claim ID', widget.claim.claimId, theme),
                      _buildInfoRow('Payer ID', widget.claim.payerID, theme),
                      _buildInfoRow(
                          'Provider ID', widget.claim.providerID, theme),
                      _buildInfoRow('Member ID', widget.claim.memberID, theme),
                      _buildInfoRow(
                        'Emirates ID',
                        widget.claim.emiratesIDNumber,
                        theme,
                      ),
                      _buildInfoRow(
                        'Doctor License',
                        clinicianId.isEmpty ? null : clinicianId,
                        theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          'Patient ID', widget.claim.patientId, theme),
                      _buildInfoRow(
                          'Facility ID', widget.claim.facilityID, theme),
                      _buildInfoRow(
                        'Encounter Type',
                        widget.claim.encounterType,
                        theme,
                      ),
                      _buildInfoRow('Start', widget.claim.start, theme),
                      _buildInfoRow('End', widget.claim.end, theme),
                      _buildInfoRow(
                        'Doctor Name',
                        profile?.professionalName,
                        theme,
                      ),
                      _buildInfoRow(
                        'Specialty',
                        profile?.specialtyDescription ?? profile?.specialtyId,
                        theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            _buildSectionTitle('Totals', theme),
            const SizedBox(height: 6),
            _buildInfoRow('Gross', widget.claim.gross, theme),
            _buildInfoRow('Patient Share', widget.claim.patientShare, theme),
            _buildInfoRow('Net', widget.claim.net, theme),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            _buildSectionTitle('Resubmission', theme),
            const SizedBox(height: 6),
            _buildInfoRow('Type', resubmission?.type, theme),
            _buildCommentRow('Comment', resubmission?.comment, theme),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCommentRow(String label, String? value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (value == null || value.isEmpty) ? 'N/A' : value,
            style: theme.textTheme.bodyMedium,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? 'N/A' : value,
              style: theme.textTheme.bodyMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
