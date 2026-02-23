class DetalleEncintado {
  final String id;
  // Reemplazamos enum ColorCinta por datos dinámicos snapshot
  final String cintaId;
  final String cintaNombre;
  final String cintaColorHex;

  final double cantidad; // Unidades (bultos/racimos), NO área
  final double cantidadCosechada; // Nueva: Cuánto de esta cinta ya se cortó
  final DateTime fecha;
  final String? usuarioId;

  const DetalleEncintado({
    required this.id,
    required this.cintaId,
    required this.cintaNombre,
    required this.cintaColorHex,
    required this.cantidad,
    this.cantidadCosechada = 0.0,
    required this.fecha,
    this.usuarioId,
  });

  double get disponible => cantidad - cantidadCosechada;
  bool get isCompletamenteCosechado => disponible <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cinta_id': cintaId,
      'cinta_nombre': cintaNombre,
      'cinta_color_hex': cintaColorHex,
      'cantidad': cantidad,
      'cantidad_cosechada': cantidadCosechada,
      'fecha': fecha.millisecondsSinceEpoch,
      'usuario_id': usuarioId,
    };
  }

  factory DetalleEncintado.fromMap(Map<String, dynamic> map) {
    return DetalleEncintado(
      id: map['id'] ?? '',
      cintaId: map['cinta_id'] ?? '',
      cintaNombre: map['cinta_nombre'] ?? 'Desconocida',
      cintaColorHex: map['cinta_color_hex'] ?? '#CCCCCC',
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0,
      cantidadCosechada: (map['cantidad_cosechada'] as num?)?.toDouble() ?? 0.0,
      fecha: map['fecha'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha'])
          : DateTime.now(),
      usuarioId: map['usuario_id'],
    );
  }
}
