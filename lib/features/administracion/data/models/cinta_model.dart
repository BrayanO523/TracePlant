import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cinta.dart';

class CintaModel extends Cinta {
  const CintaModel({
    required super.id,
    required super.color,
    required super.descripcion,
    required super.colorHex,
    required super.productoraId,
  });

  factory CintaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CintaModel(
      id: doc.id,
      color: data['color'] ?? '',
      descripcion: data['descripcion'] ?? '',
      colorHex: data['colorHex'] ?? '#000000',
      productoraId: data['productoraId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'color': color,
      'descripcion': descripcion,
      'colorHex': colorHex,
      'productoraId': productoraId,
    };
  }
}
