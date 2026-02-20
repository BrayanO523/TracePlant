import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/di/providers.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/constants/firestore_paths.dart';
import '../viewmodels/consultas_notifier.dart';
import '../widgets/export_button.dart';
import '../logic/pdf_report_generator.dart';
import '../../../../../features/administracion/domain/entities/cinta.dart';

import 'inventario_cosechado_screen.dart';
import 'proyeccion_cosecha_screen.dart';
import 'consultas_detalle_views.dart';

class ConsultasScreen extends ConsumerStatefulWidget {
  final String productoraId;

  const ConsultasScreen({super.key, required this.productoraId});

  @override
  ConsumerState<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends ConsumerState<ConsultasScreen> {
  Future<void> _exportarReporte() async {
    final state = ref.read(consultasProvider(widget.productoraId));
    final notifier = ref.read(consultasProvider(widget.productoraId).notifier);

    String nombreProductora = "Productora";
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.productoras)
          .doc(widget.productoraId)
          .get();
      if (doc.exists) {
        nombreProductora = doc.data()?['nombre_empresa'] ?? "Productora";
      }
    } catch (_) {}

    List<Cinta> cintas = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestorePaths.cintas)
          .where('productoraId', isEqualTo: widget.productoraId)
          .get();

      cintas = snapshot.docs
          .map(
            (d) => Cinta(
              id: d.id,
              color: d.data()['color'] ?? '',
              descripcion: d.data()['descripcion'] ?? '',
              colorHex: d.data()['colorHex'] ?? '#000000',
              productoraId: d.data()['productoraId'] ?? widget.productoraId,
            ),
          )
          .toList();
    } catch (_) {}

    await PdfReportGenerator.generateAndPrint(
      state,
      notifier.getStatsPorColor(),
      notifier.getProduccionSemanal(),
      nombreProductora,
      cintas,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Asegurar carga de datos
    ref.watch(consultasProvider(widget.productoraId));

    // Obtener permisos del usuario actual
    final userAsync = ref.watch(currentUserStreamProvider);
    final perms = userAsync.value?.effectivePermissions;
    final canExport = perms?.consultas.crear ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Consultas y Reportes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (canExport) ...[
            ExportButton(onTap: _exportarReporte, isLoading: false),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ref
            .read(consultasProvider(widget.productoraId).notifier)
            .refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccione una categoría',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Grid de opciones principales
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _MenuOptionCard(
                    title: 'Por Variedad',
                    icon: Icons.eco_rounded,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultaVariedadView(
                          productoraId: widget.productoraId,
                        ),
                      ),
                    ),
                  ),
                  _MenuOptionCard(
                    title: 'Por Cinta',
                    icon: Icons.palette_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultaCintaView(
                          productoraId: widget.productoraId,
                        ),
                      ),
                    ),
                  ),
                  _MenuOptionCard(
                    title: 'Por Finca / Lote',
                    icon: Icons.terrain_rounded,
                    color: Colors.brown,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultaFincaView(
                          productoraId: widget.productoraId,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Herramientas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              _ToolOptionTile(
                title: 'Proyección de Cosecha',
                subtitle: 'Ver estimaciones de cosecha futura',
                icon: Icons.calendar_month_rounded,
                color: AppColors.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProyeccionCosechaScreen(
                      productoraId: widget.productoraId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ToolOptionTile(
                title: 'Inventario Cosechado',
                subtitle: 'Lotes cosechados pendientes de entrega',
                icon: Icons.inventory_2_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventarioCosechadoScreen(
                      productoraId: widget.productoraId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuOptionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
