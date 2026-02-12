import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import 'produccion_fincas_screen.dart';

class ProduccionDashboardScreen extends ConsumerStatefulWidget {
  final String productoraId;

  const ProduccionDashboardScreen({super.key, required this.productoraId});

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
          // Handle error silently or show snackbar
          setState(() => _loading = false);
        },
        (stats) {
          setState(() {
            _stats = {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                  _StatsGrid(stats: _stats, loading: _loading),
                  const SizedBox(height: 20),
                  // Aquí podría ir gráficos o actividad reciente
                ],
              ),
            ),
          ),

          // ── BOTÓN INFERIOR (Action Area) ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProduccionFincasScreen(
                          productoraId: widget.productoraId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.terrain_rounded, size: 28),
                  label: const Text(
                    'MIS FINCAS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;

  const _StatsGrid({required this.stats, required this.loading});

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
              color: Colors.blue,
              label: 'Ciclos Activos',
              value: stats['ciclosActivos'].toString(),
            ),
            _StatCard(
              width: itemWidth,
              icon: Icons.grid_on_rounded,
              color: Colors.orange,
              label: 'Lotes Activos',
              value: stats['lotesActivos'].toString(),
            ),
            _StatCard(
              width: itemWidth,
              icon: Icons.agriculture_rounded,
              color: Colors.green,
              label: 'Cosecha Total',
              value: '${stats['volumenCosecha'].toStringAsFixed(1)} un',
            ),
            _StatCard(
              width: itemWidth,
              icon: Icons.bookmark_rounded,
              color: Colors.purple,
              label: 'En Cinta',
              value: '${stats['volumenEncintado'].toStringAsFixed(1)} un',
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

  const _StatCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              color: color.withOpacity(0.1),
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
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
