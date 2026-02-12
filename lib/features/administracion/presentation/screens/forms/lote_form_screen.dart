import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/finca.dart';
import '../../../domain/entities/lote.dart';
import '../../providers/admin_view_model.dart';
import '../../providers/administracion_provider.dart';

class LoteFormScreen extends ConsumerStatefulWidget {
  final Finca finca;
  final Lote? lote;

  const LoteFormScreen({super.key, required this.finca, this.lote});

  @override
  ConsumerState<LoteFormScreen> createState() => _LoteFormScreenState();
}

class _LoteFormScreenState extends ConsumerState<LoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _areaCtrl;
  String? _selectedVariedadId;
  String? _selectedVariedadNombre;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.lote?.nombre ?? '');
    _areaCtrl = TextEditingController(
      text: widget.lote != null ? widget.lote!.area.toString() : '',
    );
    _selectedVariedadId = widget.lote?.variedadId;
    _selectedVariedadNombre = widget.lote?.variedadNombre;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreCtrl.text.trim();
      final area = double.parse(_areaCtrl.text.trim());

      try {
        await ref
            .read(adminViewModelProvider.notifier)
            .saveLote(
              id: widget.lote?.id,
              nombre: nombre,
              area: area,
              fincaId: widget.finca.id,
              variedadId: _selectedVariedadId!,
              variedadNombre: _selectedVariedadNombre!,
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
    final variedadesAsync = ref.watch(variedadesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lote == null ? 'Nuevo Lote' : 'Editar Lote'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (Ej: Sector Norte)',
                    prefixIcon: Icon(Icons.grass_rounded),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),

                const SizedBox(height: 16),

                // Area
                TextFormField(
                  controller: _areaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Área (m²)',
                    prefixIcon: Icon(Icons.square_foot_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Inválido';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Variedad Dropdown
                variedadesAsync.when(
                  data: (variedades) {
                    if (variedades.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay variedades registradas. Cree una primero.',
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedVariedadId,
                      decoration: const InputDecoration(
                        labelText: 'Variedad',
                        prefixIcon: Icon(Icons.eco_rounded),
                      ),
                      items: variedades.map((v) {
                        return DropdownMenuItem(
                          value: v.id,
                          child: Text(v.nombre),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setState(() {
                          _selectedVariedadId = id;
                          _selectedVariedadNombre = variedades
                              .firstWhere((v) => v.id == id)
                              .nombre;
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione una variedad' : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text(
                    'Error al cargar variedades: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedVariedadId == null && widget.lote == null
                        ? null // Disable if no variety selected
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Guardar Lote'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
