import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/administracion_provider.dart';
import '../providers/admin_view_model.dart';

import 'finca_detail_screen.dart';
import 'forms/finca_form_screen.dart';

class FincasScreen extends ConsumerWidget {
  const FincasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fincasAsync = ref.watch(fincasStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fincas')),
      body: fincasAsync.when(
        data: (fincas) => ListView.separated(
          itemCount: fincas.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final finca = fincas[index];
            return ListTile(
              leading: const Icon(Icons.landscape, size: 40),
              title: Text(finca.nombre),
              subtitle: Text('Área Total: ${finca.areaTotal} m²'),
              isThreeLine: true,
              // onTap navigates to details (Lotes)
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FincaDetailScreen(finca: finca),
                ),
              ),
              // onLongPress to edit the Finca itself
              onLongPress: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FincaFormScreen(finca: finca),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FincaFormScreen(finca: finca),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, finca.id),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FincaFormScreen()),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Eliminar Finca? Esto podría dejar lotes huérfanos si no se valida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(adminViewModelProvider.notifier)
                  .deleteEntity('fincas', id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
