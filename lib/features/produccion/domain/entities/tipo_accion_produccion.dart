enum TipoAccionProduccion { siembra, encintado, cosecha }

extension TipoAccionProduccionExtension on TipoAccionProduccion {
  String get titulo {
    switch (this) {
      case TipoAccionProduccion.siembra:
        return ' Registrar Siembra';
      case TipoAccionProduccion.encintado:
        return ' Lotes a Encintar';
      case TipoAccionProduccion.cosecha:
        return ' Lotes a Cosechar';
    }
  }
}
