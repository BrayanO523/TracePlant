import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/productora.dart';

class ProductoraModel extends Productora {
  const ProductoraModel({
    required super.id,
    required super.name,
    super.code,
    super.location,
    super.rnt,
    super.contactPhone,
    super.contactEmail,
    super.isActive,
    required super.ownerUid,
    super.semanasParaCosecha,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductoraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductoraModel(
      id: doc.id,
      name: data['nombre'] ?? '',
      code: data['codigo'],
      location: data['ubicacion'],
      rnt: data['rtn'],
      contactPhone: data['telefono_contacto'],
      contactEmail: data['correo_contacto'],
      isActive: data['activo'] ?? true,
      ownerUid: data['uid_propietario'] ?? '',
      semanasParaCosecha: (data['semanas_para_cosecha'] as num?)?.toInt() ?? 30,
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
      'telefono_contacto': contactPhone,
      'correo_contacto': contactEmail,
      'activo': isActive,
      'uid_propietario': ownerUid,
      'semanas_para_cosecha': semanasParaCosecha,
      if (createdAt != null) 'fecha_creacion': Timestamp.fromDate(createdAt!),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };
  }
}
