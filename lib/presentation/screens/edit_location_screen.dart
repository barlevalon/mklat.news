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

  Future<void> _saveLocation(BuildContext context) async {
    final locationProvider = context.read<LocationProvider>();

    final updatedLocation = widget.location.copyWith(
      customLabel: _labelController.text.trim(),
      isPrimary: _isPrimary,
    );

    final result = await locationProvider.updateLocation(updatedLocation);
    if (!context.mounted) return;

    switch (result) {
      case UpdateLocationResult.success:
        Navigator.pop(context);
        break;
      case UpdateLocationResult.notFound:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.locationNotFound)),
        );
        break;
      case UpdateLocationResult.persistFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveLocationFailed)),
        );
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final screenContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) {
        var isDeleting = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(AppStrings.deleteLocation),
              content: Text(
                AppStrings.deleteLocationPrompt(widget.location.displayLabel),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (isDeleting) return;

                          setDialogState(() => isDeleting = true);
                          final locationProvider = screenContext
                              .read<LocationProvider>();
                          final result = await locationProvider.deleteLocation(
                            widget.location.id,
                          );
                          if (!screenContext.mounted) return;

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext); // close dialog
                          }

                          switch (result) {
                            case DeleteLocationResult.success:
                              Navigator.pop(screenContext); // close edit screen
                              break;
                            case DeleteLocationResult.notFound:
                              ScaffoldMessenger.of(screenContext).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.locationNotFound),
                                ),
                              );
                              break;
                            case DeleteLocationResult.persistFailed:
                              ScaffoldMessenger.of(screenContext).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.saveLocationFailed),
                                ),
                              );
                              break;
                          }
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<LocationProvider>().isSaving;

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
                onChanged: isSaving
                    ? null
                    : (value) {
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
                      onPressed: isSaving ? null : () => _saveLocation(context),
                      child: const Text(AppStrings.save),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving
                          ? null
                          : () => _showDeleteConfirmation(context),
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
