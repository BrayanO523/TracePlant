// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> limpiarDatosHuerfanos() async {
  final firestore = FirebaseFirestore.instance;
  print('🧹 Iniciando limpieza de datos huérfanos...');

  // 1. Obtener todas las Fincas activas IDs
  final fincasSnap = await firestore.collection('fincas').get();
  final fincasIds = fincasSnap.docs.map((d) => d.id).toSet();
  print('📋 Fincas encontradas: ${fincasIds.length}');

  // 2. Buscar Lotes huérfanos (fincaId no existe en fincasIds)
  final lotesSnap = await firestore.collection('lotes').get();
  int lotesBorrados = 0;

  for (var loteDoc in lotesSnap.docs) {
    final fincaId = loteDoc.data()['fincaId'] as String?;

    // Si tiene fincaId pero esa finca NO existe, es huérfano
    if (fincaId != null && !fincasIds.contains(fincaId)) {
      print(
        '🗑️ Borrando Lote huérfano: ${loteDoc.id} (Finca inexistente: $fincaId)',
      );

      // Borrar ciclos de este lote primero
      await _borrarCiclosDeLote(firestore, loteDoc.id);

      // Borrar el lote
      await loteDoc.reference.delete();
      lotesBorrados++;
    }
  }
  print('✅ Lotes huérfanos eliminados: $lotesBorrados');

  // 3. Buscar Ciclos huérfanos (id_lote no existe) - Opcional, doble chequeo
  // Esto es costoso si hay muchos ciclos, pero útil para limpieza profunda.
}

Future<void> _borrarCiclosDeLote(FirebaseFirestore db, String loteId) async {
  final ciclosSnap = await db
      .collection('ciclos_produccion')
      .where('id_lote', isEqualTo: loteId)
      .get();

  for (var ciclo in ciclosSnap.docs) {
    await ciclo.reference.delete();
  }
  if (ciclosSnap.docs.isNotEmpty) {
    print('   ↳ Eliminados ${ciclosSnap.docs.length} ciclos del lote $loteId');
  }
}
