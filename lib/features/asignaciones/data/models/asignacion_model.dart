import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/asignacion.dart';
import '../../domain/entities/asignacion_enums.dart';

/// Modelo de datos Firestore para asignaciones.
class AsignacionModel extends Asignacion {
  const AsignacionModel({
    required super.id,
    required super.idEmpacadora,
    required super.idProductora,
    required super.nombreEmpacadora,
    required super.nombreProductora,
    required super.estado,
    required super.fechaAsignacion,
    super.fechaFinalizacion,
  });

  factory AsignacionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AsignacionModel(
      id: doc.id,
      idEmpacadora: data['id_empacadora'] ?? '',
      idProductora: data['id_productora'] ?? '',
      nombreEmpacadora: data['nombre_empacadora'] ?? '',
      nombreProductora: data['nombre_productora'] ?? '',
      estado: EstadoAsignacion.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoAsignacion.activa,
      ),
      fechaAsignacion:
          (data['fecha_asignacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaFinalizacion: (data['fecha_finalizacion'] as Timestamp?)?.toDate(),
    );
  }

  /// JSON para creación (sin fecha_finalizacion).
  Map<String, dynamic> toJsonCreate() {
    return {
      'id_empacadora': idEmpacadora,
      'id_productora': idProductora,
      'nombre_empacadora': nombreEmpacadora,
      'nombre_productora': nombreProductora,
      'estado': estado.name,
      'fecha_asignacion': Timestamp.fromDate(fechaAsignacion),
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
  }
}
