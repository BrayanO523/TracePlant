import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/finca.dart';
import '../../../domain/entities/lote.dart';
import '../../providers/admin_view_model.dart';
import '../../providers/administracion_provider.dart';
import '../../../../../app/theme/app_colors.dart';
import 'polygon_editor_screen.dart';

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

  /// Coordenadas GPS del polígono del lote
  late List<LatLng> _coordenadas;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.lote?.nombre ?? '');
    _areaCtrl = TextEditingController(
      text: widget.lote != null ? widget.lote!.area.toString() : '',
    );
    // Cargar coordenadas existentes
    _coordenadas = (widget.lote?.coordenadas ?? [])
        .map((c) => LatLng(c['lat']!, c['lng']!))
        .toList();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  /// Convierte las coordenadas LatLng al formato que espera el modelo
  List<Map<String, double>> get _coordsForModel =>
      _coordenadas.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

  Future<void> _openMapEditor() async {
    // Obtener todos los lotes de esta finca para mostrar como referencia
    final lotesAsync = ref.read(lotesByFincaStreamProvider(widget.finca.id));
    final allLotes = lotesAsync.value ?? [];

    // Filtrar: solo lotes vecinos (con mapa) que no sean el lote actual
    final currentId = widget.lote?.id;
    final neighbors = allLotes
        .where((l) => l.tieneMapa && l.id != currentId)
        .map(
          (l) => ExistingPolygon(
            label: l.nombre,
            points: l.coordenadas
                .map((c) => LatLng(c['lat']!, c['lng']!))
                .toList(),
          ),
        )
        .toList();

    final fincaCoords = (widget.finca.coordenadas)
        .map((c) => LatLng(c['lat']!, c['lng']!))
        .toList();

    final result = await Navigator.push<List<LatLng>>(
      context,
      MaterialPageRoute(
        builder: (_) => PolygonEditorScreen(
          initialPoints: _coordenadas,
          existingPolygons: neighbors,
          parentPolygon: fincaCoords,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _coordenadas = result);
    }
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
        title: Text(widget.lote == null ? 'Nuevo Lote' : 'Editar Lote'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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

                const SizedBox(height: 24),

                // ── SECCIÓN MAPA ──
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      // Preview del polígono si existe
                      if (_coordenadas.length >= 3)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: SizedBox(
                            height: 180,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  _coordenadas
                                          .map((p) => p.latitude)
                                          .reduce((a, b) => a + b) /
                                      _coordenadas.length,
                                  _coordenadas
                                          .map((p) => p.longitude)
                                          .reduce((a, b) => a + b) /
                                      _coordenadas.length,
                                ),
                                initialZoom: 17,
                                interactionOptions: const InteractionOptions(
                                  flags: 0,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName:
                                      'com.example.productoraempacadora',
                                ),
                                PolygonLayer(
                                  polygons: [
                                    Polygon(
                                      points: _coordenadas,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderColor: AppColors.primary,
                                      borderStrokeWidth: 2,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Botón para abrir el editor de polígonos
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: OutlinedButton.icon(
                          onPressed: _openMapEditor,
                          icon: Icon(
                            _coordenadas.length >= 3
                                ? Icons.edit_location_alt_rounded
                                : Icons.add_location_alt_rounded,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            _coordenadas.length >= 3
                                ? 'Editar Polígono (${_coordenadas.length} vértices)'
                                : '📍 Mapear Terreno',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
