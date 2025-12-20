import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/xml_handler.dart';
import 'package:provider/provider.dart';

class AddActivityDialog extends StatefulWidget {
  final String clinicianId;
  final List<String> existingCodes; // For duplicate check

  const AddActivityDialog({
    super.key,
    required this.clinicianId,
    this.existingCodes = const [],
  });

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _type = '3'; // Default to CPT
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _netController = TextEditingController(text: '0.00');
  late final TextEditingController _clinicianController;
  final _priorAuthController = TextEditingController();

  final Map<String, String> _typeMap = {
    "3": "CPT",
    "8": "DSL",
    "5": "Drug",
    "6": "CDT",
  };

  @override
  void initState() {
    super.initState();
    _clinicianController = TextEditingController(text: widget.clinicianId);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _quantityController.dispose();
    _netController.dispose();
    _clinicianController.dispose();
    _priorAuthController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newActivity = ActivityData()
        ..type = _type
        ..code = _codeController.text
        ..quantity = _quantityController.text
        ..net = _netController.text
        ..clinician = _clinicianController.text
        ..priorAuthorizationID = _priorAuthController.text.isNotEmpty
            ? _priorAuthController.text
            : null
        ..start = context.read<ClaimDataNotifier>().claimData?.start;

      Navigator.of(context).pop(newActivity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Activity'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _typeMap.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _type = value ?? '3'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                autofocus: true, // UX: Autofocus
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                  helperText: 'CPT/Drug/Service Code',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a code';
                  }
                  if (widget.existingCodes.contains(value)) {
                    // Logic: Duplicate Warning (we can choose to block or just warn)
                    // For now, let's just return a warning text but allow it?
                    // Validator returns error string which BLOCKS submission.
                    // If user wants a warning only, we'd need a different UI.
                    // Usually "Duplicate Warning" implies blocking or explicit override.
                    // Let's making it an error for now to be safe, or we can use a helper text.
                    // Let's stick to standard validation:
                    // "Duplicate Warning" -> usually implies non-blocking visual cue.
                    // But standard Validator blocks.
                    // I'll make it show an error: "Code already exists".
                    // If the requirement is strict non-blocking warning, I would need a state variable.
                    return 'Warning: Code already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _netController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Net Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clinicianController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Clinician',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priorAuthController,
                textInputAction: TextInputAction.done, // UX: Enter to submit
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Prior Authorization ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
