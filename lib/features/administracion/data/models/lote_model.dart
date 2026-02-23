import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lote.dart';

class LoteModel extends Lote {
  const LoteModel({
    required super.id,
    required super.nombre,
    required super.area,
    required super.fincaId,
    super.variedadId,
    super.variedadNombre,
    required super.productoraId,
    required super.estado,
    super.coordenadas,
  });

  factory LoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parsear coordenadas: Firestore las guarda como List<GeoPoint>
    final rawCoords = data['coordenadas'] as List<dynamic>? ?? [];
    final coordenadas = rawCoords.map<Map<String, double>>((point) {
      if (point is GeoPoint) {
        return {'lat': point.latitude, 'lng': point.longitude};
      }
      // Fallback si se guardó como Map
      final m = point as Map<String, dynamic>;
      return {
        'lat': (m['lat'] as num).toDouble(),
        'lng': (m['lng'] as num).toDouble(),
      };
    }).toList();

    return LoteModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      area: (data['area'] ?? 0).toDouble(),
      fincaId: data['fincaId'] ?? '',
      variedadId: data['variedadId'],
      variedadNombre: data['variedadNombre'] ?? data['variedad'],
      productoraId: data['productoraId'] ?? '',
      estado: data['estado'] ?? 'produccion',
      coordenadas: coordenadas,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'area': area,
      'fincaId': fincaId,
      'variedadId': variedadId,
      'variedadNombre': variedadNombre,
      'productoraId': productoraId,
      'estado': estado,
      'coordenadas': coordenadas
          .map((c) => GeoPoint(c['lat']!, c['lng']!))
          .toList(),
    };
  }
}
