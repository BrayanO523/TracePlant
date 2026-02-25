import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../produccion/presentation/views/produccion_dashboard_screen.dart';
import '../../../produccion/presentation/views/ciclo_history_screen.dart';
import '../viewmodels/empacadora_dashboard_notifier.dart';
import '../../../../core/utils/formatters.dart';

class EmpacadoraHomeScreen extends ConsumerStatefulWidget {
  const EmpacadoraHomeScreen({super.key});

  @override
  ConsumerState<EmpacadoraHomeScreen> createState() =>
      _EmpacadoraHomeScreenState();
}

class _EmpacadoraHomeScreenState extends ConsumerState<EmpacadoraHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserStreamProvider);
    final user = userState.asData?.value;

    if (userState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: Center(child: Text('Cargando perfil...')),
      );
    }

    final companyId = user.companyId;

    if (companyId == null) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: Center(child: Text('Error: Usuario sin empresa asignada')),
      );
    }

    final state = ref.watch(empacadoraDashboardProvider(companyId));

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? _buildErrorView(state.error!, companyId)
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxScrolled) => [
                _buildSliverAppBar(companyId),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _ResumenTab(state: state),
                  _ProductorasTab(state: state, companyId: companyId),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorView(String error, String companyId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.invalidate(empacadoraDashboardProvider(companyId)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(String companyId) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
        title: const Text(
          'Panel Empacadora',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 60),
              child: Icon(
                Icons.warehouse_rounded,
                size: 60,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          tooltip: 'Actualizar',
          onPressed: () {
            ref.invalidate(empacadoraDashboardProvider(companyId));
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          tooltip: 'Cerrar Sesión',
          onPressed: () {
            ref.read(authNotifierProvider.notifier).signOut();
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Resumen', icon: Icon(Icons.dashboard_rounded, size: 20)),
          Tab(text: 'Productoras', icon: Icon(Icons.store_rounded, size: 20)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB RESUMEN
// ═══════════════════════════════════════════════════════

class _ResumenTab extends StatelessWidget {
  final EmpacadoraDashboardState state;
  const _ResumenTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // KPIs
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Productoras',
                value: AppFormatters.formatInt(
                  state.productorasAsignadas.length,
                ),
                icon: Icons.store_mall_directory_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                title: 'Ciclos Activos',
                value: AppFormatters.formatInt(state.totalCiclosActivos),
                icon: Icons.loop_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _KpiCard(
          title: 'Total Encintado',
          value: AppFormatters.formatInt(state.totalKilosProyectados),
          icon: Icons.inventory_2_rounded,
          color: AppColors.estadoEncintado,
          suffix: 'un',
        ),

        const SizedBox(height: 24),

        // Proyección por cinta
        _buildSectionHeader('Proyección por Cinta', Icons.bookmark_rounded),
        const SizedBox(height: 10),
        if (state.proyeccionesCinta.isEmpty)
          _buildEmptyState('No hay cintas registradas aún')
        else
          ...state.proyeccionesCinta.map((p) => _CintaCard(proyeccion: p)),

        const SizedBox(height: 24),

        // Próximas cosechas
        _buildSectionHeader('Próximas Cosechas', Icons.event_available_rounded),
        const SizedBox(height: 10),
        if (state.proximasCosechas.isEmpty)
          _buildEmptyState('No hay cosechas proyectadas')
        else
          ...state.proximasCosechas.map((c) => _CosechaCard(cosecha: c)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  KPI CARD
// ═══════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    suffix!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CINTA PROJECTION CARD
// ═══════════════════════════════════════════════════════

class _CintaCard extends StatelessWidget {
  final ProyeccionCinta proyeccion;
  const _CintaCard({required this.proyeccion});

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(proyeccion.colorHex);
    final isLight = color.computeLuminance() > 0.7;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CicloHistoryScreen(ciclo: proyeccion.ciclo),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: isLight
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proyeccion.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (proyeccion.nombreLote.isNotEmpty)
                            proyeccion.nombreLote,
                          if (proyeccion.nombreFinca.isNotEmpty)
                            proyeccion.nombreFinca,
                          if (proyeccion.nombreProductora.isNotEmpty)
                            proyeccion.nombreProductora,
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${AppFormatters.formatInt(proyeccion.cantidad)} un',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isLight ? Colors.grey.shade800 : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PRÓXIMA COSECHA CARD
// ═══════════════════════════════════════════════════════

class _CosechaCard extends StatelessWidget {
  final ProximaCosecha cosecha;
  const _CosechaCard({required this.cosecha});

  @override
  Widget build(BuildContext context) {
    final dias = cosecha.diasRestantes;
    final isPast = dias <= 0;
    final isUrgent = dias <= 30 && dias > 0;

    final statusColor = isPast
        ? AppColors.error
        : isUrgent
        ? AppColors.warning
        : AppColors.estadoCosechado;

    final statusText = isPast
        ? '${dias.abs()}d pasado'
        : dias == 0
        ? '¡Hoy!'
        : '$dias días';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CicloHistoryScreen(ciclo: cosecha.ciclo),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPast ? Icons.warning_rounded : Icons.schedule_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cosecha.nombreLote,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (cosecha.nombreFinca.isNotEmpty)
                            cosecha.nombreFinca,
                          cosecha.productoraName,
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cosecha.fechaProyectada.day}/${cosecha.fechaProyectada.month}/${cosecha.fechaProyectada.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB PRODUCTORAS
// ═══════════════════════════════════════════════════════

class _ProductorasTab extends StatelessWidget {
  final EmpacadoraDashboardState state;
  final String companyId;

  const _ProductorasTab({required this.state, required this.companyId});

  @override
  Widget build(BuildContext context) {
    if (state.productorasAsignadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No tienes productoras asignadas aún',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.productorasAsignadas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final productora = state.productorasAsignadas[index];
        final ciclosCount = state.ciclosPorProductora[productora.id] ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProduccionDashboardScreen(
                  productoraId: productora.id,
                  readOnly: true,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      productora.name.isNotEmpty
                          ? productora.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productora.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              productora.location ?? 'Sin ubicación',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Stats row
                      Row(
                        children: [
                          _miniStat(
                            Icons.loop_rounded,
                            '$ciclosCount ciclos',
                            AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          if (productora.rnt != null)
                            _miniStat(
                              Icons.badge_outlined,
                              productora.rnt!,
                              AppColors.textHint,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
