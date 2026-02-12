import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/administracion_provider.dart';
import '../providers/admin_view_model.dart';
import 'forms/variedad_form_screen.dart';

class VariedadesScreen extends ConsumerWidget {
  const VariedadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variedadesAsync = ref.watch(variedadesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Variedades')),
      body: variedadesAsync.when(
        data: (variedades) => ListView.separated(
          itemCount: variedades.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final variedad = variedades[index];
            return ListTile(
              title: Text(variedad.nombre),
              subtitle: Text(variedad.descripcion),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VariedadFormScreen(variedad: variedad),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => ref
                    .read(adminViewModelProvider.notifier)
                    .deleteEntity('variedades', variedad.id),
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
          MaterialPageRoute(builder: (_) => const VariedadFormScreen()),
        ),
      ),
    );
  }
}
