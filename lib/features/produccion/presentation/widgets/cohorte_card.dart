import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/logic/encintado_cohortes_logic.dart'; // Importar los modelos
import '../../../../core/utils/formatters.dart';

class CohorteCard extends StatelessWidget {
  final CohorteResumen cohorte;
  final String? fincaNombre;
  final String? loteNombre;
  final VoidCallback? onTap;

  const CohorteCard({
    super.key,
    required this.cohorte,
    this.fincaNombre,
    this.loteNombre,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Parseo seguro del color
    Color colorCinta;
    try {
      colorCinta = Color(
        int.parse(cohorte.cintaColorHex.replaceFirst('#', '0xff')),
      );
    } catch (_) {
      colorCinta = Colors.grey;
    }

    // Formateo de fecha legible "15 Oct"
    // Formateo de fecha legible "15 Oct"
    // Fix: Intenta usar el locale 'es', si falla usa el default.
    String fechaFormat;
    try {
      fechaFormat = DateFormat(
        'd MMM',
        'es',
      ).format(cohorte.fechaEstimadaCosecha);
    } catch (_) {
      // Fallback si no hay locale data: usa formato default del sistema
      fechaFormat = DateFormat('d MMM').format(cohorte.fechaEstimadaCosecha);
    }

    // Cálculo de tiempo restante
    final now = DateTime.now();
    final difference = cohorte.fechaEstimadaCosecha.difference(now);
    final days = difference.inDays;
    // Semanas completas restantes (aprox)
    final weeks = (days / 7).ceil();

    String tiempoRestante;
    Color tiempoColor = Colors.black87;

    if (days < 0) {
      tiempoRestante = 'Vencido hace ${-(days / 7).floor()} sem';
      tiempoColor = Colors.red;
    } else if (days == 0) {
      tiempoRestante = '¡Cosecha Hoy!';
      tiempoColor = Colors.green;
    } else if (weeks <= 1) {
      tiempoRestante = '$days días para cosecha';
    } else {
      tiempoRestante = 'Faltan $weeks semanas';
    }

    return Card(
      elevation: 4,
      shadowColor: colorCinta.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, colorCinta.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Indicador Visual de Color (SOLO COLOR, SIN TEXTO)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorCinta, // Color sólido
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorCinta.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Información Principal (Proyección)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tiempoRestante,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tiempoColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 4),
                      if (fincaNombre != null || loteNombre != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.brown.shade100),
                          ),
                          child: Text(
                            '${fincaNombre ?? ''} • ${loteNombre ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      Text(
                        'Cinta: ${cohorte.cintaColor}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dato Clave Destacado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.green,
                            ),
                            Flexible(
                              child: Text(
                                '${AppFormatters.formatInt(cohorte.cantidadTotal)} Racimos',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Fecha Estimada (Lateral)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ESTIMADA',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      fechaFormat,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'en ${cohorte.anioSiembra}', // O el año de cosecha si cambia
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
