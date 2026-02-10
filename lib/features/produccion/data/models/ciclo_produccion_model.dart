import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/produccion_enums.dart';

class CicloProduccionModel extends CicloProduccion {
  const CicloProduccionModel({
    required super.id,
    required super.idLote,
    required super.nombreLote,
    required super.idProductora,
    super.estado,
    required super.fechaApertura,
    required super.area,
    required super.variedad,
    super.fechaEncintado,
    super.colorCinta,
    super.cantidadEncintado,
    super.fechaCosecha,
    super.cantidadCosecha,
    super.uidRegistradoPor,
    super.fechaCreacion,
    super.fechaActualizacion,
  });

  factory CicloProduccionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CicloProduccionModel(
      id: doc.id,
      idLote: data['id_lote'] as String? ?? '',
      nombreLote: data['nombre_lote'] as String? ?? '',
      idProductora: data['id_productora'] as String? ?? '',
      estado: _parseEstado(data['estado'] as String?),
      fechaApertura:
          (data['fecha_apertura'] as Timestamp?)?.toDate() ?? DateTime.now(),
      area: (data['area'] as num?)?.toDouble() ?? 0,
      variedad: data['variedad'] as String? ?? '',
      fechaEncintado: (data['fecha_encintado'] as Timestamp?)?.toDate(),
      colorCinta: ColorCinta.fromString(data['color_cinta'] as String?),
      cantidadEncintado: (data['cantidad_encintado'] as num?)?.toDouble(),
      fechaCosecha: (data['fecha_cosecha'] as Timestamp?)?.toDate(),
      cantidadCosecha: (data['cantidad_cosecha'] as num?)?.toDouble(),
      uidRegistradoPor: data['uid_registrado_por'] as String?,
      fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fecha_actualizacion'] as Timestamp?)?.toDate(),
    );
  }

  /// JSON para creación (Apertura)
  Map<String, dynamic> toJsonCreate() {
    return {
      'id_lote': idLote,
      'nombre_lote': nombreLote,
      'id_productora': idProductora,
      'estado': estado.name,
      'fecha_apertura': Timestamp.fromDate(fechaApertura),
      'area': area,
      'variedad': variedad,
      'color_cinta': colorCinta?.name,
      'cantidad_encintado': cantidadEncintado,
      'cantidad_cosecha': cantidadCosecha,
      'uid_registrado_por': uidRegistradoPor,
      'fecha_encintado': fechaEncintado != null
          ? Timestamp.fromDate(fechaEncintado!)
          : null,
      'fecha_cosecha': fechaCosecha != null
          ? Timestamp.fromDate(fechaCosecha!)
          : null,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };
  }

  static EstadoCiclo _parseEstado(String? value) {
    if (value == null) return EstadoCiclo.abierto;
    return EstadoCiclo.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoCiclo.abierto,
    );
  }
}
