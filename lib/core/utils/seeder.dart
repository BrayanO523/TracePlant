import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Genera datos de prueba en Firestore para debugging.
class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedProduccion(String productoraId) async {
    if (kDebugMode) {
      //  print("SEEDING DATA FOR PRODUCTORA: $productoraId");
    }

    final batch = _firestore.batch();
    final produccionRef = _firestore
        .collection('productoras')
        .doc(productoraId);

    // 1. Asegurar documento Productora
    batch.set(produccionRef, {
      'id': productoraId,
      'nombre': 'Productora Demo',
      'ubicacion': 'Valle de Comayagua',
      'rnt': 'HN-2024-TEST',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Crear Lotes con area y variedad
    final lotesData = [
      {
        'nombre': 'LOTE A',
        'estado': 'libre',
        'area': 3.5,
        'variedad': 'Sandía',
      },
      {'nombre': 'LOTE B', 'estado': 'libre', 'area': 2.0, 'variedad': 'Melón'},
      {
        'nombre': 'LOTE C',
        'estado': 'ocupado',
        'area': 4.2,
        'variedad': 'Arroz',
        'color_cinta': 'rojo',
      },
      {
        'nombre': 'LOTE D',
        'estado': 'libre',
        'area': 1.8,
        'variedad': 'Frijoles',
      },
    ];

    final loteIds = <String, String>{}; // nombre → docId

    for (var lote in lotesData) {
      final docRef = _firestore.collection('lotes').doc();
      loteIds[lote['nombre'] as String] = docRef.id;
      batch.set(docRef, {
        'id': docRef.id,
        'nombre': lote['nombre'],
        'id_productora': productoraId,
        'estado': lote['estado'],
        'area': lote['area'],
        'variedad': lote['variedad'],
        if (lote.containsKey('color_cinta')) 'color_cinta': lote['color_cinta'],
        'fecha_creacion': FieldValue.serverTimestamp(),
      });
    }

    // 3. Ciclo abierto para Lote C (Arroz)
    final docRefCiclo = _firestore.collection('ciclos_produccion').doc();
    final fechaInicio = DateTime.now().subtract(const Duration(days: 5));
    final idLoteC = loteIds['LOTE C']!;

    batch.set(docRefCiclo, {
      'id': docRefCiclo.id,
      'id_lote': idLoteC,
      'nombre_lote': 'LOTE C',
      'id_productora': productoraId,
      'estado': 'abierto',
      'fecha_apertura': Timestamp.fromDate(fechaInicio),
      'area': 4.2,
      'variedad': 'Arroz',
      'uid_registrado_por': productoraId,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });

    // 4. Ciclo cosechado (historial) - Lote A (Sandía)
    final docRefCiclo2 = _firestore.collection('ciclos_produccion').doc();
    final fechaInicio2 = DateTime.now().subtract(const Duration(days: 30));
    final idLoteA = loteIds['LOTE A']!;

    batch.set(docRefCiclo2, {
      'id': docRefCiclo2.id,
      'id_lote': idLoteA,
      'nombre_lote': 'LOTE A',
      'id_productora': productoraId,
      'estado': 'cosechado',
      'fecha_apertura': Timestamp.fromDate(fechaInicio2),
      'area': 3.5,
      'variedad': 'Sandía',
      'color_cinta': 'azul',
      'cantidad_encintado': 520.0,
      'fecha_encintado': Timestamp.fromDate(
        fechaInicio2.add(const Duration(days: 10)),
      ),
      'cantidad_cosecha': 480.0,
      'fecha_cosecha': Timestamp.fromDate(
        fechaInicio2.add(const Duration(days: 25)),
      ),
      'uid_registrado_por': productoraId,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    if (kDebugMode) {
      //  print("SEED COMPLETE");
    }
  }
}
