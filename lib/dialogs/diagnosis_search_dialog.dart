import 'package:flutter/material.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/notifiers.dart';

Future<void> showDiagnosisSearchDialog(
    BuildContext context, ClaimDataNotifier notifier) async {
  final selectedCode = await showDialog<String>(
    context: context,
    builder: (context) => const DiagnosisSearchDialog(),
  );
  if (selectedCode != null && context.mounted) {
    notifier.addDiagnosis(selectedCode);
  }
}

class DiagnosisSearchDialog extends StatefulWidget {
  const DiagnosisSearchDialog({super.key});

  @override
  State<DiagnosisSearchDialog> createState() => _DiagnosisSearchDialogState();
}

class _DiagnosisSearchDialogState extends State<DiagnosisSearchDialog> {
  final _searchController = TextEditingController();
  List<MapEntry<String, String>> _filteredDiagnoses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDiagnoses);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDiagnoses);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _filterDiagnoses() async {
    final query = _searchController.text;
    if (query.length < 2) {
      if (mounted) setState(() => _filteredDiagnoses = []);
      return;
    }
    final results = await DatabaseHelper().searchIcd10(query);
    if (mounted) {
      setState(() => _filteredDiagnoses = results);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Search Diagnosis'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Search by code or description...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredDiagnoses.isEmpty
                    ? Center(
                        child: Text(_searchController.text.length < 2
                            ? 'Type at least 2 characters to search.'
                            : 'No results found.'))
                    : ListView.builder(
                        itemCount: _filteredDiagnoses.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredDiagnoses[index];
                          return ListTile(
                            title: Text(entry.value),
                            subtitle: Text(entry.key),
                            onTap: () => Navigator.of(context).pop(entry.key),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
}
