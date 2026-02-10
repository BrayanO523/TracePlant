import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/evento_campo.dart';
import '../../domain/entities/produccion_enums.dart';

class EventoCampoModel extends EventoCampo {
  const EventoCampoModel({
    required super.id,
    required super.tipo,
    required super.idCiclo,
    required super.idLote,
    required super.cantidad,
    super.colorCinta,
    super.observaciones,
    required super.idProductora,
    required super.uidRegistradoPor,
    required super.fechaEvento,
    super.fechaCreacion,
  });

  factory EventoCampoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventoCampoModel(
      id: doc.id,
      tipo: _parseTipo(data['tipo'] as String?),
      idCiclo: data['id_ciclo'] as String? ?? '',
      idLote: data['id_lote'] as String? ?? '',
      cantidad: (data['cantidad'] as num?)?.toDouble() ?? 0,
      colorCinta: data['color_cinta'] as String?,
      observaciones: data['observaciones'] as String?,
      idProductora: data['id_productora'] as String? ?? '',
      uidRegistradoPor: data['uid_registrado_por'] as String? ?? '',
      fechaEvento:
          (data['fecha_evento'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      'tipo': tipo.name,
      'id_ciclo': idCiclo,
      'id_lote': idLote,
      'cantidad': cantidad,
      'color_cinta': colorCinta,
      'observaciones': observaciones,
      'id_productora': idProductora,
      'uid_registrado_por': uidRegistradoPor,
      'fecha_evento': Timestamp.fromDate(fechaEvento),
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
  }

  static TipoEvento _parseTipo(String? value) {
    if (value == null) return TipoEvento.apertura;
    return TipoEvento.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoEvento.apertura,
    );
  }
}
