import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
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
          title: const Text(AppStrings.deleteLocation),
          content: Text(
            AppStrings.deleteLocationPrompt(widget.location.displayLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                final locationProvider = context.read<LocationProvider>();
                locationProvider.deleteLocation(widget.location.id);
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close edit screen
              },
              child: const Text(
                AppStrings.delete,
                style: TextStyle(color: Colors.red),
              ),
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
          title: const Text(AppStrings.editLocation),
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
                AppStrings.customLabel,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              // OREF name (read-only)
              const Text(
                AppStrings.area,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.readOnlyBorderColor(context),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.readOnlySurfaceColor(context),
                ),
                child: Text(
                  widget.location.orefName,
                  style: TextStyle(color: AppTheme.readOnlyTextColor(context)),
                ),
              ),
              const SizedBox(height: 16),
              // Primary checkbox
              CheckboxListTile(
                title: const Text(AppStrings.primaryLocation),
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
                      child: const Text(AppStrings.save),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text(AppStrings.delete),
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
