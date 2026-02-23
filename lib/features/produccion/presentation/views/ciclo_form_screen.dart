import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../viewmodels/produccion_notifier.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';

import 'package:intl/intl.dart';
import '../../../administracion/domain/entities/cinta.dart';
import '../widgets/ciclo_timeline.dart';
import '../../../administracion/presentation/screens/cintas_screen.dart';

/// Formulario premium para registrar eventos del ciclo (Siembra, Encintado, Cosecha).
/// Re-diseñado con estilo "Card-based" profesional.
class CicloFormScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final String idLote;
  final String nombreLote;
  final TipoEvento? siguientePaso;
  final double? areaLote;
  final String? variedadLote;

  const CicloFormScreen({
    super.key,
    required this.productoraId,
    required this.idLote,
    required this.nombreLote,
    this.siguientePaso,
    this.areaLote,
    this.variedadLote,
  });

  @override
  ConsumerState<CicloFormScreen> createState() => _CicloFormScreenState();
}

class _CicloFormScreenState extends ConsumerState<CicloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _areaController;
  late final TextEditingController _variedadController;

  // Encintado
  Cinta? _cintaSeleccionada;
  final _cantidadEncintadoController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();
  String? _encintadoSeleccionadoId;
  bool _cosechaPreFilled = false; // Para pre-llenar solo una vez

  // Estado local para mostrar formulario de agregar encintado
  bool _showEncintadoForm = false;

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(
      text: widget.areaLote?.toString() ?? '',
    );
    _variedadController = TextEditingController(
      text: widget.variedadLote ?? '',
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    _variedadController.dispose();
    _cantidadEncintadoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final produccionState = ref.watch(
      produccionNotifierProvider(widget.productoraId),
    );

    // Escuchar mensajes de éxito/error
    ref.listen<ProduccionState>(
      produccionNotifierProvider(widget.productoraId),
      (prev, next) {
        if (next.successMessage != null &&
            prev?.successMessage != next.successMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.estadoCosechado,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref
              .read(produccionNotifierProvider(widget.productoraId).notifier)
              .clearMessages();

          if (widget.siguientePaso == TipoEvento.encintado) {
            setState(() {
              _showEncintadoForm = false;
              _cantidadEncintadoController.clear();
              _cintaSeleccionada = null;
            });
          } else {
            Navigator.pop(context);
          }
        }
        if (next.error != null && prev?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.estadoCancelado,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref
              .read(produccionNotifierProvider(widget.productoraId).notifier)
              .clearMessages();
        }
      },
    );

    final paso = widget.siguientePaso;

    // Buscar ciclo activo
    final cicloActivo = produccionState.ciclos
        .where(
          (c) =>
              c.idLote == widget.idLote &&
              (c.estado == EstadoCiclo.sembrado ||
                  c.estado == EstadoCiclo.encintado),
        )
        .toList();
    final ciclo = cicloActivo.isNotEmpty ? cicloActivo.first : null;

    // Pre-llenar cantidad cosechada con el total del último encintado (solo una vez)
    if (!_cosechaPreFilled &&
        paso == TipoEvento.cosecha &&
        ciclo != null &&
        ciclo.totalEncintado > 0) {
      _cosechaPreFilled = true;
      _cantidadEncintadoController.text = ciclo.totalEncintado.toStringAsFixed(
        2,
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Surface gris suave
        appBar: AppBar(
          title: Text(
            _tituloFormulario(paso),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.edit_document), text: 'Formulario'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Formulario
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Lote (Moderno)
                    _buildLoteHeader(theme, ciclo),
                    const SizedBox(height: 20),

                    if (paso == null)
                      _buildCompletedMessage(theme)
                    else ...[
                      // Fecha Evento (Card separado para resaltar)
                      _buildDatePicker(theme),
                      const SizedBox(height: 20),

                      // Campos dinámicos en Cards
                      ..._buildDynamicFields(
                        paso,
                        ciclo,
                        theme,
                        produccionState.isLoading,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Tab 2: Historial
            ciclo != null
                ? Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: CicloTimeline(ciclo: ciclo),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay historial para este lote aún',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
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

  // ═══════════════════════════════════════════════════════
  //  MODERN HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildLoteHeader(ThemeData theme, CicloProduccion? ciclo) {
    String diasTexto = '';
    if (ciclo != null) {
      diasTexto = 'Siembra hace ${_tiempoTranscurrido(ciclo.fechaSiembra)}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grass_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombreLote,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ciclo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${ciclo.variedad} • ${ciclo.area.toStringAsFixed(1)} mz',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        diasTexto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.areaLote} mz',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  MODERN DATE PICKER
  // ═══════════════════════════════════════════════════════
  Widget _buildDatePicker(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _fechaSeleccionada,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) setState(() => _fechaSeleccionada = date);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha del Evento',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _formatDateDisplay(_fechaSeleccionada),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.edit_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  DYNAMIC FIELDS
  // ═══════════════════════════════════════════════════════
  List<Widget> _buildDynamicFields(
    TipoEvento paso,
    CicloProduccion? ciclo,
    ThemeData theme,
    bool isLoading,
  ) {
    final perms = ref
        .watch(currentUserStreamProvider)
        .value
        ?.effectivePermissions;
    final canCrearEncintado = perms?.encintado.crear ?? false;
    final canCrearCosecha = perms?.cosecha.crear ?? false;

    switch (paso) {
      case TipoEvento.siembra:
        return [
          _buildCardSection(
            title: 'Datos de Siembra',
            icon: Icons.eco_rounded,
            child: _buildSiembraFields(),
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(paso, ciclo, isLoading),
        ];

      case TipoEvento.encintado:
        return [
          // _buildEncintadoHistory(theme, ciclo), // Removed as it's now in a separate tab
          // const SizedBox(height: 20), // Removed corresponding SizedBox
          if (canCrearEncintado &&
              (_showEncintadoForm || (ciclo?.encintados.isEmpty ?? true)))
            Column(
              children: [
                _buildCardSection(
                  title: 'Nuevo Encintado',
                  icon: Icons.add_circle_outline_rounded,
                  child: _buildEncintadoFields(theme, ciclo),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if ((ciclo?.encintados.isNotEmpty ?? false))
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _showEncintadoForm = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    if ((ciclo?.encintados.isNotEmpty ?? false))
                      const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildSubmitButton(paso, ciclo, isLoading),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                if (canCrearEncintado) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showEncintadoForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Nuevo Encintado'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (canCrearCosecha && (ciclo?.encintados.isNotEmpty ?? false))
                  Builder(
                    builder: (context) {
                      bool hasAvailable = true;
                      if (ciclo?.esCultivoContinuo == true) {
                        hasAvailable = ciclo!.encintados.any(
                          (e) => e.disponible > 0,
                        );
                      }
                      if (!hasAvailable) return const SizedBox.shrink();
                      return _buildActionToCosecha(theme, ciclo);
                    },
                  ),
              ],
            ),
        ];

      case TipoEvento.cosecha:
        return [
          _buildCardSection(
            title: 'Registro de Cosecha',
            icon: Icons.agriculture_rounded,
            child: _buildCosechaFields(theme, ciclo),
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(paso, ciclo, isLoading),
        ];

      case TipoEvento.entrega:
        return [];
    }
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSiembraFields() {
    final variedadesAsync = ref.watch(
      variedadesStreamProviderFamily(widget.productoraId),
    );
    return Column(
      children: [
        TextFormField(
          controller: _areaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Permitir edición siempre, incluso si viene el área del lote
          readOnly: false,
          enabled: true,
          decoration: InputDecoration(
            labelText: 'Área a Sembrar',
            hintText: 'Ej: 2.5',
            suffixText: 'mz',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: false,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingrese el área';
            final n = double.tryParse(v);
            if (n == null || n <= 0) return 'Área inválida';

            // Validar que no sobrepase el área del lote
            if (widget.areaLote != null && n > widget.areaLote!) {
              return 'Máximo ${widget.areaLote} mz';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        variedadesAsync.when(
          data: (variedades) {
            final items = variedades.map((v) => v.nombre).toSet().toList();
            final currentValue = items.contains(_variedadController.text)
                ? _variedadController.text
                : null;
            return DropdownButtonFormField<String>(
              initialValue: currentValue,
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _variedadController.text = val);
              },
              decoration: InputDecoration(
                labelText: 'Variedad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Seleccione la variedad' : null,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text(
            'Error cargando variedades',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildEncintadoFields(ThemeData theme, CicloProduccion? ciclo) {
    final cintasAsync = ref.watch(
      cintasStreamProviderFamily(widget.productoraId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Color de Cinta',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            // Solo mostrar si el usuario puede gestionar cintas
            if (ref
                    .watch(currentUserStreamProvider)
                    .value
                    ?.effectivePermissions
                    .cintas
                    .crear ??
                false)
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CintasScreen()),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Gestionar Cintas'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        cintasAsync.when(
          data: (cintas) {
            if (cintas.isEmpty) {
              return const Text('No hay colores configurados');
            }

            Widget autoSuggestionWidget = const SizedBox.shrink();

            if (ciclo?.esCultivoContinuo == true) {
              final dayOfYear = int.parse(
                DateFormat('D').format(_fechaSeleccionada),
              );
              final weekOfYear =
                  ((dayOfYear - _fechaSeleccionada.weekday + 10) / 7).floor();
              final colorIndex = (weekOfYear - 1) % cintas.length;
              final finalIndex = colorIndex < 0 ? 0 : colorIndex;
              final cintaAsignada = cintas[finalIndex];

              if (_cintaSeleccionada == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _cintaSeleccionada == null) {
                    setState(() => _cintaSeleccionada = cintaAsignada);
                  }
                });
              }

              autoSuggestionWidget = Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sugerido (Semana $weekOfYear): ${cintaAsignada.color}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                autoSuggestionWidget,
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cintas.map((cinta) {
                    final isSelected = _cintaSeleccionada?.id == cinta.id;
                    return GestureDetector(
                      onTap: () => setState(() => _cintaSeleccionada = cinta),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _parseColor(cinta.colorHex),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cinta.color,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },

          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error'),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cantidadEncintadoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cantidad (Unidades)',
            prefixIcon: const Icon(Icons.numbers_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) =>
              (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Cantidad inválida' : null,
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    if (hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildActionToCosecha(ThemeData theme, CicloProduccion? ciclo) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CicloFormScreen(
                productoraId: widget.productoraId,
                idLote: widget.idLote,
                nombreLote: widget.nombreLote,
                areaLote: widget.areaLote,
                variedadLote: widget.variedadLote,
                siguientePaso: TipoEvento.cosecha,
              ),
            ),
          );
        },
        icon: const Icon(Icons.agriculture_rounded),
        label: const Text('Finalizar Ciclo / Cosechar'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.estadoCosechado,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildCosechaFields(ThemeData theme, CicloProduccion? ciclo) {
    if (ciclo == null) return const SizedBox.shrink();
    final totalEncintado = ciclo.totalEncintado;

    if (ciclo.esCultivoContinuo) {
      final opcionesDisponibles = ciclo.encintados
          .where((e) => e.disponible > 0)
          .toList();
      if (opcionesDisponibles.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'No hay disponibilidad para cosechar en ninguna cohorte.',
            style: TextStyle(color: Colors.orange),
          ),
        );
      }

      final currentValue =
          opcionesDisponibles.any((e) => e.id == _encintadoSeleccionadoId)
          ? _encintadoSeleccionadoId
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cohorte a Cosechar (Cinta)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentValue,
            hint: const Text('Seleccione cohorte de cinta'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            isExpanded: true,
            items: opcionesDisponibles.map((e) {
              return DropdownMenuItem(
                value: e.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(e.cintaColorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${e.cintaNombre} - Disp: ${e.disponible.toStringAsFixed(0)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _encintadoSeleccionadoId = val;
                if (val != null) {
                  final match = opcionesDisponibles.firstWhere(
                    (e) => e.id == val,
                  );
                  _cantidadEncintadoController.text = match.disponible
                      .toStringAsFixed(0);
                }
              });
            },
            validator: (v) => v == null ? 'Requerido' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _cantidadEncintadoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cantidad Cosechada',
              suffixText: 'uds',
              prefixIcon: const Icon(Icons.agriculture),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) {
              final parsed = double.tryParse(v ?? '') ?? 0;
              if (parsed <= 0) return 'Cantidad inválida';
              if (_encintadoSeleccionadoId != null) {
                final limit = opcionesDisponibles
                    .firstWhere((e) => e.id == _encintadoSeleccionadoId)
                    .disponible;
                if (parsed > limit) return 'Excede el disponible ($limit)';
              }
              return null;
            },
          ),
        ],
      );
    }

    // Lógica original para Maíz (Global)
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Total Encintado: ${totalEncintado.toStringAsFixed(2)} uds\nRegistre lo que realmente se cosechó.',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cantidadEncintadoController, // Reused controller
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cantidad Cosechada',
            suffixText: 'uds',
            prefixIcon: const Icon(Icons.agriculture),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) =>
              (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Cantidad inválida' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    TipoEvento paso,
    CicloProduccion? ciclo,
    bool isLoading,
  ) {
    final (label, icon, color) = switch (paso) {
      TipoEvento.siembra => (
        'Registrar Siembra',
        Icons.grass_rounded,
        AppColors.estadoSembrado,
      ),
      TipoEvento.encintado => (
        'Guardar Encintado',
        Icons.save_rounded,
        AppColors.estadoEncintado,
      ),
      TipoEvento.cosecha => (
        'Registrar Cosecha',
        Icons.agriculture_rounded,
        AppColors.estadoCosechado,
      ),
      TipoEvento.entrega => (
        'Registrar Entrega',
        Icons.local_shipping,
        AppColors.estadoEntregado,
      ),
    };

    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: isLoading ? null : () => _submit(paso, ciclo),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedMessage(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin ciclos activos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Este lote está libre para siembra.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  LOGIC
  // ─────────────────────────────────────────────────────────

  Future<void> _submit(TipoEvento paso, CicloProduccion? ciclo) async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateStreamProvider);
    final uidUsuario = authState.asData?.value?.uid ?? 'unknown';
    final notifier = ref.read(
      produccionNotifierProvider(widget.productoraId).notifier,
    );

    switch (paso) {
      case TipoEvento.siembra:
        await notifier.registrarSiembra(
          idLote: widget.idLote,
          nombreLote: widget.nombreLote,
          area: double.parse(_areaController.text),
          variedad: _variedadController.text.trim(),
          uidUsuario: uidUsuario,
        );
      case TipoEvento.encintado:
        if (ciclo == null) return;
        if (_cintaSeleccionada == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seleccione un color de cinta'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await notifier.registrarEncintado(
          idCiclo: ciclo.id,
          cintaId: _cintaSeleccionada!.id,
          cintaNombre: _cintaSeleccionada!.color,
          cintaColorHex: _cintaSeleccionada!.colorHex,
          cantidad: double.parse(_cantidadEncintadoController.text),
          fecha: _fechaSeleccionada,
          uidUsuario: uidUsuario,
        );
      case TipoEvento.cosecha:
        if (ciclo == null) return;
        if (ciclo.esCultivoContinuo && _encintadoSeleccionadoId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debe seleccionar una cinta para cosechar'),
            ),
          );
          return;
        }
        await notifier.registrarCosecha(
          idCiclo: ciclo.id,
          idEncintado: ciclo.esCultivoContinuo
              ? _encintadoSeleccionadoId
              : null,
          cantidad: double.parse(_cantidadEncintadoController.text),
          uidUsuario: uidUsuario,
        );
      case TipoEvento.entrega:
        break;
    }
  }

  String _tituloFormulario(TipoEvento? paso) => switch (paso) {
    TipoEvento.siembra => 'Nueva Siembra',
    TipoEvento.encintado => 'Gestionar Encintado',
    TipoEvento.cosecha => 'Registrar Cosecha',
    TipoEvento.entrega => 'Registrar Entrega',
    null => widget.nombreLote,
  };

  String _tiempoTranscurrido(DateTime fecha) {
    final difference = DateTime.now().difference(fecha);
    final days = difference.inDays;
    if (days < 0) return '0 días';
    if (days < 7) return '$days días';
    final weeks = days ~/ 7;
    final remainingDays = days % 7;
    if (remainingDays == 0) return '$weeks sem';
    return '$weeks sem, $remainingDays d';
  }

  String _formatDateDisplay(DateTime date) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${meses[date.month - 1]}, ${date.year}';
  }
}
