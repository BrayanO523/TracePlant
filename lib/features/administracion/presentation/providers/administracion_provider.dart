import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/administracion_repository_impl.dart';
import '../../domain/entities/cinta.dart';
import '../../domain/entities/finca.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/variedad.dart';
import '../../domain/repositories/i_administracion_repository.dart';

// Repository Provider
final administracionRepositoryProvider = Provider<IAdministracionRepository>((
  ref,
) {
  return AdministracionRepositoryImpl();
});

// Streams
final cintasStreamProvider = StreamProvider<List<Cinta>>((ref) {
  final repository = ref.watch(administracionRepositoryProvider);
  return repository.watchCintas();
});

final variedadesStreamProvider = StreamProvider<List<Variedad>>((ref) {
  final repository = ref.watch(administracionRepositoryProvider);
  return repository.watchVariedades();
});

final fincasStreamProvider = StreamProvider<List<Finca>>((ref) {
  final repository = ref.watch(administracionRepositoryProvider);
  return repository.watchFincas();
});

final lotesByFincaStreamProvider = StreamProvider.family<List<Lote>, String>((
  ref,
  fincaId,
) {
  final repository = ref.watch(administracionRepositoryProvider);
  return repository.watchLotesByFinca(fincaId);
});

final allLotesStreamProvider = StreamProvider<List<Lote>>((ref) {
  final repository = ref.watch(administracionRepositoryProvider);
  return repository.watchAllLotes();
});
