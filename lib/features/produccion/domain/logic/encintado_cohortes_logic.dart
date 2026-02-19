import 'package:intl/intl.dart';

// ─── 1. MODELOS DE DATOS ─────────────────────────────────────────────────────

/// INPUT: El registro crudo que entra desde el formulario o base de datos.
/// Representa una acción puntual de un operario en un momento dado.
class EncintadoInput {
  final String id;
  final String loteId;
  final String cintaColor; // Ej: "Amarillo"
  final String cintaColorHex; // Ej: "#FFF100"
  final int cantidad; // Ej: 50 racimos
  final DateTime fecha; // Cuándo se puso la cinta

  EncintadoInput({
    required this.id,
    required this.loteId,
    required this.cintaColor,
    required this.cintaColorHex,
    required this.cantidad,
    required this.fecha,
  });
}

/// OUTPUT: El resumen agrupado para la toma de decisiones.
/// Representa una "Cohorte de Producción" que madurará junta.
class CohorteResumen {
  final String idCohorte; // Generado: "W42-Amarillo-LoteX"
  final int semanaSiembra; // Semana ISO del encintado
  final int anioSiembra;
  final String cintaColor;
  final String cintaColorHex;
  final String loteId; // Nuevo: Para desglose por lote
  final int cantidadTotal; // Suma de todos los inputs de esa semana
  final DateTime
  fechaEstimadaCosecha; // Fecha encintado + semanas de maduración
  final int semanaCosecha; // Semana ISO de la cosecha

  CohorteResumen({
    required this.idCohorte,
    required this.semanaSiembra,
    required this.anioSiembra,
    required this.cintaColor,
    required this.cintaColorHex,
    required this.loteId,
    required this.cantidadTotal,
    required this.fechaEstimadaCosecha,
    required this.semanaCosecha,
  });
}

// ─── 2. SERVICIO DE LÓGICA (Processing Service) ──────────────────────────────

class EncintadoProcessor {
  // Configurable: Semanas que tarda el fruto en estar listo para corte
  // static const int semanasMaduracion = 11; // Eliminado, ahora es dinámico

  /// Transforma una lista dispersa de inputs en una lista consolidada de cohortes.
  /// [semParaCosecha] viene de la configuración de la Productora (por defecto 11 o 12).
  List<CohorteResumen> procesarCohortes(
    List<EncintadoInput> inputsRaw,
    int semParaCosecha,
  ) {
    if (inputsRaw.isEmpty) return [];

    // Estructura temporal para agrupar: Map<Key, List<Input>>
    // Key: "AÑO-SEMANA-COLOR-LOTEID"
    final Map<String, List<EncintadoInput>> agrupador = {};

    for (var input in inputsRaw) {
      final iso = _getIsoWeek(input.fecha);
      // Clave única de agrupación incluyendo Lote
      final key = '${iso.year}-${iso.week}-${input.cintaColor}-${input.loteId}';

      agrupador.putIfAbsent(key, () => []).add(input);
    }

    // Transformar Map agrupado a Lista de Resúmenes
    final List<CohorteResumen> resultados = [];

    agrupador.forEach((key, inputsGrupo) {
      if (inputsGrupo.isEmpty) return;

      // 1. Datos comunes del grupo (tomamos del primero)
      final first = inputsGrupo.first;
      final isoEncintado = _getIsoWeek(first.fecha);

      // 2. Sumar cantidades
      final total = inputsGrupo.fold(0, (sum, item) => sum + item.cantidad);

      // 3. Proyectar Cosecha
      // Tomamos la fecha promedio o la del lunes de esa semana como base
      // Para simplificar, usaremos la fecha del primer registro + ajuste de semana.
      final fechaCosecha = first.fecha.add(Duration(days: semParaCosecha * 7));
      final isoCosecha = _getIsoWeek(fechaCosecha);

      resultados.add(
        CohorteResumen(
          idCohorte: key,
          semanaSiembra: isoEncintado.week,
          anioSiembra: isoEncintado.year,
          cintaColor: first.cintaColor,
          cintaColorHex: first.cintaColorHex,
          loteId: first.loteId,
          cantidadTotal: total,
          fechaEstimadaCosecha: fechaCosecha,
          semanaCosecha: isoCosecha.week,
        ),
      );
    });

    // Ordenar por fecha de cosecha (lo más pronto primero)
    resultados.sort(
      (a, b) => a.fechaEstimadaCosecha.compareTo(b.fechaEstimadaCosecha),
    );

    return resultados;
  }

  /// Helper: Cálculo de Semana ISO-8601
  ({int week, int year}) _getIsoWeek(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return (
        week: 52,
        year: date.year - 1,
      ); // Aproximación simple, idealmente recursivo
    } else if (woy > 52) {
      return (week: 1, year: date.year + 1);
    } else {
      return (week: woy, year: date.year);
    }
  }
}
