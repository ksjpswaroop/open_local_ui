import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:open_local_ui/helpers/http.dart';
import 'package:open_local_ui/models/ollama_responses.dart';
import 'package:open_local_ui/providers/model.dart';

class PushModelDialog extends StatefulWidget {
  const PushModelDialog({super.key});

  @override
  State<PushModelDialog> createState() => _PushModelDialogState();
}

class _PushModelDialogState extends State<PushModelDialog> {
  final TextEditingController _modelSelectionController =
      TextEditingController();
  bool _isPushing = false;
  double _progressValue = 0.0;
  String _progressBarText = 'Preparing to push model...';

  void _updateProgress(OllamaPushResponse response) {
    setState(() {
      _progressValue = response.completed / response.total;

      final duration = HTTPHelpers.calculateRemainingTime(response);

      _progressBarText =
          'Status: ${response.status} - Remaining time: ${duration.inHours}:${duration.inMinutes % 60}:${duration.inSeconds % 60}';
    });
  }

  @override
  void dispose() {
    _modelSelectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry> modelsMenuEntries = [];

    for (final model in context.read<ModelProvider>().models) {
      final shortName = model.name.length > 20
          ? '${model.name.substring(0, 20)}...'
          : model.name;

      modelsMenuEntries
          .add(DropdownMenuEntry(value: model.name, label: shortName));
    }

    return AlertDialog(
      title: const Text('Push model'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: !_isPushing,
            child: Column(
              children: [
                const Text('Please select the model to push:'),
                const SizedBox(width: 8.0),
                DropdownMenu(
                  controller: _modelSelectionController,
                  inputDecorationTheme: const InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                  enableFilter: true,
                  enableSearch: true,
                  hintText: 'Select a model',
                  dropdownMenuEntries: modelsMenuEntries,
                  onSelected: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Visibility(
            visible: _isPushing,
            child: Column(
              children: [
                Text(_progressBarText),
                const SizedBox(height: 8.0),
                LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 20.0,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_isPushing ? 'Continue in background' : 'Close'),
        ),
        if (!_isPushing)
          TextButton(
            onPressed: () async {
              setState(() => _isPushing = true);

              final stream = context
                  .read<ModelProvider>()
                  .push(_modelSelectionController.text);

              await for (final data in stream) {
                if (context.mounted) _updateProgress(data);
              }

              if (context.mounted) {
                setState(() {
                  _isPushing = false;
                  _progressValue = 0.0;
                  _progressBarText = '';
                  _modelSelectionController.clear();
                });
              }
            },
            child: const Text('Start'),
          ),
      ],
    );
  }
}

Future<void> showPushModelDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) {
      return const PushModelDialog();
    },
  );
}
