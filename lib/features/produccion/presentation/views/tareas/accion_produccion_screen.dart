import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../domain/entities/tipo_accion_produccion.dart';
import '../../viewmodels/accion_lotes_provider.dart';
import '../../../domain/entities/produccion_enums.dart';
import '../ciclo_form_screen.dart'; // importando ciclo_form_screen

class AccionProduccionScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final TipoAccionProduccion accion;

  const AccionProduccionScreen({
    super.key,
    required this.productoraId,
    required this.accion,
  });

  @override
  ConsumerState<AccionProduccionScreen> createState() =>
      _AccionProduccionScreenState();
}

class _AccionProduccionScreenState
    extends ConsumerState<AccionProduccionScreen> {
  String? selectedFincaId;

  @override
  Widget build(BuildContext context) {
    final params = AccionProduccionParams(widget.productoraId, widget.accion);
    final dataState = ref.watch(accionFincasProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.accion.titulo), centerTitle: true),
      body: dataState.when(
        data: (fincas) => _buildBody(fincas),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ocurrió un error cargando los datos:\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildBody(List<FincaConLotesAccion> fincas) {
    if (fincas.isEmpty) {
      return const Center(child: Text('No hay fincas registradas.'));
    }

    // Auto-select initially
    if (selectedFincaId == null) {
      final primeraConLotes = fincas.where((f) => f.hasLotes).firstOrNull;
      if (primeraConLotes != null) {
        // En un microtask para no interferir con el build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              selectedFincaId = primeraConLotes.finca.id;
            });
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              selectedFincaId = fincas.first.finca.id;
            });
          }
        });
      }
    }

    final activeFincaAccion = fincas.firstWhere(
      (f) => f.finca.id == selectedFincaId,
      orElse: () => fincas.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── PESTAÑAS DE FINCA INTEGRAL (Filter Chips) ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.white,
          child: const Text(
            'Filtra por Finca:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: fincas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final fa = fincas[index];
              final isSelected = fa.finca.id == selectedFincaId;
              // Si no tiene lotes para la tarea, lo mostramos un poco más inactivo
              final disableStyle = !fa.hasLotes && !isSelected;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fa.finca.nombre,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (disableStyle
                                  ? Colors.grey.shade500
                                  : Colors.black87),
                      ),
                    ),
                    if (fa.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white24 : AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          fa.count.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: _getColorBadge(widget.accion),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide.none,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedFincaId = fa.finca.id;
                    });
                  }
                },
              );
            },
          ),
        ),

        // ── CABECERA EXPLÍCITA DE FINCA SELECCIONADA ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Lotes Disponibles en ${activeFincaAccion.finca.nombre}:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── LISTA INFERIOR DE LOTES DISPONIBLES ──
        Expanded(child: _buildLotesList(activeFincaAccion)),
      ],
    );
  }

  Color _getColorBadge(TipoAccionProduccion accion) {
    switch (accion) {
      case TipoAccionProduccion.siembra:
        return AppColors.success;
      case TipoAccionProduccion.encintado:
        return AppColors.warning;
      case TipoAccionProduccion.cosecha:
        return AppColors.error;
    }
  }

  Widget _buildLotesList(FincaConLotesAccion fa) {
    if (!fa.hasLotes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay lotes disponibles para esta tarea aquí.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fa.lotesDisponibles.length,
      itemBuilder: (context, index) {
        final lote = fa.lotesDisponibles[index];
        final ciclo = fa.ciclosPorLote[lote.id];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final TipoEvento nextStep;
              switch (widget.accion) {
                case TipoAccionProduccion.siembra:
                  nextStep = TipoEvento.siembra;
                  break;
                case TipoAccionProduccion.encintado:
                  nextStep = TipoEvento.encintado;
                  break;
                case TipoAccionProduccion.cosecha:
                  nextStep = TipoEvento.cosecha;
                  break;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CicloFormScreen(
                    productoraId: widget.productoraId,
                    idLote: lote.id,
                    nombreLote: lote.nombre,
                    siguientePaso: nextStep,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getColorBadge(
                        widget.accion,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconBadge(widget.accion),
                      color: _getColorBadge(widget.accion),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lote.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Finca: ${fa.finca.nombre}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (ciclo != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Activo: \${ciclo.variedad}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconBadge(TipoAccionProduccion accion) {
    switch (accion) {
      case TipoAccionProduccion.siembra:
        return Icons.grass_rounded;
      case TipoAccionProduccion.encintado:
        return Icons.loyalty_rounded;
      case TipoAccionProduccion.cosecha:
        return Icons.content_cut_rounded;
    }
  }
}
