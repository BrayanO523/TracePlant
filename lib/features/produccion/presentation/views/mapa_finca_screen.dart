import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../administracion/domain/entities/lote.dart';
import '../../../administracion/presentation/providers/administracion_provider.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';
import '../consultas/viewmodels/consultas_notifier.dart';

/// Mapa Termográfico GIS.
/// Pinta los lotes con polígonos de colores según su estado de producción.
class MapaFincaScreen extends ConsumerWidget {
  final String productoraId;

  const MapaFincaScreen({super.key, required this.productoraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(allLotesStreamProvider);
    final fincasAsync = ref.watch(fincasStreamProvider);
    final ciclosAsync = ref.watch(
      ciclosActivosStreamProviderFamily(productoraId),
    );
    final semanasParaCosecha = ref
        .watch(consultasProvider(productoraId))
        .semanasParaCosecha;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mapa GIS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          // Leyenda
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Leyenda de colores',
            onPressed: () => _showLegend(context),
          ),
        ],
      ),
      body: lotesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allLotes) {
          // Filtrar solo lotes que tienen mapa
          final lotes = allLotes.where((l) => l.tieneMapa).toList();

          if (lotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin Lotes Mapeados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dibuja el polígono de tus lotes en\nAdministración → Fincas → Lotes → Editar → Mapear Terreno',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Obtener ciclos (puede ser loading aún)
          final ciclos = ciclosAsync.value ?? <CicloProduccion>[];
          final fincas = fincasAsync.value ?? [];
          final fincasMapeadas = fincas.where((f) => f.tieneMapa).toList();

          // Calcular centro del mapa basado en todos los polígonos
          final allPoints = [
            ...lotes.expand((l) => l.coordenadas),
            ...fincasMapeadas.expand((f) => f.coordenadas),
          ].toList();

          final centerLat =
              allPoints.map((p) => p['lat']!).reduce((a, b) => a + b) /
              allPoints.length;
          final centerLng =
              allPoints.map((p) => p['lng']!).reduce((a, b) => a + b) /
              allPoints.length;

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 16,
            ),
            children: [
              // Tiles de CartoDB (Limpio, gratuito y sin warnings de OSM en consola)
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.productoraempacadora',
              ),

              // Polígonos de Fincas (Contenedores)
              if (fincasMapeadas.isNotEmpty)
                PolygonLayer(
                  polygons: fincasMapeadas.map((finca) {
                    final points = finca.coordenadas
                        .map((c) => LatLng(c['lat']!, c['lng']!))
                        .toList();
                    return Polygon(
                      points: points,
                      color: Colors.transparent, // Transparente adentro
                      borderColor: Colors.green.shade800.withValues(
                        alpha: 0.6,
                      ), // Borde grueso
                      borderStrokeWidth: 4,
                      label: finca.nombre,
                      labelStyle: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              // Polígonos coloreados (Lotes)
              PolygonLayer(
                polygons: lotes.map((lote) {
                  final color = _getPolygonColor(
                    lote,
                    ciclos,
                    semanasParaCosecha,
                  );
                  final points = lote.coordenadas
                      .map((c) => LatLng(c['lat']!, c['lng']!))
                      .toList();
                  return Polygon(
                    points: points,
                    color: color.withValues(alpha: 0.45),
                    borderColor: color,
                    borderStrokeWidth: 2,
                    label: lote.nombre,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Marcadores centrales (para toque / interacción)
              MarkerLayer(
                markers: lotes.map((lote) {
                  final center = _getPolygonCenter(lote);
                  final color = _getPolygonColor(
                    lote,
                    ciclos,
                    semanasParaCosecha,
                  );
                  return Marker(
                    point: center,
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showLoteInfo(
                        context,
                        lote,
                        ciclos,
                        semanasParaCosecha,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Determina el color del polígono según el estado del ciclo activo del lote.
  Color _getPolygonColor(
    Lote lote,
    List<CicloProduccion> ciclos,
    int semanasParaCosecha,
  ) {
    // Buscar ciclo activo para este lote
    final ciclo = ciclos
        .where(
          (c) =>
              c.idLote == lote.id &&
              c.estado != EstadoCiclo.cosechado &&
              c.estado != EstadoCiclo.entregado &&
              c.estado != EstadoCiclo.cancelado,
        )
        .firstOrNull;

    if (ciclo == null) {
      // Lote libre
      return Colors.grey;
    }

    // Calcular proyección
    final proyeccion = ciclo.proyeccionCosecha(semanasParaCosecha);

    if (proyeccion == null) {
      // Sembrado sin encintados aún
      return const Color(0xFF43A047); // Verde
    }

    final diasRestantes = proyeccion.difference(DateTime.now()).inDays;

    if (diasRestantes <= 0) {
      // ¡Cosecha urgente! Ya pasó o es esta semana
      return const Color(0xFFE53935); // Rojo
    } else if (diasRestantes <= 21) {
      // 1-3 semanas
      return const Color(0xFFFB8C00); // Naranja/Amarillo
    } else {
      // Más de 3 semanas
      return const Color(0xFF43A047); // Verde
    }
  }

  LatLng _getPolygonCenter(Lote lote) {
    final lat =
        lote.coordenadas.map((c) => c['lat']!).reduce((a, b) => a + b) /
        lote.coordenadas.length;
    final lng =
        lote.coordenadas.map((c) => c['lng']!).reduce((a, b) => a + b) /
        lote.coordenadas.length;
    return LatLng(lat, lng);
  }

  /// Muestra un BottomSheet con información detallada del lote.
  void _showLoteInfo(
    BuildContext context,
    Lote lote,
    List<CicloProduccion> ciclos,
    int semanasParaCosecha,
  ) {
    final ciclo = ciclos
        .where(
          (c) =>
              c.idLote == lote.id &&
              c.estado != EstadoCiclo.cosechado &&
              c.estado != EstadoCiclo.entregado &&
              c.estado != EstadoCiclo.cancelado,
        )
        .firstOrNull;

    final color = _getPolygonColor(lote, ciclos, semanasParaCosecha);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con indicador de color
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lote.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ciclo != null ? ciclo.estado.name.toUpperCase() : 'LIBRE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info grid
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.straighten_rounded,
                    label: 'Área',
                    value: '${lote.area} m²',
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.local_florist_rounded,
                    label: 'Variedad',
                    value: ciclo?.variedad.isNotEmpty == true
                        ? ciclo!.variedad
                        : lote.variedad,
                  ),
                ],
              ),

              if (ciclo != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: 'Siembra',
                      value: _formatDate(ciclo.fechaSiembra),
                    ),
                    const SizedBox(width: 12),
                    if (ciclo.encintados.isNotEmpty)
                      _InfoChip(
                        icon: Icons.confirmation_number_rounded,
                        label: 'Encintados',
                        value: '${ciclo.encintados.length}',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Proyección
                Builder(
                  builder: (_) {
                    final proy = ciclo.proyeccionCosecha(semanasParaCosecha);
                    if (proy == null) {
                      return const SizedBox.shrink();
                    }
                    final dias = proy.difference(DateTime.now()).inDays;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dias <= 0
                                  ? '⚠️ Cosecha pendiente (${dias.abs()} días de retraso)'
                                  : '📅 Proyección: ${_formatDate(proy)} ($dias días)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _showLegend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leyenda de Colores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _LegendItem(
                color: Colors.grey,
                label: 'Libre',
                description: 'Sin ciclo activo',
              ),
              _LegendItem(
                color: const Color(0xFF43A047),
                label: 'Crecimiento',
                description: 'Más de 3 semanas para cosecha',
              ),
              _LegendItem(
                color: const Color(0xFFFB8C00),
                label: 'Maduración',
                description: '1 a 3 semanas para cosecha',
              ),
              _LegendItem(
                color: const Color(0xFFE53935),
                label: 'Urgente',
                description: 'Cosecha esta semana o retrasada',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
