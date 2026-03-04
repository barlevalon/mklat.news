import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/saved_location.dart';
import '../providers/location_provider.dart';

class EditLocationScreen extends StatefulWidget {
  final SavedLocation location;

  const EditLocationScreen({super.key, required this.location});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  late final TextEditingController _labelController;
  late bool _isPrimary;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.location.customLabel);
    _isPrimary = widget.location.isPrimary;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _saveLocation(BuildContext context) {
    final locationProvider = context.read<LocationProvider>();

    final updatedLocation = widget.location.copyWith(
      customLabel: _labelController.text.trim(),
      isPrimary: _isPrimary,
    );

    locationProvider.updateLocation(updatedLocation);
    Navigator.pop(context);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחק מיקום'),
          content: Text("למחוק את '${widget.location.displayLabel}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () {
                final locationProvider = context.read<LocationProvider>();
                locationProvider.deleteLocation(widget.location.id);
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close edit screen
              },
              child: const Text('מחק', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ערוך מיקום'),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom label field
              const Text(
                'שם מותאם',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              // OREF name (read-only)
              const Text('אזור', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade50,
                ),
                child: Text(
                  widget.location.orefName,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 16),
              // Primary checkbox
              CheckboxListTile(
                title: const Text('מיקום ראשי'),
                value: _isPrimary,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Spacer(),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveLocation(context),
                      child: const Text('שמור'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('מחק'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
