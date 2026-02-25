import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/ciclo_produccion.dart';
import 'ciclo_history_screen.dart';
import '../../../../core/utils/formatters.dart';

class LoteHistoryScreen extends ConsumerStatefulWidget {
  final String productoraId;
  final String loteId;
  final String nombreLote;

  const LoteHistoryScreen({
    super.key,
    required this.productoraId,
    required this.loteId,
    required this.nombreLote,
  });

  @override
  ConsumerState<LoteHistoryScreen> createState() => _LoteHistoryScreenState();
}

class _LoteHistoryScreenState extends ConsumerState<LoteHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<CicloProduccion> _ciclos = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  DateTime? _lastDate;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(produccionRepositoryProvider);

      // 1. Cargar ciclo activo (si existe)
      final activeResult = await repo.getCicloActivo(
        widget.productoraId,
        widget.loteId,
      );
      CicloProduccion? activeCycle;
      if (activeResult is Success<CicloProduccion>) {
        activeCycle = activeResult.data;
      }

      // 2. Cargar historial (primera página)
      final historyResult = await repo.getHistorialCiclos(
        productoraId: widget.productoraId,
        loteId: widget.loteId,
        limit: _pageSize,
      );

      switch (historyResult) {
        case Success(data: final historyCiclos):
          if (mounted) {
            setState(() {
              _ciclos.clear();
              if (activeCycle != null) {
                _ciclos.add(activeCycle);
              }
              _ciclos.addAll(historyCiclos);

              _hasMore = historyCiclos.length == _pageSize;
              if (historyCiclos.isNotEmpty) {
                _lastDate = historyCiclos.last.fechaSiembra;
              }
              _isLoading = false;
            });
          }
          break;
        case FailureResult(failure: final f):
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = f.message;
            });
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(produccionRepositoryProvider);
      final result = await repo.getHistorialCiclos(
        productoraId: widget.productoraId,
        loteId: widget.loteId,
        limit: _pageSize,
        lastDate: _lastDate,
      );

      switch (result) {
        case Success(data: final newCiclos):
          if (mounted) {
            setState(() {
              _ciclos.addAll(newCiclos);
              _hasMore = newCiclos.length == _pageSize;
              if (newCiclos.isNotEmpty) {
                _lastDate = newCiclos.last.fechaSiembra;
              }
              _isLoading = false;
            });
          }
          break;
        case FailureResult(failure: final f):
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = f.message;
            });
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _refresh() async {
    _lastDate = null;
    _hasMore = true;
    _error = null;
    await _loadInitialData(); // Reload both active and history
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Lote',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nombreLote,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: _ciclos.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ciclos.isEmpty && !_isLoading && _error == null
            ? const Center(
                child: Text(
                  'No hay historial registrado',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _ciclos.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _ciclos.length) {
                    return _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                  }

                  final ciclo = _ciclos[index];
                  return _HistoryCard(ciclo: ciclo);
                },
              ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CicloProduccion ciclo;

  const _HistoryCard({required this.ciclo});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final estadoStr = ciclo.estado.name.toUpperCase();

    Color estadoColor = Colors.grey;
    if (ciclo.estado.name == 'cosechado') {
      estadoColor = AppColors.estadoCosechado;
    }
    if (ciclo.estado.name == 'cancelado') {
      estadoColor = AppColors.estadoCancelado;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CicloHistoryScreen(ciclo: ciclo)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estadoStr,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    dateFormat.format(ciclo.fechaSiembra),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ciclo.variedad,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (ciclo.cantidadCosecha != null && ciclo.cantidadCosecha! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.estadoCosechado,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${AppFormatters.formatNumber(ciclo.cantidadCosecha)} Uds',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
