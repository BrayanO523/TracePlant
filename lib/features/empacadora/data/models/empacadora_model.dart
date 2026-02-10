import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/empacadora.dart';

class EmpacadoraModel extends Empacadora {
  const EmpacadoraModel({
    required super.id,
    required super.name,
    super.code,
    super.location,
    super.rnt,
    super.capacity,
    super.isActive,
    required super.ownerUid,
    super.createdAt,
    super.updatedAt,
    super.shift,
    super.contactPhone,
  });

  factory EmpacadoraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmpacadoraModel(
      id: doc.id,
      name: data['nombre'] ?? '',
      code: data['codigo'],
      location: data['ubicacion'],
      rnt: data['rtn'],
      capacity: data['capacidad'],
      isActive: data['activo'] ?? true,
      ownerUid: data['uid_propietario'] ?? '',
      shift: data['turno'],
      contactPhone: data['telefono_contacto'],
      createdAt: (data['fecha_creacion'] as Timestamp?)?.toDate(),
      updatedAt: (data['fecha_actualizacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'codigo': code,
      'ubicacion': location,
      'rtn': rnt,
      'capacidad': capacity,
      'activo': isActive,
      'turno': shift,
      'telefono_contacto': contactPhone,
      'uid_propietario': ownerUid,
      if (createdAt != null) 'fecha_creacion': Timestamp.fromDate(createdAt!),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };
  }
}
