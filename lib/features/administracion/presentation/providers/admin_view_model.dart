import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/cinta.dart';
import '../../domain/entities/finca.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/variedad.dart';
import 'administracion_provider.dart';

class AdminViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AdminViewModel(this.ref) : super(const AsyncValue.data(null));

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> saveCinta({
    String? id, // Optional, null/empty = create
    required String color,
    required String descripcion,
    required String colorHex,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cinta = Cinta(
        id: id ?? '',
        color: color,
        descripcion: descripcion,
        colorHex: colorHex,
        productoraId: _currentUserId,
      );
      await ref.read(administracionRepositoryProvider).saveCinta(cinta);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveVariedad({
    String? id, // Optional
    required String nombre,
    required String descripcion,
  }) async {
    state = const AsyncValue.loading();
    try {
      final variedad = Variedad(
        id: id ?? '',
        nombre: nombre,
        descripcion: descripcion,
        productoraId: _currentUserId,
      );
      await ref.read(administracionRepositoryProvider).saveVariedad(variedad);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveFinca({
    String? id, // Optional
    required String nombre,
    required String ubicacion,
    required double areaTotal,
  }) async {
    state = const AsyncValue.loading();
    try {
      final finca = Finca(
        id: id ?? '',
        nombre: nombre,
        ubicacion: ubicacion,
        areaTotal: areaTotal,
        productoraId: _currentUserId,
      );
      await ref.read(administracionRepositoryProvider).saveFinca(finca);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveLote({
    String? id, // Optional
    required String fincaId,
    required String nombre,
    required double area,
    required String variedadId,
    required String variedadNombre,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Validar Finca
      final finca = await ref
          .read(administracionRepositoryProvider)
          .getFincaById(fincaId);
      if (finca == null) {
        throw Exception('La Finca especificada no existe.');
      }

      // NOTE: We removed the check against available area because Finca area is now dynamic.
      // It grows as we add lotes.

      // 2. Guardar Lote
      final lote = Lote(
        id: id ?? '',
        nombre: nombre,
        area: area,
        fincaId: fincaId,
        variedadId: variedadId,
        variedadNombre: variedadNombre,
        productoraId: _currentUserId,
        estado: 'produccion',
      );
      await ref.read(administracionRepositoryProvider).saveLote(lote);

      // 3. Update Finca Area (Aggregation)
      await _updateFincaArea(fincaId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _updateFincaArea(String fincaId) async {
    final lotes = await ref
        .read(administracionRepositoryProvider)
        .getLotesByFincaFuture(fincaId);

    final totalArea = lotes.fold(0.0, (sum, lote) => sum + lote.area);

    final finca = await ref
        .read(administracionRepositoryProvider)
        .getFincaById(fincaId);

    if (finca != null) {
      final updatedFinca = Finca(
        id: finca.id,
        nombre: finca.nombre,
        ubicacion: finca.ubicacion,
        areaTotal: totalArea, // Updated Area
        productoraId: finca.productoraId,
        activo: finca.activo,
      );
      await ref.read(administracionRepositoryProvider).saveFinca(updatedFinca);
    }
  }

  Future<void> deleteEntity(String collection, String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(administracionRepositoryProvider);

      if (collection == 'lotes') {
        // Find fincaId before deleting
        // Since we don't have getLoteById in Repo, filtering all or just proceeding.
        // Optimization: Ideally pass FincaId to deleteEntity if possible or fetch lotes.
        // Assuming we need to fetch Lote first? Or just iterate all Fincas?
        // Let's rely on watching streams or just fetch All lotes.
        // Actually, FincaDetailScreen passes the Lote object to form, but only ID to delete.
        // A clean way is to query Lotes collection for this ID.
        // Or simpler:
        // We can't easily know Finca ID just from Lote ID without a query.
        // For now, let's assume 'id' deletion works, but updating Finca Area requires Finca ID.

        // Strategy: We will skip auto-aggregation on delete for now efficiently unless we do a query.
        // BUT user asked for "Sumando los lotes".
        // Let's just fix deleteLote later if strictly needed or fetch Finca from Lote if we enable getLoteById.
        // Wait, I can't leave it inconsistent.
        // I'll fetch ALL lotes, find the one, get its FincaId.

        // However, repo doesn't have getLoteById.
        // I'll add getLoteById or a way to get it.
        // Since I can't easily change repo interface in this single step without breaking,
        // and delete typically happens from a context where we know the Finca...
        // Maybe I should pass FincaID to deleteEntity for lotes.
        // But the signature is generic.

        await repo.deleteLote(id);
        // Note: Finca Area won't auto-update on delete blindly here without Finca ID.
        // I will fix `_confirmDeleteLote` in FincaDetailScreen to pass logic or call a specific method.
        // Actually, let's make a specific `deleteLote` method.
      } else {
        if (collection == 'cintas') await repo.deleteCinta(id);
        if (collection == 'variedades') await repo.deleteVariedad(id);
        if (collection == 'fincas') await repo.deleteFinca(id);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLote(String loteId, String fincaId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(administracionRepositoryProvider).deleteLote(loteId);
      await _updateFincaArea(fincaId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminViewModelProvider =
    StateNotifierProvider<AdminViewModel, AsyncValue<void>>((ref) {
      return AdminViewModel(ref);
    });
