import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/app_colors.dart';

/// Polígono de referencia (lote vecino ya mapeado).
class ExistingPolygon {
  final String label;
  final List<LatLng> points;
  const ExistingPolygon({required this.label, required this.points});
}

/// Editor visual de polígonos sobre un mapa OpenStreetMap.
/// El usuario toca el mapa para colocar vértices que forman el terreno.
/// Retorna `List<LatLng>` al hacer pop.
class PolygonEditorScreen extends StatefulWidget {
  /// Coordenadas iniciales (para edición de un polígono existente).
  final List<LatLng> initialPoints;

  /// Polígonos de lotes vecinos (solo referencia visual, no editables).
  final List<ExistingPolygon> existingPolygons;

  /// Polígono contenedor (por ejemplo, los límites de la Finca al mapear un Lote).
  final List<LatLng> parentPolygon;

  const PolygonEditorScreen({
    super.key,
    this.initialPoints = const [],
    this.existingPolygons = const [],
    this.parentPolygon = const [],
  });

  @override
  State<PolygonEditorScreen> createState() => _PolygonEditorScreenState();
}

class _PolygonEditorScreenState extends State<PolygonEditorScreen> {
  late List<LatLng> _points;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _points = List<LatLng>.from(widget.initialPoints);
  }

  void _addPoint(LatLng point) {
    setState(() => _points.add(point));
  }

  void _undoLast() {
    if (_points.isNotEmpty) {
      setState(() => _points.removeLast());
    }
  }

  void _clearAll() {
    setState(() => _points.clear());
  }

  void _confirm() {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 3 puntos para formar un polígono'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.pop(context, _points);
  }

  @override
  Widget build(BuildContext context) {
    // Todos los puntos disponibles (propios + vecinos + padre) para calcular centro
    final allAvailable = [
      ..._points,
      ...widget.existingPolygons.expand((p) => p.points),
      ...widget.parentPolygon,
    ];

    final center = allAvailable.isNotEmpty
        ? LatLng(
            allAvailable.map((p) => p.latitude).reduce((a, b) => a + b) /
                allAvailable.length,
            allAvailable.map((p) => p.longitude).reduce((a, b) => a + b) /
                allAvailable.length,
          )
        : const LatLng(15.2, -86.2); // Centro de Honduras

    final zoom = allAvailable.isNotEmpty ? 17.0 : 7.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mapear Terreno'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            label: const Text(
              'Confirmar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Mapa ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              // Tiles de CartoDB Voyager (sin advertencias OSM)
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.productoraempacadora',
              ),

              // Polígono Padre (ej: Finca contenedora)
              if (widget.parentPolygon.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.parentPolygon,
                      color: Colors.transparent, // Transparente adentro
                      borderColor: Colors.green.shade800.withValues(
                        alpha: 0.5,
                      ), // Borde marcado
                      borderStrokeWidth: 4,
                    ),
                  ],
                ),

              // Polígonos de lotes vecinos (referencia, no editables)
              if (widget.existingPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: widget.existingPolygons.map((ep) {
                    return Polygon(
                      points: ep.points,
                      color: Colors.blueGrey.withValues(alpha: 0.15),
                      borderColor: Colors.blueGrey.withValues(alpha: 0.6),
                      borderStrokeWidth: 2,
                      label: ep.label,
                      labelStyle: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    );
                  }).toList(),
                ),

              // Polígono actual (el que el usuario está dibujando)
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _points,
                      color: AppColors.primary.withValues(alpha: 0.25),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),

              // Líneas parciales (antes de cerrar el polígono)
              if (_points.length >= 2 && _points.length < 3)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _points,
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ],
                ),

              // Marcadores en cada vértice
              MarkerLayer(
                markers: _points.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  return Marker(
                    point: point,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: index == 0 ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: index == 0
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // --- Info card superior ---
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _points.isEmpty
                          ? 'Toca el mapa para colocar los vértices del terreno'
                          : '${_points.length} punto${_points.length == 1 ? '' : 's'} colocado${_points.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Botones de acción inferiores ---
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Deshacer
                _CircleAction(
                  icon: Icons.undo_rounded,
                  tooltip: 'Deshacer último punto',
                  onTap: _points.isNotEmpty ? _undoLast : null,
                ),
                const SizedBox(width: 10),
                // Limpiar
                _CircleAction(
                  icon: Icons.delete_sweep_rounded,
                  tooltip: 'Limpiar todo',
                  onTap: _points.isNotEmpty ? _clearAll : null,
                  color: AppColors.error,
                ),
                const Spacer(),
                // Confirmar
                FilledButton.icon(
                  onPressed: _points.length >= 3 ? _confirm : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular con ícono y tooltip (sin texto, no overflow).
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.95),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 22,
              color: isEnabled ? color : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
