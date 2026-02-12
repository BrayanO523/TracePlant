import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/administracion_provider.dart';
import '../providers/admin_view_model.dart';
import 'forms/cinta_form_screen.dart';

class CintasScreen extends ConsumerWidget {
  const CintasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cintasAsync = ref.watch(cintasStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Colores de Cinta')),
      body: cintasAsync.when(
        data: (cintas) => ListView.separated(
          itemCount: cintas.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final cinta = cintas[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _hexToColor(cinta.colorHex),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLOR CINTA: ${cinta.color}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (cinta.descripcion.isNotEmpty)
                    Text(
                      cinta.descripcion,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CintaFormScreen(cinta: cinta),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, ref, cinta.id),
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
          MaterialPageRoute(builder: (_) => const CintaFormScreen()),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cinta'),
        content: const Text('¿Estás seguro de eliminar este color?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(adminViewModelProvider.notifier)
                  .deleteEntity('cintas', id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
