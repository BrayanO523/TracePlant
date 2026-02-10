import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/produccion_enums.dart';

class LoteModel extends Lote {
  const LoteModel({
    required super.id,
    required super.nombre,
    required super.area,
    required super.variedad,
    super.estado,
    super.colorCinta,
    required super.idProductora,
    super.fechaCreacion,
    super.fechaActualizacion,
  });

  factory LoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoteModel(
      id: doc.id,
      nombre: data['nombre'] ?? doc.id,
      area: (data['area'] as num?)?.toDouble() ?? 0,
      variedad: data['variedad'] as String? ?? '',
      estado: _parseEstadoLote(data['estado'] as String?),
      colorCinta: ColorCinta.fromString(data['color_cinta'] as String?),
      idProductora: data['id_productora'] as String? ?? '',
      fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fecha_actualizacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'area': area,
      'variedad': variedad,
      'estado': estado.name,
      'color_cinta': colorCinta?.name,
      'id_productora': idProductora,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJsonCreate() {
    return {...toJson(), 'fecha_creacion': FieldValue.serverTimestamp()};
  }

  static EstadoLote _parseEstadoLote(String? value) {
    if (value == null) return EstadoLote.libre;
    return EstadoLote.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoLote.libre,
    );
  }
}
