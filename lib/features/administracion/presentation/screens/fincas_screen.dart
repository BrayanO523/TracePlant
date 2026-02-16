import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/administracion_provider.dart';
import '../providers/admin_view_model.dart';
import 'finca_detail_screen.dart';
import 'forms/finca_form_screen.dart';
import '../widgets/admin_sliver_app_bar.dart';

class FincasScreen extends ConsumerWidget {
  const FincasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fincasAsync = ref.watch(fincasStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const AdminSliverAppBar(
            title: 'Fincas y Lotes',
            subtitle: 'Gestionar fincas y sus lotes de producción',
            icon: Icons.landscape_rounded,
          ),
          fincasAsync.when(
            data: (fincas) {
              if (fincas.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.landscape_outlined,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay fincas registradas',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toca + para agregar una finca',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final finca = fincas[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FincaDetailScreen(finca: finca),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.landscape_rounded,
                                    color: AppColors.tertiary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        finca.nombre,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.straighten_rounded,
                                            size: 14,
                                            color: AppColors.textHint,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Área: ${finca.areaTotal} m²',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.info,
                                        size: 20,
                                      ),
                                      tooltip: 'Editar finca',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FincaFormScreen(finca: finca),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      tooltip: 'Eliminar finca',
                                      onPressed: () => _confirmDelete(
                                        context,
                                        ref,
                                        finca.id,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: fincas.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
          // Espacio extra al final
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FincaFormScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Eliminar Finca'),
          ],
        ),
        content: const Text(
          '¿Eliminar Finca? Esto podría dejar lotes huérfanos si no se valida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref
                  .read(adminViewModelProvider.notifier)
                  .deleteEntity('fincas', id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
