import 'package:flutter/material.dart';
import '../../../empacadora/domain/entities/empacadora.dart';

class EmpacadoraSelectionDialog extends StatefulWidget {
  final List<Empacadora> empacadoras;
  final Map<String, int> cargaTrabajo;

  const EmpacadoraSelectionDialog({
    super.key,
    required this.empacadoras,
    required this.cargaTrabajo,
  });

  @override
  State<EmpacadoraSelectionDialog> createState() =>
      _EmpacadoraSelectionDialogState();
}

class _EmpacadoraSelectionDialogState extends State<EmpacadoraSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Empacadora> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _filteredList = widget.empacadoras;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = widget.empacadoras.where((e) {
        return e.name.toLowerCase().contains(query) ||
            (e.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar Empacadora',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar empacadora...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Flexible(
            child: SizedBox(
              width: double.maxFinite,
              height: 400, // Altura máxima
              child: _filteredList.isEmpty
                  ? const Center(child: Text('No se encontraron resultados'))
                  : ListView.builder(
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        final empacadora = _filteredList[index];
                        final count = widget.cargaTrabajo[empacadora.id] ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              empacadora.name[0].toUpperCase(),
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            empacadora.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${count} asignadas • ${empacadora.location ?? "Sin ubicación"}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context, empacadora);
                          },
                        );
                      },
                    ),
            ),
          ),

          // Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
