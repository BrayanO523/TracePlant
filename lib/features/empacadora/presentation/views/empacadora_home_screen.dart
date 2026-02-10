import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/providers.dart';
import '../../../produccion/domain/entities/produccion_enums.dart'; // Para ColorCinta
import '../viewmodels/empacadora_dashboard_notifier.dart';

class EmpacadoraHomeScreen extends ConsumerStatefulWidget {
  const EmpacadoraHomeScreen({super.key});

  @override
  ConsumerState<EmpacadoraHomeScreen> createState() =>
      _EmpacadoraHomeScreenState();
}

class _EmpacadoraHomeScreenState extends ConsumerState<EmpacadoraHomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario actual ENRIQUECIDO (AppUser)
    final userState = ref.watch(currentUserStreamProvider);
    final user = userState.asData?.value;

    if (userState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      // Si no hay usuario o falló la carga
      return const Scaffold(body: Center(child: Text("Cargando perfil...")));
    }

    final companyId = user.companyId;

    if (companyId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Usuario sin empresa asignada")),
      );
    }

    final state = ref.watch(empacadoraDashboardProvider(companyId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Empacadora'),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Resumen", icon: Icon(Icons.dashboard_rounded)),
              Tab(text: "Productoras", icon: Icon(Icons.people_alt_rounded)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(empacadoraDashboardProvider(companyId));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar Sesión',
              onPressed: () {
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? Center(child: Text("Error: ${state.error}"))
            : TabBarView(
                children: [
                  _DashboardTab(state: state),
                  _ProductorasTab(state: state),
                ],
              ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final EmpacadoraDashboardState state;
  const _DashboardTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Productores',
                value: '${state.productorasAsignadas.length}',
                icon: Icons.store_mall_directory_rounded,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Hectáreas',
                value: '${state.totalHectareasActivas.toStringAsFixed(1)}',
                icon: Icons.landscape_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _KpiCard(
          title: 'Proyección Total (Unidades Encintadas)',
          value: '${state.totalKilosProyectados.toStringAsFixed(0)}',
          icon: Icons.inventory_2_rounded,
          color: Colors.orange.shade800,
          isLarge: true,
        ),

        const SizedBox(height: 24),
        const Text(
          "Proyección por Color (Semana)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (state.proyeccionPorColor.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                "No hay proyecciones activas (cintas registradas)",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...ColorCinta.values.map((color) {
            final cantidad = state.proyeccionPorColor[color] ?? 0;
            final ciclos = state.cantidadCiclosPorColor[color] ?? 0;
            if (cantidad == 0) return const SizedBox.shrink();

            return _ProyeccionCard(
              colorCinta: color,
              cantidad: cantidad,
              ciclos: ciclos,
            );
          }),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLarge;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isLarge ? 32 : 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isLarge ? 16 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 16 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProyeccionCard extends StatelessWidget {
  final ColorCinta colorCinta;
  final double cantidad;
  final int ciclos;

  const _ProyeccionCard({
    required this.colorCinta,
    required this.cantidad,
    required this.ciclos,
  });

  Color _getColor(ColorCinta c) {
    switch (c) {
      case ColorCinta.rojo:
        return Colors.red;
      case ColorCinta.azul:
        return Colors.blue;
      case ColorCinta.verde:
        return Colors.green;
      case ColorCinta.amarillo:
        return Colors.yellow;
      case ColorCinta.naranja:
        return Colors.orange;
      case ColorCinta.morado:
        return Colors.purple;
      case ColorCinta.blanco:
        return Colors.white;
      case ColorCinta.negro:
        return Colors.black;
      case ColorCinta.rosado:
        return Colors.pinkAccent;
      case ColorCinta.celeste:
        return Colors.lightBlue;
    }
  }

  String _getColorName(ColorCinta c) => c.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final color = _getColor(colorCinta);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CINTA ${_getColorName(colorCinta)}",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$ciclos ciclos activos",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cantidad.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Unidades",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductorasTab extends StatelessWidget {
  final EmpacadoraDashboardState state;
  const _ProductorasTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.productorasAsignadas.isEmpty) {
      return const Center(child: Text("No tienes productoras asignadas aún."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.productorasAsignadas.length,
      itemBuilder: (context, index) {
        final productora = state.productorasAsignadas[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                productora.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
            title: Text(
              productora.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productora.location ?? 'Sin ubicación definida'),
                Text(
                  "RTN: ${productora.rnt ?? 'N/A'}",
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Detalle de ${productora.name} (Próximamente)"),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
