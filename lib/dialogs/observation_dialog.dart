import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/xml_handler.dart';
import 'package:path/path.dart' as p;

class ObservationDialog extends StatefulWidget {
  final ActivityData activity;
  final ClaimDataNotifier notifier;

  const ObservationDialog({
    super.key,
    required this.activity,
    required this.notifier,
  });

  @override
  State<ObservationDialog> createState() => _ObservationDialogState();
}

class _ObservationDialogState extends State<ObservationDialog> {
  void _addOrEditObservation({ObservationData? existingObservation}) async {
    final result = await showDialog<ObservationData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditObservationDialog(
        observation: existingObservation,
        activity: widget.activity,
      ),
    );

    if (result != null) {
      if (existingObservation != null) {
        widget.notifier.updateObservation(widget.activity.stateId, result);
      } else {
        widget.notifier.addObservation(widget.activity.stateId, result);
      }
      setState(() {});
    }
  }

  void _deleteObservation(ObservationData observation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete the observation: ${observation.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.notifier
          .deleteObservation(widget.activity.stateId, observation.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedObservations =
        groupBy(widget.activity.observations, (ObservationData obs) => obs.type);
    final groupKeys = groupedObservations.keys.toList();

    return AlertDialog(
      title: Text('Observations for Activity ${widget.activity.code}'),
      content: SizedBox(
        width: 700,
        height: 500,
        child: widget.activity.observations.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                itemCount: groupKeys.length,
                itemBuilder: (context, index) {
                  final groupType = groupKeys[index];
                  final observationsInGroup = groupedObservations[groupType]!;
                  final isMergeable =
                      (groupType == 'Text' || groupType == 'Presenting-Complaint') &&
                          observationsInGroup.length > 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              groupType,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                            if (isMergeable)
                              TextButton.icon(
                                icon: const Icon(Icons.merge_type, size: 16),
                                label: const Text('Merge'),
                                onPressed: () {
                                  widget.notifier.mergeObservations(
                                      widget.activity.stateId, groupType);
                                  setState(() {});
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ...observationsInGroup
                          .map((obs) => _buildObservationTile(obs))
                          ,
                      const Divider(),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Observation'),
          onPressed: _addOrEditObservation,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.find_in_page_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Observations Added',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Click "Add Observation" to get started.'),
        ],
      ),
    );
  }

  Widget _buildObservationTile(ObservationData observation) {
    if (observation.type == 'File') {
      return _buildFileTile(observation);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(_getIconForType(observation.type)),
        title: Text(observation.code),
        subtitle: observation.value.isNotEmpty
            ? Text(
                'Value: ${observation.value}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: _buildActionButtons(observation),
      ),
    );
  }

  Widget _buildFileTile(ObservationData observation) {
    String fileInfo = 'Corrupt or invalid attachment data';
    try {
      final decodedBytes = base64Decode(observation.value);
      final sizeInKb = (decodedBytes.lengthInBytes / 1024).toStringAsFixed(2);
      fileInfo = '$sizeInKb KB';
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(_getIconForType(observation.type)),
        title: Text(observation.code),
        subtitle: Text('File Attachment: $fileInfo'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View'),
              onPressed: () =>
                  AttachmentHelper.viewDecodedFile(observation.value, context),
            ),
            _buildActionButtons(observation),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ObservationData observation) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () =>
              _addOrEditObservation(existingObservation: observation),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline,
              size: 20, color: theme.colorScheme.error),
          onPressed: () => _deleteObservation(observation),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'File':
        return Icons.attach_file;
      case 'Result':
        return Icons.science_outlined;
      case 'Text':
        return Icons.notes;
      case 'Presenting-Complaint':
        return Icons.emergency_outlined;
      case 'Universal Dental':
        return Icons.medical_services_outlined;
      default:
        return Icons.comment_outlined;
    }
  }
}

