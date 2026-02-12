import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:productoraempacadora/features/administracion/domain/entities/cinta.dart';
import '../../providers/admin_view_model.dart';

class CintaFormScreen extends ConsumerStatefulWidget {
  final Cinta? cinta;

  const CintaFormScreen({super.key, this.cinta});

  @override
  ConsumerState<CintaFormScreen> createState() => _CintaFormScreenState();
}

class _CintaFormScreenState extends ConsumerState<CintaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _colorCtrl;
  late TextEditingController _descCtrl;
  late Color _screenPickerColor;

  @override
  void initState() {
    super.initState();
    _colorCtrl = TextEditingController(text: widget.cinta?.color ?? '');
    _descCtrl = TextEditingController(text: widget.cinta?.descripcion ?? '');
    _screenPickerColor = widget.cinta != null
        ? _hexToColor(widget.cinta!.colorHex)
        : const Color(0xFFFF0000); // Default Red
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFF0000);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final color = _colorCtrl.text.trim();
      final descripcion = _descCtrl.text.trim();
      // Convert Color to Hex String #RRGGBB
      final colorHex =
          '#${_screenPickerColor.value.toRadixString(16).substring(2).toUpperCase()}';

      try {
        await ref
            .read(adminViewModelProvider.notifier)
            .saveCinta(
              id: widget.cinta?.id, // Pass ID if editing
              color: color,
              descripcion: descripcion,
              colorHex: colorHex,
            );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cinta == null ? 'Nueva Cinta' : 'Editar Cinta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'COLOR CINTA (Ej: ROJO)',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'DESCRIPCIÓN'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Color Picker Section
              Text(
                'Color Visual (Referencia)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ColorPicker(
                color: _screenPickerColor,
                onColorChanged: (Color color) {
                  setState(() => _screenPickerColor = color);
                },
                width: 40,
                height: 40,
                borderRadius: 20,
                spacing: 12,
                runSpacing: 12,
                wheelDiameter: 165,
                heading: null,
                subheading: null,
                wheelSubheading: null,
                showMaterialName: false,
                showColorName: false,
                showRecentColors: false,

                enableOpacity: false, // No transparency needed for ribbons
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.primary: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.wheel: true, // Allow wheel for custom colors
                },
              ),
              // Container to show selected color clearly
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Seleccionado: '),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _screenPickerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Cinta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
