import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/productora_stats.dart';
import '../../../../app/di/providers.dart';

// Este provider es una "familia" porque necesita un argumento (productoraId)
// para funcionar. Se usa como: ref.watch(productoraStatsProvider(id))
final productoraStatsProvider = FutureProvider.family<ProductoraStats, String>((
  ref,
  productoraId,
) async {
  final repository = ref.read(produccionRepositoryProvider);

  final result = await repository.getStatsProductora(productoraId);

  if (result is Success<ProductoraStats>) {
    return result.data;
  } else {
    // En caso de error, retornamos vacío para no bloquear la UI
    // Opcional: loggear el error
    return ProductoraStats.empty();
  }
});
