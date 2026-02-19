import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:productoraempacadora/features/administracion/domain/entities/cinta.dart';
import 'package:productoraempacadora/features/produccion/domain/entities/produccion_enums.dart';
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
  late String _selectedHex;

  @override
  void initState() {
    super.initState();
    _colorCtrl = TextEditingController(text: widget.cinta?.color ?? '');
    _descCtrl = TextEditingController(text: widget.cinta?.descripcion ?? '');
    _selectedHex = widget.cinta?.colorHex ?? '#E53935'; // Default Red
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Convierte hex string (#RRGGBB) a Color
  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('0xFF$clean'));
  }

  /// Convierte Color a hex string (#RRGGBB)
  String _colorToHex(Color color) {
    // ignore: deprecated_member_use
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Abre el color picker completo para escoger cualquier color
  Future<void> _openCustomColorPicker() async {
    Color pickerColor = _hexToColor(_selectedHex);

    final bool picked =
        await ColorPicker(
          color: pickerColor,
          onColorChanged: (Color color) {
            pickerColor = color;
          },
          heading: const Text(
            'Seleccione un color',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subheading: const Text('Tono del color'),
          wheelDiameter: 190,
          wheelWidth: 20,
          pickersEnabled: const <ColorPickerType, bool>{
            ColorPickerType.both: false,
            ColorPickerType.primary: true,
            ColorPickerType.accent: true,
            ColorPickerType.bw: false,
            ColorPickerType.custom: false,
            ColorPickerType.wheel: true,
          },
          enableShadesSelection: true,
          showColorCode: true,
          colorCodeHasColor: true,
          showColorName: true,
          showRecentColors: true,
          recentColors: const [],
          maxRecentColors: 5,
          borderRadius: 20,
          elevation: 4,
        ).showPickerDialog(
          context,
          barrierDismissible: false,
          constraints: const BoxConstraints(
            minHeight: 460,
            minWidth: 320,
            maxWidth: 400,
          ),
        );

    if (picked) {
      setState(() {
        _selectedHex = _colorToHex(pickerColor);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final color = _colorCtrl.text.trim();
      final descripcion = _descCtrl.text.trim();

      try {
        await ref
            .read(adminViewModelProvider.notifier)
            .saveCinta(
              id: widget.cinta?.id,
              color: color,
              descripcion: descripcion,
              colorHex: _selectedHex,
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
    final theme = Theme.of(context);
    final currentColor = _hexToColor(_selectedHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cinta == null ? 'Nueva Cinta' : 'Editar Cinta'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Color (Ej: ROJO)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_rounded),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Temporada',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              Text(
                'Referencia Visual',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seleccione un color predefinido o elija uno personalizado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // --- Preview del color seleccionado ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Color seleccionado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedHex,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Colores predefinidos ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ColorCinta.values.map((preset) {
                  final hex =
                      '#${preset.colorValue.toRadixString(16).substring(2).toUpperCase()}';
                  final isSelected = _selectedHex == hex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedHex = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(preset.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(
                                    preset.colorValue,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // --- Botón Color Personalizado ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openCustomColorPicker,
                  icon: const Icon(Icons.palette_rounded),
                  label: const Text('Elegir Color Personalizado'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar Configuración',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
