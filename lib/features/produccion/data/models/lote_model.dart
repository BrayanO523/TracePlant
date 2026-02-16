import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/produccion_enums.dart';

class LoteModel extends Lote {
  const LoteModel({
    required super.id,
    required super.nombre,
    required super.area,
    required super.variedad,
    required super.fincaId,
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
      fincaId: data['fincaId'] ?? '',
      estado: _parseEstadoLote(data['estado'] as String?),
      colorCinta: ColorCinta.fromString(data['color_cinta'] as String?),
      // Soportar ambas claves por inconsistencia detectada
      idProductora:
          data['productoraId'] as String? ??
          data['id_productora'] as String? ??
          '',
      fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fecha_actualizacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'area': area,
      'variedad': variedad,
      'id_finca': fincaId,
      'estado': estado.name,
      'color_cinta': colorCinta?.name,
      'id_productora':
          idProductora, // Mantenemos consistencia con id_productora para nuevos
      'productoraId':
          idProductora, // Guardamos ambos para compatibilidad temporal
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJsonCreate() {
    return {...toJson(), 'fecha_creacion': FieldValue.serverTimestamp()};
  }

  static EstadoLote _parseEstadoLote(String? value) {
    if (value == null) return EstadoLote.libre;
    try {
      return EstadoLote.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => EstadoLote.libre,
      );
    } catch (_) {
      return EstadoLote.libre;
    }
  }
}
