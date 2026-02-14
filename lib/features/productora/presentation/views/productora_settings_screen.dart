import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../data/models/productora_model.dart';

/// Pantalla de ajustes de la empresa productora.
/// Muestra info general (read-only) y permite configurar
/// las semanas para proyección de cosecha después de encintado.
class ProductoraSettingsScreen extends ConsumerStatefulWidget {
  final String productoraId;
  const ProductoraSettingsScreen({super.key, required this.productoraId});

  @override
  ConsumerState<ProductoraSettingsScreen> createState() =>
      _ProductoraSettingsScreenState();
}

class _ProductoraSettingsScreenState
    extends ConsumerState<ProductoraSettingsScreen> {
  final _semanasController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  ProductoraModel? _productora;

  @override
  void initState() {
    super.initState();
    _loadProductora();
  }

  @override
  void dispose() {
    _semanasController.dispose();
    super.dispose();
  }

  Future<void> _loadProductora() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.productoras)
          .doc(widget.productoraId)
          .get();

      if (doc.exists && mounted) {
        final prod = ProductoraModel.fromFirestore(doc);
        setState(() {
          _productora = prod;
          _semanasController.text = prod.semanasParaCosecha.toString();
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _guardarSemanas() async {
    final semanas = int.tryParse(_semanasController.text.trim());
    if (semanas == null || semanas < 1 || semanas > 104) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un valor entre 1 y 104 semanas'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.productoras)
          .doc(widget.productoraId)
          .update({
            'semanas_para_cosecha': semanas,
            'fecha_actualizacion': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Proyección: $semanas sem (${semanas * 7} días)'),
                ),
              ],
            ),
            backgroundColor: AppColors.estadoCosechado,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        title: const Text('Ajustes de Empresa'),
        centerTitle: true,
        backgroundColor: AppColors.surfaceVariant,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _productora == null
          ? const Center(child: Text('No se encontró la empresa'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── INFO EMPRESA (READ-ONLY) ──
                  _buildSectionTitle('Información General'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _InfoRow(
                      icon: Icons.business_rounded,
                      label: 'Nombre',
                      value: _productora!.name,
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      value: _productora!.location ?? 'Sin definir',
                    ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'RTN',
                      value: _productora!.rnt ?? 'Sin definir',
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: _productora!.contactPhone ?? 'Sin definir',
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: _productora!.contactEmail ?? 'Sin definir',
                    ),
                    _InfoRow(
                      icon: Icons.qr_code_rounded,
                      label: 'Código',
                      value: _productora!.code ?? 'Sin definir',
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── CONFIGURACIÓN PROYECCIÓN ──
                  _buildSectionTitle('Proyección de Cosecha'),
                  const SizedBox(height: 8),
                  Text(
                    'Define cuántas semanas después del encintado '
                    'se estima la cosecha. Este valor se usa para '
                    'calcular las fechas proyectadas en Consultas.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semanas para Cosecha',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Builder(
                                    builder: (context) {
                                      final semanas =
                                          int.tryParse(
                                            _semanasController.text.trim(),
                                          ) ??
                                          30;
                                      return Text(
                                        '= ${semanas * 7} días después del encintado',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _semanasController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Semanas',
                            hintText: 'Ej: 30',
                            suffixText: 'semanas',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.timer_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _guardarSemanas,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(_saving ? 'Guardando...' : 'Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(row.icon, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}
