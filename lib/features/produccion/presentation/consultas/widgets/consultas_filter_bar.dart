import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_colors.dart';

class ConsultasFilterBar extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? variedadFilter;
  final String? loteFilter;
  final String? cintaFilter;
  final VoidCallback onDateTap;
  final VoidCallback onClearTap;
  final Function(String?) onVariedadChanged;
  final Function(String?) onLoteChanged;

  // Opcional: Listas de opciones para los dropdowns
  final List<String> variedadesDisponibles;
  final List<String> lotesDisponibles;

  const ConsultasFilterBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.variedadFilter,
    required this.loteFilter,
    required this.cintaFilter,
    required this.onDateTap,
    required this.onClearTap,
    required this.onVariedadChanged,
    required this.onLoteChanged,
    this.variedadesDisponibles = const [],
    this.lotesDisponibles = const [],
  });

  bool get hasFilters =>
      startDate != null ||
      variedadFilter != null ||
      loteFilter != null ||
      cintaFilter != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtro de Fecha
            _FilterChip(
              label: (startDate != null && endDate != null)
                  ? '${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}'
                  : 'Fecha',
              icon: Icons.calendar_today_rounded,
              isActive: startDate != null,
              onTap: onDateTap,
            ),
            const SizedBox(width: 8),

            // Filtro Variedad (Simulado como botón por ahora, idealmente un sheet o menu)
            // Para simplificar UX, usaremos un PopupMenuButton invisible sobre el chip o similar.
            // Aquí un chip simple que abre un selector externo sería mejor,
            // pero si queremos 'inline', PopupMenuButton es útil.
            PopupMenuButton<String>(
              onSelected: onVariedadChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todas las variedades'),
                ),
                ...variedadesDisponibles.map(
                  (v) => PopupMenuItem(value: v, child: Text(v)),
                ),
              ],
              child: _FilterChip(
                label: variedadFilter ?? 'Variedad',
                icon: Icons.eco_rounded,
                isActive: variedadFilter != null,
                onTap: null, // El tap lo maneja el PopupMenuButton
              ),
            ),
            const SizedBox(width: 8),

            // Filtro Lote
            PopupMenuButton<String>(
              onSelected: onLoteChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todos los lotes'),
                ),
                ...lotesDisponibles.map(
                  (l) => PopupMenuItem(value: l, child: Text(l)),
                ),
              ],
              child: _FilterChip(
                label: loteFilter ?? 'Lote',
                icon: Icons.grid_view_rounded,
                isActive: loteFilter != null,
                onTap: null,
              ),
            ),

            if (hasFilters) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onClearTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey.shade300,
            ),
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
              Text(
                label,
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
