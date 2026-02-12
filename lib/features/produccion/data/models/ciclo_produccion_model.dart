import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ciclo_produccion.dart';
import '../../domain/entities/detalle_encintado.dart';
import '../../domain/entities/produccion_enums.dart';

class CicloProduccionModel extends CicloProduccion {
  const CicloProduccionModel({
    required super.id,
    required super.idLote,
    required super.nombreLote,
    required super.idProductora,
    required super.estado,
    required super.fechaSiembra,
    required super.area,
    required super.variedad,
    super.encintados,
    super.fechaCosecha,
    super.cantidadCosecha,
    super.merma,
    super.mermaPorcentaje,
    super.uidRegistradoPor,
    super.idEmpacadora,
    super.fechaCreacion,
    super.fechaActualizacion,
  });

  factory CicloProduccionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parsear lista de encintados
    final List<DetalleEncintado> encintadosList = [];
    if (data['encintados'] != null) {
      final list = data['encintados'] as List;
      encintadosList.addAll(
        list.map((e) => DetalleEncintado.fromMap(e as Map<String, dynamic>)),
      );
    }
    // Compatibilidad hacia atrás (migración al vuelo)
    else if (data['cantidad_encintado'] != null) {
      // Si existe el formato viejo, lo convertimos a una entrada en la lista
      final legacyColor =
          ColorCinta.fromString(data['color_cinta'] as String?) ??
          ColorCinta.blanco;
      encintadosList.add(
        DetalleEncintado(
          id: 'legacy',
          cintaId: 'legacy_${legacyColor.name}',
          cintaNombre: legacyColor.label,
          cintaColorHex:
              '#${legacyColor.colorValue.toRadixString(16).padLeft(8, '0').substring(2)}', // ARGB to Hex
          cantidad: (data['cantidad_encintado'] as num?)?.toDouble() ?? 0,
          fecha:
              (data['fecha_encintado'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        ),
      );
    }

    return CicloProduccionModel(
      id: doc.id,
      idLote: data['id_lote'] as String? ?? '',
      nombreLote: data['nombre_lote'] as String? ?? '',
      idProductora: data['id_productora'] as String? ?? '',
      estado: _parseEstado(data['estado'] as String?),
      fechaSiembra:
          (data['fecha_siembra'] as Timestamp?)?.toDate() ??
          (data['fecha_apertura'] as Timestamp?)?.toDate() ?? // Compatibilidad
          DateTime.now(),
      area: (data['area'] as num?)?.toDouble() ?? 0,
      variedad: data['variedad'] as String? ?? '',
      encintados: encintadosList,
      fechaCosecha: (data['fecha_cosecha'] as Timestamp?)?.toDate(),
      cantidadCosecha: (data['cantidad_cosecha'] as num?)?.toDouble(),
      merma: (data['merma'] as num?)?.toDouble(),
      mermaPorcentaje: (data['merma_porcentaje'] as num?)?.toDouble(),
      idEmpacadora: data['id_empacadora'] as String?,
      uidRegistradoPor: data['uid_registrado_por'] as String?,
      fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fecha_actualizacion'] as Timestamp?)?.toDate(),
    );
  }

  /// JSON para creación (Siembra)
  Map<String, dynamic> toJsonCreate() {
    return {
      'id_lote': idLote,
      'nombre_lote': nombreLote,
      'id_productora': idProductora,
      'estado': estado.name,
      'fecha_siembra': Timestamp.fromDate(fechaSiembra),
      'area': area,
      'variedad': variedad,
      'encintados': encintados.map((e) => e.toMap()).toList(),
      'cantidad_cosecha': cantidadCosecha,
      'merma': merma,
      'merma_porcentaje': mermaPorcentaje,
      'id_empacadora': idEmpacadora,
      'uid_registrado_por': uidRegistradoPor,
      'fecha_cosecha': fechaCosecha != null
          ? Timestamp.fromDate(fechaCosecha!)
          : null,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };
  }

  static EstadoCiclo _parseEstado(String? value) {
    if (value == null) return EstadoCiclo.sembrado;
    return EstadoCiclo.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoCiclo.sembrado,
    );
  }
}
