import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../app/theme/app_colors.dart';

class SelectorFilterModal extends StatefulWidget {
  final List<String> variedades;
  final List<String> cintas; // Optional, can be empty
  final List<String> fincas;

  // Current values
  final bool sortAscending;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? variedad;
  final String? cinta;
  final String? finca;

  final Function({
    required bool sortAscending,
    DateTime? startDate,
    DateTime? endDate,
    String? variedad,
    String? cinta,
    String? finca,
  })
  onApply;

  const SelectorFilterModal({
    super.key,
    required this.variedades,
    required this.cintas,
    required this.fincas,
    required this.sortAscending,
    this.startDate,
    this.endDate,
    this.variedad,
    this.cinta,
    this.finca,
    required this.onApply,
  });

  @override
  State<SelectorFilterModal> createState() => _SelectorFilterModalState();
}

class _SelectorFilterModalState extends State<SelectorFilterModal> {
  late bool _sortAscending;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _variedad;
  String? _cinta;
  String? _finca;

  @override
  void initState() {
    super.initState();
    _sortAscending = widget.sortAscending;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _variedad = widget.variedad;
    _cinta = widget.cinta;
    _finca = widget.finca;
  }

  void _apply() {
    widget.onApply(
      sortAscending: _sortAscending,
      startDate: _startDate,
      endDate: _endDate,
      variedad: _variedad,
      cinta: _cinta,
      finca: _finca,
    );
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _sortAscending = false; // Default desc (más reciente primero)
      _startDate = null;
      _endDate = null;
      _variedad = null;
      _cinta = null;
      _finca = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.accent)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Configurar Vista',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Ordenamiento
                    _SectionTitle('ORDENAR POR FECHA'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _SortOption(
                          label: 'Más Recientes',
                          isSelected: !_sortAscending,
                          onTap: () => setState(() => _sortAscending = false),
                        ),
                        const SizedBox(width: 12),
                        _SortOption(
                          label: 'Más Antiguos',
                          isSelected: _sortAscending,
                          onTap: () => setState(() => _sortAscending = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fechas
                    _SectionTitle('RANGO DE FECHAS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateBox(
                            label: 'Desde',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateBox(
                            label: 'Hasta',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filtros
                    _SectionTitle('FILTRAR POR'),
                    const SizedBox(height: 16),

                    if (widget.fincas.isNotEmpty) ...[
                      _DropdownFilter<String>(
                        label: 'Finca',
                        items: widget.fincas,
                        selectedItem: _finca,
                        onChanged: (v) => setState(() => _finca = v),
                        itemAsString: (v) => v,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (widget.variedades.isNotEmpty) ...[
                      _DropdownFilter<String>(
                        label: 'Variedad',
                        items: widget.variedades,
                        selectedItem: _variedad,
                        onChanged: (v) => setState(() => _variedad = v),
                        itemAsString: (v) => v,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (widget.cintas.isNotEmpty) ...[
                      _DropdownFilter<String>(
                        label: 'Cinta',
                        items: widget.cintas,
                        selectedItem: _cinta,
                        onChanged: (v) => setState(() => _cinta = v),
                        itemAsString: (v) => v,
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Helpers copiados/adaptados para ser self-contained ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasDate
                  ? DateFormat('d MMM yyyy', 'es').format(date!)
                  : 'Seleccionar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: hasDate ? AppColors.textPrimary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemAsString;

  const _DropdownFilter({
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.itemAsString,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        DropdownSearch<T>(
          items: (filter, loadProps) => items,
          selectedItem: selectedItem,
          onChanged: onChanged,
          itemAsString: itemAsString,
          compareFn: (i, s) => i == s,
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
            fit: FlexFit.loose,
            constraints: const BoxConstraints(maxHeight: 300),
          ),
        ),
      ],
    );
  }
}
