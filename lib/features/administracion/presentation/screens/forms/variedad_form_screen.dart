import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productoraempacadora/features/administracion/domain/entities/variedad.dart';
import '../../providers/admin_view_model.dart';

class VariedadFormScreen extends ConsumerStatefulWidget {
  final Variedad? variedad;

  const VariedadFormScreen({super.key, this.variedad});

  @override
  ConsumerState<VariedadFormScreen> createState() => _VariedadFormScreenState();
}

class _VariedadFormScreenState extends ConsumerState<VariedadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.variedad?.nombre ?? '');
    _descripcionCtrl = TextEditingController(
      text: widget.variedad?.descripcion ?? '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreCtrl.text.trim();
      final descripcion = _descripcionCtrl.text.trim();

      try {
        await ref
            .read(adminViewModelProvider.notifier)
            .saveVariedad(
              id: widget.variedad?.id,
              nombre: nombre,
              descripcion: descripcion,
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
        title: Text(
          widget.variedad == null ? 'Nueva Variedad' : 'Editar Variedad',
        ),
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
                decoration: const InputDecoration(
                  labelText: 'Nombre (Ej: Hass)',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
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
                  child: const Text('Guardar Variedad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
