import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_view_model.dart';
import 'package:productoraempacadora/features/administracion/domain/entities/finca.dart';

class FincaFormScreen extends ConsumerStatefulWidget {
  final Finca? finca;

  const FincaFormScreen({super.key, this.finca});

  @override
  ConsumerState<FincaFormScreen> createState() => _FincaFormScreenState();
}

class _FincaFormScreenState extends ConsumerState<FincaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _ubicacionCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.finca?.nombre ?? '');
    _ubicacionCtrl = TextEditingController(text: widget.finca?.ubicacion ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreCtrl.text.trim();
      final ubicacion = _ubicacionCtrl.text.trim();
      // Area Total is now calculated from sum of Lotes.
      // If editing, preserve existing areaTotal. If new, start at 0.0.
      final area = widget.finca?.areaTotal ?? 0.0;

      try {
        await ref
            .read(adminViewModelProvider.notifier)
            .saveFinca(
              id: widget.finca?.id,
              nombre: nombre,
              ubicacion: ubicacion,
              areaTotal: area,
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
        title: Text(widget.finca == null ? 'Nueva Finca' : 'Editar Finca'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacionCtrl,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Finca'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
