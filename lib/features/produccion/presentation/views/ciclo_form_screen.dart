import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../viewmodels/produccion_notifier.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';

import '../../../administracion/domain/entities/cinta.dart'; // Import Cinta
import '../widgets/estado_indicador.dart';
import 'ciclo_history_screen.dart';

/// Formulario premium para registrar eventos del ciclo.
/// Campos dinámicos según el paso: Siembra, Encintado, Cosecha.
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

    // Si es el paso de encintado y no hay encintados previos, mostramos el form por defecto
    // Si ya hay encintados, mostramos el botón de "Agregar"
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
    ref.listen<
      ProduccionState
    >(produccionNotifierProvider(widget.productoraId), (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.estadoCosechado,
          ),
        );
        ref
            .read(produccionNotifierProvider(widget.productoraId).notifier)
            .clearMessages();

        // Si estamos en encintado, limpiamos el formulario pero NO cerramos la pantalla
        if (widget.siguientePaso == TipoEvento.encintado) {
          setState(() {
            _showEncintadoForm = false;
            _cantidadEncintadoController.clear();
            _cintaSeleccionada = null;
          });
        } else {
          // Si es siembra o cosecha, cerramos
          Navigator.pop(context);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.estadoCancelado,
          ),
        );
        ref
            .read(produccionNotifierProvider(widget.productoraId).notifier)
            .clearMessages();
      }
    });

    final paso = widget.siguientePaso;

    // Buscar ciclo activo del lote
    final cicloActivo = produccionState.ciclos
        .where(
          (c) =>
              c.idLote == widget.idLote &&
              (c.estado == EstadoCiclo.sembrado ||
                  c.estado == EstadoCiclo.encintado),
        )
        .toList();
    final ciclo = cicloActivo.isNotEmpty ? cicloActivo.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloFormulario(paso)),
        actions: [
          if (ciclo != null)
            IconButton(
              tooltip: 'Ver Historial del Ciclo',
              icon: const Icon(Icons.history_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CicloHistoryScreen(ciclo: ciclo),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLoteHeader(theme, ciclo),
              const SizedBox(height: 24),
              if (paso == null)
                _buildCompletedMessage(theme)
              else ...[
                // Indicador de paso actual
                Center(
                  child: EstadoIndicador(
                    estadoCiclo: paso == TipoEvento.siembra
                        ? null // Siembra es el inicio
                        : (paso == TipoEvento.encintado
                              ? EstadoCiclo.encintado
                              : EstadoCiclo.cosechado),
                  ),
                ),
                const SizedBox(height: 24),

                // Campos dinámicos
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
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HEADER & DAY COUNTER
  // ═══════════════════════════════════════════════════════

  Widget _buildLoteHeader(ThemeData theme, CicloProduccion? ciclo) {
    // Calcular días desde siembra
    String diasTexto = '';
    if (ciclo != null) {
      final days = DateTime.now().difference(ciclo.fechaSiembra).inDays;
      diasTexto = 'Día $days del ciclo';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.grass_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombreLote,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ciclo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${ciclo.area.toStringAsFixed(1)} mz · ${ciclo.variedad}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        diasTexto,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
  //  DATE PICKER
  // ═══════════════════════════════════════════════════════

  Widget _buildDatePicker(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _fechaSeleccionada,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _fechaSeleccionada = date);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha del Evento',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDateDisplay(_fechaSeleccionada),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.edit_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CAMPOS DINÁMICOS
  // ═══════════════════════════════════════════════════════

  List<Widget> _buildDynamicFields(
    TipoEvento paso,
    CicloProduccion? ciclo,
    ThemeData theme,
    bool isLoading,
  ) {
    switch (paso) {
      case TipoEvento.siembra:
        return [
          // Fecha
          _buildDatePicker(theme),
          const SizedBox(height: 16),
          _buildSiembraFields(),
          const SizedBox(height: 32),
          _buildSubmitButton(paso, ciclo, isLoading),
        ];

      case TipoEvento.encintado:
        // Layout:
        // 1. Lista de Encintados existentes
        // 2. Botón "Agregar Encintado" (o Formulario)
        // 3. Botón "Ir a Cosecha"
        return [
          _buildEncintadoHistory(theme, ciclo),
          const SizedBox(height: 24),

          if (_showEncintadoForm || (ciclo?.encintados.isEmpty ?? true))
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Nuevo Encintado",
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDatePicker(theme),
                const SizedBox(height: 16),
                _buildEncintadoFields(theme, ciclo),
                const SizedBox(height: 24),
                // Botones Guardar / Cancelar
                Row(
                  children: [
                    if ((ciclo?.encintados.isNotEmpty ?? false))
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _showEncintadoForm = false),
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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showEncintadoForm = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Encintado'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionToCosecha(theme, ciclo),
              ],
            ),
        ];

      case TipoEvento.cosecha:
        return [
          // Fecha
          _buildDatePicker(theme),
          const SizedBox(height: 16),
          _buildCosechaFields(theme, ciclo),
          const SizedBox(height: 32),
          _buildSubmitButton(paso, ciclo, isLoading),
        ];
    }
  }

  Widget _buildSiembraFields() {
    final variedadesAsync = ref.watch(variedadesStreamProvider);
    final bool isAreaLocked = widget.areaLote != null;

    return Column(
      children: [
        TextFormField(
          controller: _areaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: isAreaLocked,
          enabled: !isAreaLocked,
          decoration: InputDecoration(
            labelText: 'Área',
            hintText: 'Ej: 2.5',
            prefixIcon: const Icon(Icons.square_foot_rounded),
            suffixText: 'mz',
            suffixIcon: isAreaLocked
                ? const Icon(Icons.lock_rounded, size: 18, color: Colors.grey)
                : null,
            filled: isAreaLocked,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingrese el área';
            final n = double.tryParse(v);
            if (n == null || n <= 0) return 'Área inválida';
            return null;
          },
        ),
        const SizedBox(height: 16),
        variedadesAsync.when(
          data: (variedades) {
            // Asegurar unicidad por nombre
            final items = variedades.map((v) => v.nombre).toSet().toList();
            // Validar si el valor actual está en la lista
            final currentValue = items.contains(_variedadController.text)
                ? _variedadController.text
                : null;

            return DropdownButtonFormField<String>(
              value: currentValue,
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _variedadController.text = val;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Variedad',
                prefixIcon: Icon(Icons.eco_rounded),
                filled: false,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Seleccione la variedad';
                return null;
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text(
            'Error cargando variedades',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildEncintadoHistory(ThemeData theme, CicloProduccion? ciclo) {
    if (ciclo == null || ciclo.encintados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Text(
          'No hay encintados registrados aún.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Encintados Registrados', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ciclo.encintados.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = ciclo.encintados[index];
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseColor(item.cintaColorHex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                ),
                title: Text('${item.cintaNombre} · ${item.cantidad} uds'),
                subtitle: Text(_formatDateDisplay(item.fecha)),
                trailing: const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.green,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEncintadoFields(ThemeData theme, CicloProduccion? ciclo) {
    final cintasAsync = ref.watch(cintasStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seleccione Color de Cinta', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        cintasAsync.when(
          data: (cintas) {
            if (cintas.isEmpty) {
              return const Text('No hay colores de cinta configurados.');
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cintas.map((cinta) {
                final isSelected = _cintaSeleccionada?.id == cinta.id;
                return GestureDetector(
                  onTap: () => setState(() => _cintaSeleccionada = cinta),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _parseColor(cinta.colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cinta.color,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('Error al cargar cintas: $e'),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cantidadEncintadoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad Encintada (Unidades)',
            hintText: 'Ej: 150',
            prefixIcon: Icon(Icons.numbers_rounded),
            suffixText: 'uds',
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingrese la cantidad';
            final n = double.tryParse(v);
            if (n == null || n <= 0) return 'Cantidad inválida';
            return null;
          },
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    if (hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildActionToCosecha(ThemeData theme, CicloProduccion? ciclo) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: () {
          // Navegar a modo Cosecha
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
          backgroundColor: AppColors.estadoCosechado, // Green
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildCosechaFields(ThemeData theme, CicloProduccion? ciclo) {
    // Total encintado
    final totalEncintado = ciclo?.totalEncintado ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Total Encintado: ${totalEncintado.toStringAsFixed(2)} uds\n'
                  'Ingrese la cantidad de unidades (racimos/bultos) cosechadas.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cantidadEncintadoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad Cosechada REAL',
            hintText: 'Ej: 450',
            prefixIcon: Icon(Icons.agriculture_rounded),
            suffixText: 'unidades',
          ),
          onChanged: (v) {
            setState(() {});
          },
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingrese la cantidad';
            final n = double.tryParse(v);
            if (n == null || n <= 0) return 'Cantidad inválida';
            return null;
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BOTÓN SUBMIT
  // ═══════════════════════════════════════════════════════

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
        Icons.bookmark_rounded,
        AppColors.estadoEncintado,
      ),
      TipoEvento.cosecha => (
        'Registrar Cosecha',
        Icons.agriculture_rounded,
        AppColors.estadoCosechado,
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
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedMessage(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.estadoCosechado.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: AppColors.estadoCosechado,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin ciclos activos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puede iniciar una nueva Siembra\npara este lote.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SUBMIT LOGIC
  // ═══════════════════════════════════════════════════════

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

        // ─── VALIDATION ───
        if (_cintaSeleccionada == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seleccione un color de cinta'),
              backgroundColor: AppColors.estadoCancelado,
            ),
          );
          return;
        }

        final cantidad =
            double.tryParse(_cantidadEncintadoController.text.trim()) ?? 0;
        if (cantidad <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La cantidad debe ser mayor a 0'),
              backgroundColor: AppColors.estadoCancelado,
            ),
          );
          return;
        }

        // ─── EXECUTION ───
        await notifier.registrarEncintado(
          idCiclo: ciclo.id,
          cintaId: _cintaSeleccionada!.id,
          cintaNombre: _cintaSeleccionada!.color,
          cintaColorHex: _cintaSeleccionada!.colorHex,
          cantidad: cantidad,
          fecha: _fechaSeleccionada,
          uidUsuario: uidUsuario,
        );
      // Si el éxito se maneja en el listener, aquí no hacemos mucho más

      case TipoEvento.cosecha:
        if (ciclo == null) return;
        await notifier.registrarCosecha(
          idCiclo: ciclo.id,
          cantidad: double.parse(
            _cantidadEncintadoController.text,
          ), // Use correct controller
          uidUsuario: uidUsuario,
        );
    }
  }

  String _tituloFormulario(TipoEvento? paso) {
    return switch (paso) {
      TipoEvento.siembra => 'Nueva Siembra',
      TipoEvento.encintado => 'Gestionar Encintado',
      TipoEvento.cosecha => 'Registrar Cosecha',
      null => widget.nombreLote,
    };
  }

  String _formatDateDisplay(DateTime date) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${meses[date.month - 1]}, ${date.year}';
  }
}
