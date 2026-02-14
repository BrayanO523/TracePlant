import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_colors.dart';
import 'searchable_filter_sheet.dart';

class ConsultasFilterBar extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? variedadFilter;
  final String? loteFilter;
  final String? cintaFilter;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;
  final VoidCallback onClearTap;
  final Function(String?) onVariedadChanged;
  final Function(String?) onLoteChanged;

  final List<String> variedadesDisponibles;
  final List<String> lotesDisponibles;

  const ConsultasFilterBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.variedadFilter,
    required this.loteFilter,
    required this.cintaFilter,
    required this.onStartDateTap,
    required this.onEndDateTap,
    required this.onClearTap,
    required this.onVariedadChanged,
    required this.onLoteChanged,
    this.variedadesDisponibles = const [],
    this.lotesDisponibles = const [],
  });

  bool get hasFilters =>
      startDate != null ||
      endDate != null ||
      variedadFilter != null ||
      loteFilter != null ||
      cintaFilter != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fondo transparente como se solicitó
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Botón Desde
            _DateFilterButton(
              label: 'Desde',
              date: startDate,
              onTap: onStartDateTap,
            ),
            const SizedBox(width: 8),

            // Botón Hasta
            _DateFilterButton(
              label: 'Hasta',
              date: endDate,
              onTap: onEndDateTap,
            ),
            const SizedBox(width: 16), // Separador visual entre fechas y otros
            // Filtro Variedad (estilo Dropdown flotante)
            // Filtro Variedad (estilo Dropdown flotante con búsqueda)
            _FilterSheetButton(
              label: 'Variedad',
              value: variedadFilter,
              icon: Icons.eco_rounded,
              options: variedadesDisponibles,
              onSelected: onVariedadChanged,
            ),
            const SizedBox(width: 8),

            // Filtro Lote (estilo Dropdown flotante)
            // Filtro Lote (estilo Dropdown flotante con búsqueda)
            _FilterSheetButton(
              label: 'Lote',
              value: loteFilter,
              icon: Icons.grid_view_rounded,
              options: lotesDisponibles,
              onSelected: onLoteChanged,
            ),

            if (hasFilters) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onClearTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateFilterButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = date != null;
    final text = isActive ? '${date!.day}/${date!.month}/${date!.year}' : label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey.shade300,
            ),
            boxShadow: [
              if (!isActive)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheetButton extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final List<String> options;
  final Function(String?) onSelected;

  const _FilterSheetButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                // Return our custom sheet inside
                return SearchableFilterSheet(
                  title: label,
                  options: options,
                  selectedValue: value,
                  onSelected: onSelected,
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey.shade300,
            ),
            boxShadow: [
              if (!isActive)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  value ?? label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: isActive ? Colors.white : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
