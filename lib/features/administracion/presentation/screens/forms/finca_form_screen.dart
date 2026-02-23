import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/admin_view_model.dart';
import '../../../domain/entities/finca.dart';
import 'polygon_editor_screen.dart';

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
  late List<LatLng> _coordenadas;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.finca?.nombre ?? '');
    _ubicacionCtrl = TextEditingController(text: widget.finca?.ubicacion ?? '');
    _coordenadas = (widget.finca?.coordenadas ?? [])
        .map((c) => LatLng(c['lat']!, c['lng']!))
        .toList();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  List<Map<String, double>> get _coordsForModel =>
      _coordenadas.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

  Future<void> _openMapEditor() async {
    final result = await Navigator.push<List<LatLng>>(
      context,
      MaterialPageRoute(
        builder: (_) => PolygonEditorScreen(initialPoints: _coordenadas),
      ),
    );
    if (result != null && mounted) {
      setState(() => _coordenadas = result);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreCtrl.text.trim();
      final ubicacion = _ubicacionCtrl.text.trim();
      final area = widget.finca?.areaTotal ?? 0.0;

      try {
        await ref
            .read(adminViewModelProvider.notifier)
            .saveFinca(
              id: widget.finca?.id,
              nombre: nombre,
              ubicacion: ubicacion,
              areaTotal: area,
              coordenadas: _coordsForModel,
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
      body: SingleChildScrollView(
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
              const SizedBox(height: 24),
              // -- SECCIÓN DE MAPA --
              InkWell(
                onTap: _openMapEditor,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _coordenadas.length >= 3
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _coordenadas.length >= 3
                          ? Colors.green
                          : Colors.amber,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 32,
                        color: _coordenadas.length >= 3
                            ? Colors.green
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _coordenadas.length >= 3
                                  ? 'Polígono Trazado'
                                  : 'Trazar en Mapa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _coordenadas.length >= 3
                                    ? Colors.green.shade800
                                    : Colors.amber.shade900,
                              ),
                            ),
                            if (_coordenadas.isNotEmpty)
                              Text(
                                '${_coordenadas.length} vértices',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
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
