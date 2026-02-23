import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/finca.dart';

class FincaModel extends Finca {
  const FincaModel({
    required super.id,
    required super.nombre,
    required super.ubicacion,
    required super.areaTotal,
    required super.productoraId,
    super.activo,
    super.coordenadas,
  });

  factory FincaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parsear coordenadas
    final List<Map<String, double>> coords = [];
    if (data['coordenadas'] != null) {
      for (var item in data['coordenadas']) {
        coords.add({
          'lat': (item['lat'] as num).toDouble(),
          'lng': (item['lng'] as num).toDouble(),
        });
      }
    }

    return FincaModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      ubicacion: data['ubicacion'] ?? '',
      areaTotal: (data['areaTotal'] ?? 0).toDouble(),
      productoraId: data['productoraId'] ?? '',
      activo: data['activo'] ?? true,
      coordenadas: coords,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'ubicacion': ubicacion,
      'areaTotal': areaTotal,
      'productoraId': productoraId,
      'activo': activo,
      'coordenadas': coordenadas,
    };
  }
}
