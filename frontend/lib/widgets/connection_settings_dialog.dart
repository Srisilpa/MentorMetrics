import 'package:flutter/material.dart';
import '../services/session_service.dart';

class ConnectionSettingsDialog extends StatefulWidget {
  const ConnectionSettingsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => const ConnectionSettingsDialog(),
    );
  }

  @override
  State<ConnectionSettingsDialog> createState() => _ConnectionSettingsDialogState();
}

class _ConnectionSettingsDialogState extends State<ConnectionSettingsDialog> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await SessionService.getBaseUrl();
    setState(() {
      _controller.text = url;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isNotEmpty) {
      await SessionService.setBaseUrl(url);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend API URL set to $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_ethernet_rounded, color: Color(0xFF3157D5)),
          SizedBox(width: 10),
          Text('API Server Settings'),
        ],
      ),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Specify the backend FastAPI server URL:',
                  style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Backend Base URL',
                    hintText: 'http://127.0.0.1:8000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Web / Local PC (127.0.0.1)'),
                      onPressed: () => _controller.text = 'http://127.0.0.1:8000',
                    ),
                    ActionChip(
                      label: const Text('Android Emulator (10.0.2.2)'),
                      onPressed: () => _controller.text = 'http://10.0.2.2:8000',
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
