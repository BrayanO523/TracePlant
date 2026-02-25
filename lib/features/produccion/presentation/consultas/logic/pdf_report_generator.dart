import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:productoraempacadora/features/produccion/domain/entities/ciclo_produccion.dart';
import '../../../../../features/administracion/domain/entities/cinta.dart';
import '../viewmodels/consultas_notifier.dart';

import 'package:productoraempacadora/core/utils/formatters.dart';

class PdfReportGenerator {
  static Future<void> generateAndPrint(
    ConsultasState state,
    Map<String, double> statsPorColor,
    Map<String, double> produccionSemanal,
    String productoraName,
    List<Cinta> cintas, // Nueva dependencia
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Mapear stats usando el nombre REAL del color desde la lista de cintas
    final statsPorNombreReal = _calculateStatsPorNombreReal(
      state.ciclosFiltrados,
      cintas,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(productoraName, dateFormat),
          pw.SizedBox(height: 20),
          _buildSummary(state),
          pw.SizedBox(height: 20),
          if (statsPorNombreReal.isNotEmpty) ...[
            pw.Text(
              'Distribución por Color',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildColorTable(statsPorNombreReal),
            pw.SizedBox(height: 20),
          ],

          // ... (resto igual)

          // ...
          pw.Text(
            'Detalle de Ciclos',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildCiclosTable(state.ciclosFiltrados, dateFormat),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Produccion_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(String productoraName, DateFormat dateFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REPORTE DE PRODUCCIÓN',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(productoraName, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Text(
          'Generado: ${dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(ConsultasState state) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Ciclos',
            AppFormatters.formatInt(state.totalCiclos),
          ),
          _buildSummaryItem(
            'Encintados',
            AppFormatters.formatInt(state.totalEncintado),
          ),
          _buildSummaryItem(
            'Cosechado',
            '${AppFormatters.formatNumber(state.totalCosechado)} Uds',
          ), // Asumiendo unidad
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildColorTable(Map<String, double> stats) {
    final rows = stats.entries.map((e) {
      return [e.key, AppFormatters.formatInt(e.value)];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Color', 'Cantidad'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  static pw.Widget _buildCiclosTable(
    List<CicloProduccion> ciclos,
    DateFormat dateFormat,
  ) {
    final data = ciclos.map((c) {
      final cosecha = c.cantidadCosecha ?? 0;
      return [
        c.nombreLote,
        c.variedad,
        dateFormat.format(c.fechaSiembra),
        AppFormatters.formatInt(c.totalEncintado),
        AppFormatters.formatNumber(cosecha),
        c.estado.name, // Enum name
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Lote', 'Variedad', 'Siembra', 'Cintas', 'Cosecha', 'Estado'],
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      tableWidth: pw.TableWidth.max,
    );
  }

  static Map<String, double> _calculateStatsPorNombreReal(
    List<CicloProduccion> ciclos,
    List<Cinta> cintas,
  ) {
    final Map<String, String> colorMap = {for (var c in cintas) c.id: c.color};

    final Map<String, double> stats = {};
    for (var ciclo in ciclos) {
      for (var e in ciclo.encintados) {
        final nombreReal = colorMap[e.cintaId] ?? e.cintaNombre;
        stats[nombreReal] = (stats[nombreReal] ?? 0) + e.cantidad;
      }
    }
    return stats;
  }
}
