import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/variedad.dart';

class VariedadModel extends Variedad {
  const VariedadModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.productoraId,
  });

  factory VariedadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VariedadModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      productoraId: data['productoraId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'productoraId': productoraId,
    };
  }
}
