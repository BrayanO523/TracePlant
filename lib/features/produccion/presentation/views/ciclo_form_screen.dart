import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../viewmodels/produccion_notifier.dart';
import '../widgets/estado_indicador.dart';
import '../widgets/color_cinta_ext.dart';
import '../../domain/entities/produccion_enums.dart';
import '../../domain/entities/ciclo_produccion.dart';

/// Formulario premium para registrar eventos del ciclo.
/// Campos dinámicos según el paso: Apertura, Encintado, Cosecha.
class CicloFormScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final String idLote;
  final String nombreLote;
  final TipoEvento? siguientePaso;

  const CicloFormScreen({
    super.key,
    required this.productoraId,
    required this.idLote,
    required this.nombreLote,
    this.siguientePaso,
  });

  @override
  ConsumerState<CicloFormScreen> createState() => _CicloFormScreenState();
}

class _CicloFormScreenState extends ConsumerState<CicloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _variedadController = TextEditingController();
  final _cantidadController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();
  ColorCinta? _colorCintaSeleccionado;

  @override
  void dispose() {
    _areaController.dispose();
    _variedadController.dispose();
    _cantidadController.dispose();
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
              backgroundColor: const Color(0xFF43A047),
            ),
          );
          ref
              .read(produccionNotifierProvider(widget.productoraId).notifier)
              .clearMessages();
          Navigator.pop(context);
        }
        if (next.error != null && prev?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
          ref
              .read(produccionNotifierProvider(widget.productoraId).notifier)
              .clearMessages();
        }
      },
    );

    final paso = widget.siguientePaso;

    // Buscar ciclo activo del lote
    final cicloActivo = produccionState.ciclos
        .where(
          (c) =>
              c.idLote == widget.idLote &&
              (c.estado == EstadoCiclo.abierto ||
                  c.estado == EstadoCiclo.encintado),
        )
        .toList();
    final ciclo = cicloActivo.isNotEmpty ? cicloActivo.first : null;

    return Scaffold(
      appBar: AppBar(title: Text(_tituloFormulario(paso))),
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
                    estadoCiclo: paso == TipoEvento.apertura
                        ? null
                        : (paso == TipoEvento.encintado
                              ? EstadoCiclo.abierto
                              : EstadoCiclo.encintado),
                    colorCinta: ciclo?.colorCinta,
                  ),
                ),
                const SizedBox(height: 24),
                // Fecha
                _buildDatePicker(theme),
                const SizedBox(height: 16),
                // Campos dinámicos
                ..._buildDynamicFields(paso, ciclo, theme),
                const SizedBox(height: 32),
                _buildSubmitButton(paso, ciclo, produccionState.isLoading),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════

  Widget _buildLoteHeader(ThemeData theme, CicloProduccion? ciclo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
                  if (ciclo.colorCinta != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: ciclo.colorCinta!.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cinta: ${ciclo.colorCinta!.label}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  DATE PICKER PREMIUM
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
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                  'Fecha',
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
  ) {
    switch (paso) {
      case TipoEvento.apertura:
        return [
          TextFormField(
            controller: _areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Área',
              hintText: 'Ej: 2.5',
              prefixIcon: Icon(Icons.square_foot_rounded),
              suffixText: 'mz',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingrese el área';
              final n = double.tryParse(v);
              if (n == null || n <= 0) return 'Área inválida';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _variedadController,
            decoration: const InputDecoration(
              labelText: 'Variedad',
              hintText: 'Ej: Cavendish, Williams...',
              prefixIcon: Icon(Icons.eco_rounded),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingrese la variedad';
              return null;
            },
          ),
        ];

      case TipoEvento.encintado:
        return [
          // Selector visual de color de cinta
          _buildColorCintaSelector(theme),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cantidadController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              hintText: 'Ej: 480',
              prefixIcon: Icon(Icons.straighten_rounded),
              suffixText: 'unidades',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingrese la cantidad';
              final n = double.tryParse(v);
              if (n == null || n <= 0) return 'Cantidad inválida';
              return null;
            },
          ),
        ];

      case TipoEvento.cosecha:
        return [
          // Color heredado (solo lectura)
          if (ciclo?.colorCinta != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ciclo!.colorCinta!.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ciclo.colorCinta!.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ciclo.colorCinta!.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cinta: ${ciclo.colorCinta!.label}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Info de encintado
          if (ciclo?.cantidadEncintado != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Cantidad encintada: ${ciclo!.cantidadEncintado!.toStringAsFixed(0)} unidades',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          TextFormField(
            controller: _cantidadController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cantidad Cosechada',
              hintText: 'Ej: 450',
              prefixIcon: Icon(Icons.agriculture_rounded),
              suffixText: 'unidades',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingrese la cantidad';
              final n = double.tryParse(v);
              if (n == null || n <= 0) return 'Cantidad inválida';
              return null;
            },
          ),
        ];
    }
  }

  // ═══════════════════════════════════════════════════════
  //  COLOR CINTA SELECTOR (Grid visual premium)
  // ═══════════════════════════════════════════════════════

  Widget _buildColorCintaSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color de Cinta',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ColorCinta.values.map((color) {
            final isSelected = _colorCintaSeleccionado == color;
            return GestureDetector(
              onTap: () {
                setState(() => _colorCintaSeleccionado = color);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.color.withValues(alpha: isSelected ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? color.color
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.color.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      color.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_colorCintaSeleccionado == null) ...[
          const SizedBox(height: 8),
          Text(
            'Seleccione un color',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
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
      TipoEvento.apertura => (
        'Registrar Apertura',
        Icons.play_circle_rounded,
        const Color(0xFFF9A825),
      ),
      TipoEvento.encintado => (
        'Registrar Encintado',
        Icons.bookmark_rounded,
        const Color(0xFF1E88E5),
      ),
      TipoEvento.cosecha => (
        'Registrar Cosecha',
        Icons.agriculture_rounded,
        const Color(0xFF43A047),
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
              color: const Color(0xFF43A047).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: Color(0xFF43A047),
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
            'Puede iniciar una nueva Apertura\npara este lote.',
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
    // Validar color de cinta en encintado
    if (paso == TipoEvento.encintado && _colorCintaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un color de cinta'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateStreamProvider);
    final uidUsuario = authState.asData?.value?.uid ?? 'unknown';

    final notifier = ref.read(
      produccionNotifierProvider(widget.productoraId).notifier,
    );

    switch (paso) {
      case TipoEvento.apertura:
        await notifier.registrarApertura(
          idLote: widget.idLote,
          nombreLote: widget.nombreLote,
          area: double.parse(_areaController.text),
          variedad: _variedadController.text.trim(),
          uidUsuario: uidUsuario,
        );
      case TipoEvento.encintado:
        if (ciclo == null) return;
        await notifier.registrarEncintado(
          idCiclo: ciclo.id,
          colorCinta: _colorCintaSeleccionado!,
          cantidad: double.parse(_cantidadController.text),
          uidUsuario: uidUsuario,
        );
      case TipoEvento.cosecha:
        if (ciclo == null) return;
        await notifier.registrarCosecha(
          idCiclo: ciclo.id,
          cantidad: double.parse(_cantidadController.text),
          uidUsuario: uidUsuario,
        );
    }
  }

  String _tituloFormulario(TipoEvento? paso) {
    return switch (paso) {
      TipoEvento.apertura => 'Nueva Apertura',
      TipoEvento.encintado => 'Registrar Encintado',
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
