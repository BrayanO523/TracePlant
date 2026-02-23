import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import 'produccion_fincas_screen.dart';
import '../consultas/views/consultas_screen.dart';
import '../consultas/views/cosechas_pendientes_screen.dart';
import '../consultas/views/proyeccion_cosecha_screen.dart';
import '../../domain/entities/tipo_accion_produccion.dart';
import 'tareas/accion_produccion_screen.dart';

class ProduccionDashboardScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final bool readOnly;

  const ProduccionDashboardScreen({
    super.key,
    required this.productoraId,
    this.readOnly = false,
  });

  @override
  ConsumerState<ProduccionDashboardScreen> createState() =>
      _ProduccionDashboardScreenState();
}

class _ProduccionDashboardScreenState
    extends ConsumerState<ProduccionDashboardScreen> {
  Map<String, dynamic> _stats = {
    'ciclosActivos': 0,
    'lotesActivos': 0,
    'volumenCosecha': 0.0,
    'volumenEncintado': 0.0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(produccionRepositoryProvider);
    final result = await repo.getStatsProductora(widget.productoraId);
    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _loading = false);
        },
        (stats) {
          setState(() {
            _stats = {
              'productoraId': widget.productoraId,
              'ciclosActivos': stats.ciclosActivos,
              'lotesActivos': stats.lotesActivos,
              'volumenCosecha': stats.volumenCosecha,
              'volumenEncintado': stats.volumenEncintado,
            };
            _loading = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canViewConsultas =
        ref
            .watch(currentUserStreamProvider)
            .value
            ?.effectivePermissions
            .consultas
            .ver ??
        false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Producción'), centerTitle: true),
      body: Column(
        children: [
          // ── DASHBOARD SUPERIOR ──
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _StatsGrid(
                    stats: _stats,
                    loading: _loading,
                    canViewConsultas: canViewConsultas,
                  ),
                  const SizedBox(height: 20),
                  // Aquí podría ir gráficos o actividad reciente
                ],
              ),
            ),
          ),

          // ── BOTONES DE ACCIÓN (Task-Centric) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTaskBtn(
                          context,
                          'Siembra',
                          Icons.grass_rounded,
                          AppColors.success,
                          TipoAccionProduccion.siembra,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTaskBtn(
                          context,
                          'Encintado',
                          Icons.loyalty_rounded,
                          AppColors.warning,
                          TipoAccionProduccion.encintado,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTaskBtn(
                          context,
                          'Cosecha',
                          Icons.content_cut_rounded,
                          AppColors.error,
                          TipoAccionProduccion.cosecha,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón Administrativo Segundario
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProduccionFincasScreen(
                              productoraId: widget.productoraId,
                              readOnly: widget.readOnly,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded),
                      label: const Text(
                        'Explorador GIS de Fincas y Lotes Totales',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBtn(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    TipoAccionProduccion accion,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccionProduccionScreen(
                productoraId: widget.productoraId,
                accion: accion,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;
  final bool canViewConsultas;

  const _StatsGrid({
    required this.stats,
    required this.loading,
    required this.canViewConsultas,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 2 columnas
        final itemWidth = (width - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              width: itemWidth,
              icon: Icons.loop_rounded,
              color: AppColors.info,
              label: 'Ciclos Activos',
              value: stats['ciclosActivos'].toString(),
              onTap: canViewConsultas
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultasScreen(
                          productoraId: stats['productoraId'] ?? "",
                        ),
                      ),
                    )
                  : null,
            ),
            _StatCard(
              width: itemWidth,
              icon: Icons.grid_on_rounded,
              color: AppColors.secondary,
              label: 'Lotes Activos',
              value: stats['lotesActivos'].toString(),
              onTap: canViewConsultas
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultasScreen(
                          productoraId: stats['productoraId'] ?? "",
                        ),
                      ),
                    )
                  : null,
            ),
            _StatCard(
              width: itemWidth,
              icon: Icons.agriculture_rounded,
              color: AppColors.primary,
              label: 'Cosecha Total',
              value: '${stats['volumenCosecha'].toStringAsFixed(1)} un',
              onTap: canViewConsultas
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CosechasPendientesScreen(
                          productoraId: stats['productoraId'] ?? "",
                        ),
                      ),
                    )
                  : null,
            ),
            _StatCard(
              width: itemWidth,
              icon: Icons.bookmark_rounded,
              color: AppColors.accent,
              label: 'En Cinta',
              value: '${stats['volumenEncintado'].toStringAsFixed(1)} un',
              onTap: canViewConsultas
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProyeccionCosechaScreen(
                          productoraId: stats['productoraId'] ?? "",
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
