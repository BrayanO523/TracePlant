import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/finca.dart';
import '../../../domain/entities/lote.dart';
import '../../providers/admin_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.lote?.nombre ?? '');
    _areaCtrl = TextEditingController(
      text: widget.lote != null ? widget.lote!.area.toString() : '',
    );
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

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
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
