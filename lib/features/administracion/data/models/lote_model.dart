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
  });

  factory LoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoteModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      area: (data['area'] ?? 0).toDouble(),
      fincaId: data['fincaId'] ?? '',
      variedadId: data['variedadId'],
      variedadNombre: data['variedadNombre'],
      productoraId: data['productoraId'] ?? '',
      estado: data['estado'] ?? 'produccion',
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
    };
  }
}
