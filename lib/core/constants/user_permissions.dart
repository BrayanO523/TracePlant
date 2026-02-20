import 'package:equatable/equatable.dart';

/// Permiso individual de un módulo (ver, crear, editar, eliminar).
class ModulePermission extends Equatable {
  final bool ver;
  final bool crear;
  final bool editar;
  final bool eliminar;

  const ModulePermission({
    this.ver = false,
    this.crear = false,
    this.editar = false,
    this.eliminar = false,
  });

  /// Todos los permisos activos
  const ModulePermission.all()
    : ver = true,
      crear = true,
      editar = true,
      eliminar = true;

  /// Sin permisos
  const ModulePermission.none()
    : ver = false,
      crear = false,
      editar = false,
      eliminar = false;

  /// Solo lectura
  const ModulePermission.readOnly()
    : ver = true,
      crear = false,
      editar = false,
      eliminar = false;

  /// ¿Tiene al menos permiso de ver?
  bool get tieneAcceso => ver;

  ModulePermission copyWith({
    bool? ver,
    bool? crear,
    bool? editar,
    bool? eliminar,
  }) {
    return ModulePermission(
      ver: ver ?? this.ver,
      crear: crear ?? this.crear,
      editar: editar ?? this.editar,
      eliminar: eliminar ?? this.eliminar,
    );
  }

  Map<String, dynamic> toJson() => {
    'ver': ver,
    'crear': crear,
    'editar': editar,
    'eliminar': eliminar,
  };

  factory ModulePermission.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModulePermission.none();
    return ModulePermission(
      ver: json['ver'] as bool? ?? false,
      crear: json['crear'] as bool? ?? false,
      editar: json['editar'] as bool? ?? false,
      eliminar: json['eliminar'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [ver, crear, editar, eliminar];
}

/// Permisos completos de un usuario, con un módulo por cada sub-vista.
class UserPermissions extends Equatable {
  // ── Administración ──
  final ModulePermission cintas;
  final ModulePermission variedades;
  final ModulePermission fincas;
  final ModulePermission lotes;

  // ── Producción ──
  final ModulePermission siembra;
  final ModulePermission encintado;
  final ModulePermission cosecha;

  // ── Consultas ──
  final ModulePermission consultas;

  // ── Usuarios ──
  final ModulePermission usuarios;

  const UserPermissions({
    this.cintas = const ModulePermission.none(),
    this.variedades = const ModulePermission.none(),
    this.fincas = const ModulePermission.none(),
    this.lotes = const ModulePermission.none(),
    this.siembra = const ModulePermission.none(),
    this.encintado = const ModulePermission.none(),
    this.cosecha = const ModulePermission.none(),
    this.consultas = const ModulePermission.none(),
    this.usuarios = const ModulePermission.none(),
  });

  /// Acceso total (para el dueño de la empresa)
  const UserPermissions.owner()
    : cintas = const ModulePermission.all(),
      variedades = const ModulePermission.all(),
      fincas = const ModulePermission.all(),
      lotes = const ModulePermission.all(),
      siembra = const ModulePermission.all(),
      encintado = const ModulePermission.all(),
      cosecha = const ModulePermission.all(),
      consultas = const ModulePermission.readOnly(),
      usuarios = const ModulePermission.all();

  /// Sin acceso (default para empleado nuevo)
  const UserPermissions.none()
    : cintas = const ModulePermission.none(),
      variedades = const ModulePermission.none(),
      fincas = const ModulePermission.none(),
      lotes = const ModulePermission.none(),
      siembra = const ModulePermission.none(),
      encintado = const ModulePermission.none(),
      cosecha = const ModulePermission.none(),
      consultas = const ModulePermission.none(),
      usuarios = const ModulePermission.none();

  // ── Helpers para saber si mostrar botones de módulo padre ──

  /// ¿Tiene acceso a al menos una sub-vista de Administración?
  bool get tieneAdministracion =>
      cintas.tieneAcceso ||
      variedades.tieneAcceso ||
      fincas.tieneAcceso ||
      lotes.tieneAcceso;

  /// ¿Tiene acceso a al menos una sub-vista de Producción?
  bool get tieneProduccion =>
      siembra.tieneAcceso || encintado.tieneAcceso || cosecha.tieneAcceso;

  /// ¿Tiene acceso a Consultas?
  bool get tieneConsultas => consultas.tieneAcceso;

  /// ¿Tiene acceso a Usuarios?
  bool get tieneUsuarios => usuarios.tieneAcceso;

  UserPermissions copyWith({
    ModulePermission? cintas,
    ModulePermission? variedades,
    ModulePermission? fincas,
    ModulePermission? lotes,
    ModulePermission? siembra,
    ModulePermission? encintado,
    ModulePermission? cosecha,
    ModulePermission? consultas,
    ModulePermission? usuarios,
  }) {
    return UserPermissions(
      cintas: cintas ?? this.cintas,
      variedades: variedades ?? this.variedades,
      fincas: fincas ?? this.fincas,
      lotes: lotes ?? this.lotes,
      siembra: siembra ?? this.siembra,
      encintado: encintado ?? this.encintado,
      cosecha: cosecha ?? this.cosecha,
      consultas: consultas ?? this.consultas,
      usuarios: usuarios ?? this.usuarios,
    );
  }

  Map<String, dynamic> toJson() => {
    'cintas': cintas.toJson(),
    'variedades': variedades.toJson(),
    'fincas': fincas.toJson(),
    'lotes': lotes.toJson(),
    'siembra': siembra.toJson(),
    'encintado': encintado.toJson(),
    'cosecha': cosecha.toJson(),
    'consultas': consultas.toJson(),
    'usuarios': usuarios.toJson(),
  };

  factory UserPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPermissions.none();
    return UserPermissions(
      cintas: ModulePermission.fromJson(
        json['cintas'] as Map<String, dynamic>?,
      ),
      variedades: ModulePermission.fromJson(
        json['variedades'] as Map<String, dynamic>?,
      ),
      fincas: ModulePermission.fromJson(
        json['fincas'] as Map<String, dynamic>?,
      ),
      lotes: ModulePermission.fromJson(json['lotes'] as Map<String, dynamic>?),
      siembra: ModulePermission.fromJson(
        json['siembra'] as Map<String, dynamic>?,
      ),
      encintado: ModulePermission.fromJson(
        json['encintado'] as Map<String, dynamic>?,
      ),
      cosecha: ModulePermission.fromJson(
        json['cosecha'] as Map<String, dynamic>?,
      ),
      consultas: ModulePermission.fromJson(
        json['consultas'] as Map<String, dynamic>?,
      ),
      usuarios: ModulePermission.fromJson(
        json['usuarios'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [
    cintas,
    variedades,
    fincas,
    lotes,
    siembra,
    encintado,
    cosecha,
    consultas,
    usuarios,
  ];
}