class AddEditObservationDialog extends StatefulWidget {
  final ObservationData? observation;
  final ActivityData activity;
  const AddEditObservationDialog(
      {super.key, this.observation, required this.activity});

  @override
  State<AddEditObservationDialog> createState() =>
      _AddEditObservationDialogState();
}

class _AddEditObservationDialogState extends State<AddEditObservationDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  late TextEditingController _codeController;
  late TextEditingController _valueController;
  late TextEditingController _valueTypeController;

  String? _fileName;
  String? _fileBase64;
  bool _isDragging = false;

  final List<String> _observationTypes = [
    'Text',
    'File',
    'Result',
    'Presenting-Complaint',
    'Universal Dental',
  ];

  @override
  void initState() {
    super.initState();
    final obs = widget.observation;
    final isCdtActivity = widget.activity.type == '6';

    _selectedType = obs?.type;
    if (_selectedType == null) {
      if (isCdtActivity) {
        _selectedType = 'Universal Dental';
      } else {
        _selectedType = _observationTypes.first;
      }
    }

    _codeController = TextEditingController(text: obs?.code ?? '');
    _valueController = TextEditingController(text: obs?.value ?? '');
    _valueTypeController = TextEditingController(text: obs?.valueType ?? '');

    if (_selectedType == 'File') {
      _fileBase64 = obs?.value;
      if (obs == null) _valueTypeController.text = 'Base64';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _valueTypeController.dispose();
    super.dispose();
  }

  Future<void> _handleFile(String path) async {
    try {
      final base64 = await AttachmentHelper.encodeFromFile(path);
      setState(() {
        _fileBase64 = base64;
        _fileName = p.basename(path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error handling file: $e')),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == 'File' && _fileBase64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or drop a file.')),
        );
        return;
      }

      final newObservation = ObservationData(
        type: _selectedType!,
        code: _codeController.text,
        value: _selectedType == 'File'
            ? _fileBase64!
            : (_selectedType == 'Universal Dental'
                ? ''
                : _valueController.text),
        valueType: _selectedType == 'Universal Dental'
            ? ''
            : _valueTypeController.text,
      );

      if (widget.observation != null) {
        newObservation.id = widget.observation!.id;
      }
      Navigator.of(context).pop(newObservation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.observation != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Observation' : 'Add Observation'),
      content: DropTarget(
        onDragDone: (details) async {
          if (details.files.isNotEmpty && _selectedType == 'File') {
            await _handleFile(details.files.first.path);
          }
        },
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        child: Container(
          decoration: _isDragging && _selectedType == 'File'
              ? BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(8.0),
                )
              : null,
          width: 500,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    items: _observationTypes
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        _codeController.clear();
                        _valueController.clear();
                        _valueTypeController.clear();
                        _fileBase64 = null;
                        _fileName = null;

                        if (_selectedType == 'File') {
                          _valueTypeController.text = 'Base64';
                        }
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Observation Type'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      helperText: 'e.g., "Attachment" or a LOINC code',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Code cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == 'File')
                    _buildFilePicker()
                  else if (_selectedType != 'Universal Dental')
                    TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Value cannot be empty' : null,
                      onChanged: (value) {
                        if (_selectedType == 'Result' &&
                            double.tryParse(value) != null) {
                          _valueTypeController.text = 'Decimal';
                        }
                      },
                    ),
                  if (_selectedType != 'File' &&
                      _selectedType != 'Universal Dental')
                    const SizedBox(height: 16),
                  if (_selectedType != 'Universal Dental')
                    TextFormField(
                      controller: _valueTypeController,
                      decoration: const InputDecoration(labelText: 'Value Type'),
                      readOnly: _selectedType == 'File',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        )
      ],
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachment (Select file or drop on window)',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Select File'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  await _handleFile(result.files.single.path!);
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _fileName ??
                    (_fileBase64 != null
                        ? 'Existing attachment loaded'
                        : 'No file selected'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}