// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DerbysTable extends Derbys with TableInfo<$DerbysTable, Derby> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DerbysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaCreacionMeta = const VerificationMeta(
    'fechaCreacion',
  );
  @override
  late final GeneratedColumn<DateTime> fechaCreacion =
      GeneratedColumn<DateTime>(
        'fecha_creacion',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _rondasTotalesMeta = const VerificationMeta(
    'rondasTotales',
  );
  @override
  late final GeneratedColumn<int> rondasTotales = GeneratedColumn<int>(
    'rondas_totales',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _puntosVictoriaMeta = const VerificationMeta(
    'puntosVictoria',
  );
  @override
  late final GeneratedColumn<int> puntosVictoria = GeneratedColumn<int>(
    'puntos_victoria',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _puntosEmpateMeta = const VerificationMeta(
    'puntosEmpate',
  );
  @override
  late final GeneratedColumn<int> puntosEmpate = GeneratedColumn<int>(
    'puntos_empate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _puntosDerrotaMeta = const VerificationMeta(
    'puntosDerrota',
  );
  @override
  late final GeneratedColumn<int> puntosDerrota = GeneratedColumn<int>(
    'puntos_derrota',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _posicionesPremioMeta = const VerificationMeta(
    'posicionesPremio',
  );
  @override
  late final GeneratedColumn<int> posicionesPremio = GeneratedColumn<int>(
    'posiciones_premio',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('configuracion'),
  );
  static const VerificationMeta _pesoMinimoMeta = const VerificationMeta(
    'pesoMinimo',
  );
  @override
  late final GeneratedColumn<double> pesoMinimo = GeneratedColumn<double>(
    'peso_minimo',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1800.0),
  );
  static const VerificationMeta _pesoMaximoMeta = const VerificationMeta(
    'pesoMaximo',
  );
  @override
  late final GeneratedColumn<double> pesoMaximo = GeneratedColumn<double>(
    'peso_maximo',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2500.0),
  );
  static const VerificationMeta _pesoGalloBaseMeta = const VerificationMeta(
    'pesoGalloBase',
  );
  @override
  late final GeneratedColumn<double> pesoGalloBase = GeneratedColumn<double>(
    'peso_gallo_base',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _permitirRepeticionesMeta =
      const VerificationMeta('permitirRepeticiones');
  @override
  late final GeneratedColumn<bool> permitirRepeticiones = GeneratedColumn<bool>(
    'permitir_repeticiones',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("permitir_repeticiones" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _diferenciaMaxPesoMeta = const VerificationMeta(
    'diferenciaMaxPeso',
  );
  @override
  late final GeneratedColumn<double> diferenciaMaxPeso =
      GeneratedColumn<double>(
        'diferencia_max_peso',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(80.0),
      );
  static const VerificationMeta _validacionEstrictaMeta =
      const VerificationMeta('validacionEstricta');
  @override
  late final GeneratedColumn<bool> validacionEstricta = GeneratedColumn<bool>(
    'validacion_estricta',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("validacion_estricta" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    fechaCreacion,
    rondasTotales,
    puntosVictoria,
    puntosEmpate,
    puntosDerrota,
    posicionesPremio,
    estado,
    pesoMinimo,
    pesoMaximo,
    pesoGalloBase,
    permitirRepeticiones,
    diferenciaMaxPeso,
    validacionEstricta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'derbys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Derby> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('fecha_creacion')) {
      context.handle(
        _fechaCreacionMeta,
        fechaCreacion.isAcceptableOrUnknown(
          data['fecha_creacion']!,
          _fechaCreacionMeta,
        ),
      );
    }
    if (data.containsKey('rondas_totales')) {
      context.handle(
        _rondasTotalesMeta,
        rondasTotales.isAcceptableOrUnknown(
          data['rondas_totales']!,
          _rondasTotalesMeta,
        ),
      );
    }
    if (data.containsKey('puntos_victoria')) {
      context.handle(
        _puntosVictoriaMeta,
        puntosVictoria.isAcceptableOrUnknown(
          data['puntos_victoria']!,
          _puntosVictoriaMeta,
        ),
      );
    }
    if (data.containsKey('puntos_empate')) {
      context.handle(
        _puntosEmpateMeta,
        puntosEmpate.isAcceptableOrUnknown(
          data['puntos_empate']!,
          _puntosEmpateMeta,
        ),
      );
    }
    if (data.containsKey('puntos_derrota')) {
      context.handle(
        _puntosDerrotaMeta,
        puntosDerrota.isAcceptableOrUnknown(
          data['puntos_derrota']!,
          _puntosDerrotaMeta,
        ),
      );
    }
    if (data.containsKey('posiciones_premio')) {
      context.handle(
        _posicionesPremioMeta,
        posicionesPremio.isAcceptableOrUnknown(
          data['posiciones_premio']!,
          _posicionesPremioMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('peso_minimo')) {
      context.handle(
        _pesoMinimoMeta,
        pesoMinimo.isAcceptableOrUnknown(data['peso_minimo']!, _pesoMinimoMeta),
      );
    }
    if (data.containsKey('peso_maximo')) {
      context.handle(
        _pesoMaximoMeta,
        pesoMaximo.isAcceptableOrUnknown(data['peso_maximo']!, _pesoMaximoMeta),
      );
    }
    if (data.containsKey('peso_gallo_base')) {
      context.handle(
        _pesoGalloBaseMeta,
        pesoGalloBase.isAcceptableOrUnknown(
          data['peso_gallo_base']!,
          _pesoGalloBaseMeta,
        ),
      );
    }
    if (data.containsKey('permitir_repeticiones')) {
      context.handle(
        _permitirRepeticionesMeta,
        permitirRepeticiones.isAcceptableOrUnknown(
          data['permitir_repeticiones']!,
          _permitirRepeticionesMeta,
        ),
      );
    }
    if (data.containsKey('diferencia_max_peso')) {
      context.handle(
        _diferenciaMaxPesoMeta,
        diferenciaMaxPeso.isAcceptableOrUnknown(
          data['diferencia_max_peso']!,
          _diferenciaMaxPesoMeta,
        ),
      );
    }
    if (data.containsKey('validacion_estricta')) {
      context.handle(
        _validacionEstrictaMeta,
        validacionEstricta.isAcceptableOrUnknown(
          data['validacion_estricta']!,
          _validacionEstrictaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Derby map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Derby(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      fechaCreacion: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_creacion'],
      )!,
      rondasTotales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rondas_totales'],
      )!,
      puntosVictoria: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puntos_victoria'],
      )!,
      puntosEmpate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puntos_empate'],
      )!,
      puntosDerrota: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puntos_derrota'],
      )!,
      posicionesPremio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posiciones_premio'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      pesoMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_minimo'],
      )!,
      pesoMaximo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_maximo'],
      )!,
      pesoGalloBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_gallo_base'],
      )!,
      permitirRepeticiones: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}permitir_repeticiones'],
      )!,
      diferenciaMaxPeso: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diferencia_max_peso'],
      )!,
      validacionEstricta: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}validacion_estricta'],
      )!,
    );
  }

  @override
  $DerbysTable createAlias(String alias) {
    return $DerbysTable(attachedDatabase, alias);
  }
}

class Derby extends DataClass implements Insertable<Derby> {
  final int id;
  final String nombre;
  final DateTime fechaCreacion;
  final int rondasTotales;
  final int puntosVictoria;
  final int puntosEmpate;
  final int puntosDerrota;
  final int posicionesPremio;
  final String estado;

  /// Peso mínimo aceptado para gallos P.L. (gramos).
  final double pesoMinimo;

  /// Peso máximo aceptado para gallos P.L. (gramos).
  final double pesoMaximo;

  /// Peso específico del gallo base (gramos). 0 = sin restricción.
  final double pesoGalloBase;

  /// En derbys de peso libre, ¿se pueden repetir contrincantes?
  final bool permitirRepeticiones;

  /// Diferencia máxima de peso permitida en peleas P.L. (gramos). 0 = sin límite.
  final double diferenciaMaxPeso;

  /// Validación estricta: si true, lanza error si no hay solución completa.
  final bool validacionEstricta;
  const Derby({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
    required this.rondasTotales,
    required this.puntosVictoria,
    required this.puntosEmpate,
    required this.puntosDerrota,
    required this.posicionesPremio,
    required this.estado,
    required this.pesoMinimo,
    required this.pesoMaximo,
    required this.pesoGalloBase,
    required this.permitirRepeticiones,
    required this.diferenciaMaxPeso,
    required this.validacionEstricta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['fecha_creacion'] = Variable<DateTime>(fechaCreacion);
    map['rondas_totales'] = Variable<int>(rondasTotales);
    map['puntos_victoria'] = Variable<int>(puntosVictoria);
    map['puntos_empate'] = Variable<int>(puntosEmpate);
    map['puntos_derrota'] = Variable<int>(puntosDerrota);
    map['posiciones_premio'] = Variable<int>(posicionesPremio);
    map['estado'] = Variable<String>(estado);
    map['peso_minimo'] = Variable<double>(pesoMinimo);
    map['peso_maximo'] = Variable<double>(pesoMaximo);
    map['peso_gallo_base'] = Variable<double>(pesoGalloBase);
    map['permitir_repeticiones'] = Variable<bool>(permitirRepeticiones);
    map['diferencia_max_peso'] = Variable<double>(diferenciaMaxPeso);
    map['validacion_estricta'] = Variable<bool>(validacionEstricta);
    return map;
  }

  DerbysCompanion toCompanion(bool nullToAbsent) {
    return DerbysCompanion(
      id: Value(id),
      nombre: Value(nombre),
      fechaCreacion: Value(fechaCreacion),
      rondasTotales: Value(rondasTotales),
      puntosVictoria: Value(puntosVictoria),
      puntosEmpate: Value(puntosEmpate),
      puntosDerrota: Value(puntosDerrota),
      posicionesPremio: Value(posicionesPremio),
      estado: Value(estado),
      pesoMinimo: Value(pesoMinimo),
      pesoMaximo: Value(pesoMaximo),
      pesoGalloBase: Value(pesoGalloBase),
      permitirRepeticiones: Value(permitirRepeticiones),
      diferenciaMaxPeso: Value(diferenciaMaxPeso),
      validacionEstricta: Value(validacionEstricta),
    );
  }

  factory Derby.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Derby(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      fechaCreacion: serializer.fromJson<DateTime>(json['fechaCreacion']),
      rondasTotales: serializer.fromJson<int>(json['rondasTotales']),
      puntosVictoria: serializer.fromJson<int>(json['puntosVictoria']),
      puntosEmpate: serializer.fromJson<int>(json['puntosEmpate']),
      puntosDerrota: serializer.fromJson<int>(json['puntosDerrota']),
      posicionesPremio: serializer.fromJson<int>(json['posicionesPremio']),
      estado: serializer.fromJson<String>(json['estado']),
      pesoMinimo: serializer.fromJson<double>(json['pesoMinimo']),
      pesoMaximo: serializer.fromJson<double>(json['pesoMaximo']),
      pesoGalloBase: serializer.fromJson<double>(json['pesoGalloBase']),
      permitirRepeticiones: serializer.fromJson<bool>(
        json['permitirRepeticiones'],
      ),
      diferenciaMaxPeso: serializer.fromJson<double>(json['diferenciaMaxPeso']),
      validacionEstricta: serializer.fromJson<bool>(json['validacionEstricta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'fechaCreacion': serializer.toJson<DateTime>(fechaCreacion),
      'rondasTotales': serializer.toJson<int>(rondasTotales),
      'puntosVictoria': serializer.toJson<int>(puntosVictoria),
      'puntosEmpate': serializer.toJson<int>(puntosEmpate),
      'puntosDerrota': serializer.toJson<int>(puntosDerrota),
      'posicionesPremio': serializer.toJson<int>(posicionesPremio),
      'estado': serializer.toJson<String>(estado),
      'pesoMinimo': serializer.toJson<double>(pesoMinimo),
      'pesoMaximo': serializer.toJson<double>(pesoMaximo),
      'pesoGalloBase': serializer.toJson<double>(pesoGalloBase),
      'permitirRepeticiones': serializer.toJson<bool>(permitirRepeticiones),
      'diferenciaMaxPeso': serializer.toJson<double>(diferenciaMaxPeso),
      'validacionEstricta': serializer.toJson<bool>(validacionEstricta),
    };
  }

  Derby copyWith({
    int? id,
    String? nombre,
    DateTime? fechaCreacion,
    int? rondasTotales,
    int? puntosVictoria,
    int? puntosEmpate,
    int? puntosDerrota,
    int? posicionesPremio,
    String? estado,
    double? pesoMinimo,
    double? pesoMaximo,
    double? pesoGalloBase,
    bool? permitirRepeticiones,
    double? diferenciaMaxPeso,
    bool? validacionEstricta,
  }) => Derby(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    rondasTotales: rondasTotales ?? this.rondasTotales,
    puntosVictoria: puntosVictoria ?? this.puntosVictoria,
    puntosEmpate: puntosEmpate ?? this.puntosEmpate,
    puntosDerrota: puntosDerrota ?? this.puntosDerrota,
    posicionesPremio: posicionesPremio ?? this.posicionesPremio,
    estado: estado ?? this.estado,
    pesoMinimo: pesoMinimo ?? this.pesoMinimo,
    pesoMaximo: pesoMaximo ?? this.pesoMaximo,
    pesoGalloBase: pesoGalloBase ?? this.pesoGalloBase,
    permitirRepeticiones: permitirRepeticiones ?? this.permitirRepeticiones,
    diferenciaMaxPeso: diferenciaMaxPeso ?? this.diferenciaMaxPeso,
    validacionEstricta: validacionEstricta ?? this.validacionEstricta,
  );
  Derby copyWithCompanion(DerbysCompanion data) {
    return Derby(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      fechaCreacion: data.fechaCreacion.present
          ? data.fechaCreacion.value
          : this.fechaCreacion,
      rondasTotales: data.rondasTotales.present
          ? data.rondasTotales.value
          : this.rondasTotales,
      puntosVictoria: data.puntosVictoria.present
          ? data.puntosVictoria.value
          : this.puntosVictoria,
      puntosEmpate: data.puntosEmpate.present
          ? data.puntosEmpate.value
          : this.puntosEmpate,
      puntosDerrota: data.puntosDerrota.present
          ? data.puntosDerrota.value
          : this.puntosDerrota,
      posicionesPremio: data.posicionesPremio.present
          ? data.posicionesPremio.value
          : this.posicionesPremio,
      estado: data.estado.present ? data.estado.value : this.estado,
      pesoMinimo: data.pesoMinimo.present
          ? data.pesoMinimo.value
          : this.pesoMinimo,
      pesoMaximo: data.pesoMaximo.present
          ? data.pesoMaximo.value
          : this.pesoMaximo,
      pesoGalloBase: data.pesoGalloBase.present
          ? data.pesoGalloBase.value
          : this.pesoGalloBase,
      permitirRepeticiones: data.permitirRepeticiones.present
          ? data.permitirRepeticiones.value
          : this.permitirRepeticiones,
      diferenciaMaxPeso: data.diferenciaMaxPeso.present
          ? data.diferenciaMaxPeso.value
          : this.diferenciaMaxPeso,
      validacionEstricta: data.validacionEstricta.present
          ? data.validacionEstricta.value
          : this.validacionEstricta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Derby(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('rondasTotales: $rondasTotales, ')
          ..write('puntosVictoria: $puntosVictoria, ')
          ..write('puntosEmpate: $puntosEmpate, ')
          ..write('puntosDerrota: $puntosDerrota, ')
          ..write('posicionesPremio: $posicionesPremio, ')
          ..write('estado: $estado, ')
          ..write('pesoMinimo: $pesoMinimo, ')
          ..write('pesoMaximo: $pesoMaximo, ')
          ..write('pesoGalloBase: $pesoGalloBase, ')
          ..write('permitirRepeticiones: $permitirRepeticiones, ')
          ..write('diferenciaMaxPeso: $diferenciaMaxPeso, ')
          ..write('validacionEstricta: $validacionEstricta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    fechaCreacion,
    rondasTotales,
    puntosVictoria,
    puntosEmpate,
    puntosDerrota,
    posicionesPremio,
    estado,
    pesoMinimo,
    pesoMaximo,
    pesoGalloBase,
    permitirRepeticiones,
    diferenciaMaxPeso,
    validacionEstricta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Derby &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.fechaCreacion == this.fechaCreacion &&
          other.rondasTotales == this.rondasTotales &&
          other.puntosVictoria == this.puntosVictoria &&
          other.puntosEmpate == this.puntosEmpate &&
          other.puntosDerrota == this.puntosDerrota &&
          other.posicionesPremio == this.posicionesPremio &&
          other.estado == this.estado &&
          other.pesoMinimo == this.pesoMinimo &&
          other.pesoMaximo == this.pesoMaximo &&
          other.pesoGalloBase == this.pesoGalloBase &&
          other.permitirRepeticiones == this.permitirRepeticiones &&
          other.diferenciaMaxPeso == this.diferenciaMaxPeso &&
          other.validacionEstricta == this.validacionEstricta);
}

class DerbysCompanion extends UpdateCompanion<Derby> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<DateTime> fechaCreacion;
  final Value<int> rondasTotales;
  final Value<int> puntosVictoria;
  final Value<int> puntosEmpate;
  final Value<int> puntosDerrota;
  final Value<int> posicionesPremio;
  final Value<String> estado;
  final Value<double> pesoMinimo;
  final Value<double> pesoMaximo;
  final Value<double> pesoGalloBase;
  final Value<bool> permitirRepeticiones;
  final Value<double> diferenciaMaxPeso;
  final Value<bool> validacionEstricta;
  const DerbysCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.rondasTotales = const Value.absent(),
    this.puntosVictoria = const Value.absent(),
    this.puntosEmpate = const Value.absent(),
    this.puntosDerrota = const Value.absent(),
    this.posicionesPremio = const Value.absent(),
    this.estado = const Value.absent(),
    this.pesoMinimo = const Value.absent(),
    this.pesoMaximo = const Value.absent(),
    this.pesoGalloBase = const Value.absent(),
    this.permitirRepeticiones = const Value.absent(),
    this.diferenciaMaxPeso = const Value.absent(),
    this.validacionEstricta = const Value.absent(),
  });
  DerbysCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    this.fechaCreacion = const Value.absent(),
    this.rondasTotales = const Value.absent(),
    this.puntosVictoria = const Value.absent(),
    this.puntosEmpate = const Value.absent(),
    this.puntosDerrota = const Value.absent(),
    this.posicionesPremio = const Value.absent(),
    this.estado = const Value.absent(),
    this.pesoMinimo = const Value.absent(),
    this.pesoMaximo = const Value.absent(),
    this.pesoGalloBase = const Value.absent(),
    this.permitirRepeticiones = const Value.absent(),
    this.diferenciaMaxPeso = const Value.absent(),
    this.validacionEstricta = const Value.absent(),
  }) : nombre = Value(nombre);
  static Insertable<Derby> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<DateTime>? fechaCreacion,
    Expression<int>? rondasTotales,
    Expression<int>? puntosVictoria,
    Expression<int>? puntosEmpate,
    Expression<int>? puntosDerrota,
    Expression<int>? posicionesPremio,
    Expression<String>? estado,
    Expression<double>? pesoMinimo,
    Expression<double>? pesoMaximo,
    Expression<double>? pesoGalloBase,
    Expression<bool>? permitirRepeticiones,
    Expression<double>? diferenciaMaxPeso,
    Expression<bool>? validacionEstricta,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion,
      if (rondasTotales != null) 'rondas_totales': rondasTotales,
      if (puntosVictoria != null) 'puntos_victoria': puntosVictoria,
      if (puntosEmpate != null) 'puntos_empate': puntosEmpate,
      if (puntosDerrota != null) 'puntos_derrota': puntosDerrota,
      if (posicionesPremio != null) 'posiciones_premio': posicionesPremio,
      if (estado != null) 'estado': estado,
      if (pesoMinimo != null) 'peso_minimo': pesoMinimo,
      if (pesoMaximo != null) 'peso_maximo': pesoMaximo,
      if (pesoGalloBase != null) 'peso_gallo_base': pesoGalloBase,
      if (permitirRepeticiones != null)
        'permitir_repeticiones': permitirRepeticiones,
      if (diferenciaMaxPeso != null) 'diferencia_max_peso': diferenciaMaxPeso,
      if (validacionEstricta != null) 'validacion_estricta': validacionEstricta,
    });
  }

  DerbysCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<DateTime>? fechaCreacion,
    Value<int>? rondasTotales,
    Value<int>? puntosVictoria,
    Value<int>? puntosEmpate,
    Value<int>? puntosDerrota,
    Value<int>? posicionesPremio,
    Value<String>? estado,
    Value<double>? pesoMinimo,
    Value<double>? pesoMaximo,
    Value<double>? pesoGalloBase,
    Value<bool>? permitirRepeticiones,
    Value<double>? diferenciaMaxPeso,
    Value<bool>? validacionEstricta,
  }) {
    return DerbysCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      rondasTotales: rondasTotales ?? this.rondasTotales,
      puntosVictoria: puntosVictoria ?? this.puntosVictoria,
      puntosEmpate: puntosEmpate ?? this.puntosEmpate,
      puntosDerrota: puntosDerrota ?? this.puntosDerrota,
      posicionesPremio: posicionesPremio ?? this.posicionesPremio,
      estado: estado ?? this.estado,
      pesoMinimo: pesoMinimo ?? this.pesoMinimo,
      pesoMaximo: pesoMaximo ?? this.pesoMaximo,
      pesoGalloBase: pesoGalloBase ?? this.pesoGalloBase,
      permitirRepeticiones: permitirRepeticiones ?? this.permitirRepeticiones,
      diferenciaMaxPeso: diferenciaMaxPeso ?? this.diferenciaMaxPeso,
      validacionEstricta: validacionEstricta ?? this.validacionEstricta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (fechaCreacion.present) {
      map['fecha_creacion'] = Variable<DateTime>(fechaCreacion.value);
    }
    if (rondasTotales.present) {
      map['rondas_totales'] = Variable<int>(rondasTotales.value);
    }
    if (puntosVictoria.present) {
      map['puntos_victoria'] = Variable<int>(puntosVictoria.value);
    }
    if (puntosEmpate.present) {
      map['puntos_empate'] = Variable<int>(puntosEmpate.value);
    }
    if (puntosDerrota.present) {
      map['puntos_derrota'] = Variable<int>(puntosDerrota.value);
    }
    if (posicionesPremio.present) {
      map['posiciones_premio'] = Variable<int>(posicionesPremio.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (pesoMinimo.present) {
      map['peso_minimo'] = Variable<double>(pesoMinimo.value);
    }
    if (pesoMaximo.present) {
      map['peso_maximo'] = Variable<double>(pesoMaximo.value);
    }
    if (pesoGalloBase.present) {
      map['peso_gallo_base'] = Variable<double>(pesoGalloBase.value);
    }
    if (permitirRepeticiones.present) {
      map['permitir_repeticiones'] = Variable<bool>(permitirRepeticiones.value);
    }
    if (diferenciaMaxPeso.present) {
      map['diferencia_max_peso'] = Variable<double>(diferenciaMaxPeso.value);
    }
    if (validacionEstricta.present) {
      map['validacion_estricta'] = Variable<bool>(validacionEstricta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DerbysCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('rondasTotales: $rondasTotales, ')
          ..write('puntosVictoria: $puntosVictoria, ')
          ..write('puntosEmpate: $puntosEmpate, ')
          ..write('puntosDerrota: $puntosDerrota, ')
          ..write('posicionesPremio: $posicionesPremio, ')
          ..write('estado: $estado, ')
          ..write('pesoMinimo: $pesoMinimo, ')
          ..write('pesoMaximo: $pesoMaximo, ')
          ..write('pesoGalloBase: $pesoGalloBase, ')
          ..write('permitirRepeticiones: $permitirRepeticiones, ')
          ..write('diferenciaMaxPeso: $diferenciaMaxPeso, ')
          ..write('validacionEstricta: $validacionEstricta')
          ..write(')'))
        .toString();
  }
}

class $PartidosTable extends Partidos with TableInfo<$PartidosTable, Partido> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartidosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _derbyIdMeta = const VerificationMeta(
    'derbyId',
  );
  @override
  late final GeneratedColumn<int> derbyId = GeneratedColumn<int>(
    'derby_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES derbys (id)',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responsableMeta = const VerificationMeta(
    'responsable',
  );
  @override
  late final GeneratedColumn<String> responsable = GeneratedColumn<String>(
    'responsable',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('activo'),
  );
  static const VerificationMeta _puntosMeta = const VerificationMeta('puntos');
  @override
  late final GeneratedColumn<int> puntos = GeneratedColumn<int>(
    'puntos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _eliminadoMeta = const VerificationMeta(
    'eliminado',
  );
  @override
  late final GeneratedColumn<bool> eliminado = GeneratedColumn<bool>(
    'eliminado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _depositoPagadoMeta = const VerificationMeta(
    'depositoPagado',
  );
  @override
  late final GeneratedColumn<bool> depositoPagado = GeneratedColumn<bool>(
    'deposito_pagado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deposito_pagado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _depositoCantidadMeta = const VerificationMeta(
    'depositoCantidad',
  );
  @override
  late final GeneratedColumn<double> depositoCantidad = GeneratedColumn<double>(
    'deposito_cantidad',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _esComodinMeta = const VerificationMeta(
    'esComodin',
  );
  @override
  late final GeneratedColumn<bool> esComodin = GeneratedColumn<bool>(
    'es_comodin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_comodin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    derbyId,
    nombre,
    responsable,
    telefono,
    estado,
    puntos,
    eliminado,
    depositoPagado,
    depositoCantidad,
    esComodin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'partidos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Partido> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('derby_id')) {
      context.handle(
        _derbyIdMeta,
        derbyId.isAcceptableOrUnknown(data['derby_id']!, _derbyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_derbyIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('responsable')) {
      context.handle(
        _responsableMeta,
        responsable.isAcceptableOrUnknown(
          data['responsable']!,
          _responsableMeta,
        ),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('puntos')) {
      context.handle(
        _puntosMeta,
        puntos.isAcceptableOrUnknown(data['puntos']!, _puntosMeta),
      );
    }
    if (data.containsKey('eliminado')) {
      context.handle(
        _eliminadoMeta,
        eliminado.isAcceptableOrUnknown(data['eliminado']!, _eliminadoMeta),
      );
    }
    if (data.containsKey('deposito_pagado')) {
      context.handle(
        _depositoPagadoMeta,
        depositoPagado.isAcceptableOrUnknown(
          data['deposito_pagado']!,
          _depositoPagadoMeta,
        ),
      );
    }
    if (data.containsKey('deposito_cantidad')) {
      context.handle(
        _depositoCantidadMeta,
        depositoCantidad.isAcceptableOrUnknown(
          data['deposito_cantidad']!,
          _depositoCantidadMeta,
        ),
      );
    }
    if (data.containsKey('es_comodin')) {
      context.handle(
        _esComodinMeta,
        esComodin.isAcceptableOrUnknown(data['es_comodin']!, _esComodinMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Partido map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Partido(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      derbyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}derby_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      responsable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responsable'],
      ),
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      puntos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puntos'],
      )!,
      eliminado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminado'],
      )!,
      depositoPagado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deposito_pagado'],
      )!,
      depositoCantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deposito_cantidad'],
      )!,
      esComodin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_comodin'],
      )!,
    );
  }

  @override
  $PartidosTable createAlias(String alias) {
    return $PartidosTable(attachedDatabase, alias);
  }
}

class Partido extends DataClass implements Insertable<Partido> {
  final int id;
  final int derbyId;
  final String nombre;
  final String? responsable;
  final String? telefono;
  final String estado;
  final int puntos;
  final bool eliminado;
  final bool depositoPagado;
  final double depositoCantidad;

  /// True si es un partido comodín (entra cuando hay impar post-eliminación).
  final bool esComodin;
  const Partido({
    required this.id,
    required this.derbyId,
    required this.nombre,
    this.responsable,
    this.telefono,
    required this.estado,
    required this.puntos,
    required this.eliminado,
    required this.depositoPagado,
    required this.depositoCantidad,
    required this.esComodin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['derby_id'] = Variable<int>(derbyId);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || responsable != null) {
      map['responsable'] = Variable<String>(responsable);
    }
    if (!nullToAbsent || telefono != null) {
      map['telefono'] = Variable<String>(telefono);
    }
    map['estado'] = Variable<String>(estado);
    map['puntos'] = Variable<int>(puntos);
    map['eliminado'] = Variable<bool>(eliminado);
    map['deposito_pagado'] = Variable<bool>(depositoPagado);
    map['deposito_cantidad'] = Variable<double>(depositoCantidad);
    map['es_comodin'] = Variable<bool>(esComodin);
    return map;
  }

  PartidosCompanion toCompanion(bool nullToAbsent) {
    return PartidosCompanion(
      id: Value(id),
      derbyId: Value(derbyId),
      nombre: Value(nombre),
      responsable: responsable == null && nullToAbsent
          ? const Value.absent()
          : Value(responsable),
      telefono: telefono == null && nullToAbsent
          ? const Value.absent()
          : Value(telefono),
      estado: Value(estado),
      puntos: Value(puntos),
      eliminado: Value(eliminado),
      depositoPagado: Value(depositoPagado),
      depositoCantidad: Value(depositoCantidad),
      esComodin: Value(esComodin),
    );
  }

  factory Partido.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Partido(
      id: serializer.fromJson<int>(json['id']),
      derbyId: serializer.fromJson<int>(json['derbyId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      responsable: serializer.fromJson<String?>(json['responsable']),
      telefono: serializer.fromJson<String?>(json['telefono']),
      estado: serializer.fromJson<String>(json['estado']),
      puntos: serializer.fromJson<int>(json['puntos']),
      eliminado: serializer.fromJson<bool>(json['eliminado']),
      depositoPagado: serializer.fromJson<bool>(json['depositoPagado']),
      depositoCantidad: serializer.fromJson<double>(json['depositoCantidad']),
      esComodin: serializer.fromJson<bool>(json['esComodin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'derbyId': serializer.toJson<int>(derbyId),
      'nombre': serializer.toJson<String>(nombre),
      'responsable': serializer.toJson<String?>(responsable),
      'telefono': serializer.toJson<String?>(telefono),
      'estado': serializer.toJson<String>(estado),
      'puntos': serializer.toJson<int>(puntos),
      'eliminado': serializer.toJson<bool>(eliminado),
      'depositoPagado': serializer.toJson<bool>(depositoPagado),
      'depositoCantidad': serializer.toJson<double>(depositoCantidad),
      'esComodin': serializer.toJson<bool>(esComodin),
    };
  }

  Partido copyWith({
    int? id,
    int? derbyId,
    String? nombre,
    Value<String?> responsable = const Value.absent(),
    Value<String?> telefono = const Value.absent(),
    String? estado,
    int? puntos,
    bool? eliminado,
    bool? depositoPagado,
    double? depositoCantidad,
    bool? esComodin,
  }) => Partido(
    id: id ?? this.id,
    derbyId: derbyId ?? this.derbyId,
    nombre: nombre ?? this.nombre,
    responsable: responsable.present ? responsable.value : this.responsable,
    telefono: telefono.present ? telefono.value : this.telefono,
    estado: estado ?? this.estado,
    puntos: puntos ?? this.puntos,
    eliminado: eliminado ?? this.eliminado,
    depositoPagado: depositoPagado ?? this.depositoPagado,
    depositoCantidad: depositoCantidad ?? this.depositoCantidad,
    esComodin: esComodin ?? this.esComodin,
  );
  Partido copyWithCompanion(PartidosCompanion data) {
    return Partido(
      id: data.id.present ? data.id.value : this.id,
      derbyId: data.derbyId.present ? data.derbyId.value : this.derbyId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      responsable: data.responsable.present
          ? data.responsable.value
          : this.responsable,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      estado: data.estado.present ? data.estado.value : this.estado,
      puntos: data.puntos.present ? data.puntos.value : this.puntos,
      eliminado: data.eliminado.present ? data.eliminado.value : this.eliminado,
      depositoPagado: data.depositoPagado.present
          ? data.depositoPagado.value
          : this.depositoPagado,
      depositoCantidad: data.depositoCantidad.present
          ? data.depositoCantidad.value
          : this.depositoCantidad,
      esComodin: data.esComodin.present ? data.esComodin.value : this.esComodin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Partido(')
          ..write('id: $id, ')
          ..write('derbyId: $derbyId, ')
          ..write('nombre: $nombre, ')
          ..write('responsable: $responsable, ')
          ..write('telefono: $telefono, ')
          ..write('estado: $estado, ')
          ..write('puntos: $puntos, ')
          ..write('eliminado: $eliminado, ')
          ..write('depositoPagado: $depositoPagado, ')
          ..write('depositoCantidad: $depositoCantidad, ')
          ..write('esComodin: $esComodin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    derbyId,
    nombre,
    responsable,
    telefono,
    estado,
    puntos,
    eliminado,
    depositoPagado,
    depositoCantidad,
    esComodin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Partido &&
          other.id == this.id &&
          other.derbyId == this.derbyId &&
          other.nombre == this.nombre &&
          other.responsable == this.responsable &&
          other.telefono == this.telefono &&
          other.estado == this.estado &&
          other.puntos == this.puntos &&
          other.eliminado == this.eliminado &&
          other.depositoPagado == this.depositoPagado &&
          other.depositoCantidad == this.depositoCantidad &&
          other.esComodin == this.esComodin);
}

class PartidosCompanion extends UpdateCompanion<Partido> {
  final Value<int> id;
  final Value<int> derbyId;
  final Value<String> nombre;
  final Value<String?> responsable;
  final Value<String?> telefono;
  final Value<String> estado;
  final Value<int> puntos;
  final Value<bool> eliminado;
  final Value<bool> depositoPagado;
  final Value<double> depositoCantidad;
  final Value<bool> esComodin;
  const PartidosCompanion({
    this.id = const Value.absent(),
    this.derbyId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.responsable = const Value.absent(),
    this.telefono = const Value.absent(),
    this.estado = const Value.absent(),
    this.puntos = const Value.absent(),
    this.eliminado = const Value.absent(),
    this.depositoPagado = const Value.absent(),
    this.depositoCantidad = const Value.absent(),
    this.esComodin = const Value.absent(),
  });
  PartidosCompanion.insert({
    this.id = const Value.absent(),
    required int derbyId,
    required String nombre,
    this.responsable = const Value.absent(),
    this.telefono = const Value.absent(),
    this.estado = const Value.absent(),
    this.puntos = const Value.absent(),
    this.eliminado = const Value.absent(),
    this.depositoPagado = const Value.absent(),
    this.depositoCantidad = const Value.absent(),
    this.esComodin = const Value.absent(),
  }) : derbyId = Value(derbyId),
       nombre = Value(nombre);
  static Insertable<Partido> custom({
    Expression<int>? id,
    Expression<int>? derbyId,
    Expression<String>? nombre,
    Expression<String>? responsable,
    Expression<String>? telefono,
    Expression<String>? estado,
    Expression<int>? puntos,
    Expression<bool>? eliminado,
    Expression<bool>? depositoPagado,
    Expression<double>? depositoCantidad,
    Expression<bool>? esComodin,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (derbyId != null) 'derby_id': derbyId,
      if (nombre != null) 'nombre': nombre,
      if (responsable != null) 'responsable': responsable,
      if (telefono != null) 'telefono': telefono,
      if (estado != null) 'estado': estado,
      if (puntos != null) 'puntos': puntos,
      if (eliminado != null) 'eliminado': eliminado,
      if (depositoPagado != null) 'deposito_pagado': depositoPagado,
      if (depositoCantidad != null) 'deposito_cantidad': depositoCantidad,
      if (esComodin != null) 'es_comodin': esComodin,
    });
  }

  PartidosCompanion copyWith({
    Value<int>? id,
    Value<int>? derbyId,
    Value<String>? nombre,
    Value<String?>? responsable,
    Value<String?>? telefono,
    Value<String>? estado,
    Value<int>? puntos,
    Value<bool>? eliminado,
    Value<bool>? depositoPagado,
    Value<double>? depositoCantidad,
    Value<bool>? esComodin,
  }) {
    return PartidosCompanion(
      id: id ?? this.id,
      derbyId: derbyId ?? this.derbyId,
      nombre: nombre ?? this.nombre,
      responsable: responsable ?? this.responsable,
      telefono: telefono ?? this.telefono,
      estado: estado ?? this.estado,
      puntos: puntos ?? this.puntos,
      eliminado: eliminado ?? this.eliminado,
      depositoPagado: depositoPagado ?? this.depositoPagado,
      depositoCantidad: depositoCantidad ?? this.depositoCantidad,
      esComodin: esComodin ?? this.esComodin,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (derbyId.present) {
      map['derby_id'] = Variable<int>(derbyId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (responsable.present) {
      map['responsable'] = Variable<String>(responsable.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (puntos.present) {
      map['puntos'] = Variable<int>(puntos.value);
    }
    if (eliminado.present) {
      map['eliminado'] = Variable<bool>(eliminado.value);
    }
    if (depositoPagado.present) {
      map['deposito_pagado'] = Variable<bool>(depositoPagado.value);
    }
    if (depositoCantidad.present) {
      map['deposito_cantidad'] = Variable<double>(depositoCantidad.value);
    }
    if (esComodin.present) {
      map['es_comodin'] = Variable<bool>(esComodin.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartidosCompanion(')
          ..write('id: $id, ')
          ..write('derbyId: $derbyId, ')
          ..write('nombre: $nombre, ')
          ..write('responsable: $responsable, ')
          ..write('telefono: $telefono, ')
          ..write('estado: $estado, ')
          ..write('puntos: $puntos, ')
          ..write('eliminado: $eliminado, ')
          ..write('depositoPagado: $depositoPagado, ')
          ..write('depositoCantidad: $depositoCantidad, ')
          ..write('esComodin: $esComodin')
          ..write(')'))
        .toString();
  }
}

class $GallosTable extends Gallos with TableInfo<$GallosTable, GalloEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GallosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _partidoIdMeta = const VerificationMeta(
    'partidoId',
  );
  @override
  late final GeneratedColumn<int> partidoId = GeneratedColumn<int>(
    'partido_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES partidos (id)',
    ),
  );
  static const VerificationMeta _anilloMeta = const VerificationMeta('anillo');
  @override
  late final GeneratedColumn<String> anillo = GeneratedColumn<String>(
    'anillo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _pesoGramosMeta = const VerificationMeta(
    'pesoGramos',
  );
  @override
  late final GeneratedColumn<double> pesoGramos = GeneratedColumn<double>(
    'peso_gramos',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _esBaseMeta = const VerificationMeta('esBase');
  @override
  late final GeneratedColumn<bool> esBase = GeneratedColumn<bool>(
    'es_base',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_base" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacionesMeta = const VerificationMeta(
    'observaciones',
  );
  @override
  late final GeneratedColumn<String> observaciones = GeneratedColumn<String>(
    'observaciones',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    partidoId,
    anillo,
    pesoGramos,
    esBase,
    color,
    observaciones,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gallos';
  @override
  VerificationContext validateIntegrity(
    Insertable<GalloEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('partido_id')) {
      context.handle(
        _partidoIdMeta,
        partidoId.isAcceptableOrUnknown(data['partido_id']!, _partidoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partidoIdMeta);
    }
    if (data.containsKey('anillo')) {
      context.handle(
        _anilloMeta,
        anillo.isAcceptableOrUnknown(data['anillo']!, _anilloMeta),
      );
    } else if (isInserting) {
      context.missing(_anilloMeta);
    }
    if (data.containsKey('peso_gramos')) {
      context.handle(
        _pesoGramosMeta,
        pesoGramos.isAcceptableOrUnknown(data['peso_gramos']!, _pesoGramosMeta),
      );
    } else if (isInserting) {
      context.missing(_pesoGramosMeta);
    }
    if (data.containsKey('es_base')) {
      context.handle(
        _esBaseMeta,
        esBase.isAcceptableOrUnknown(data['es_base']!, _esBaseMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('observaciones')) {
      context.handle(
        _observacionesMeta,
        observaciones.isAcceptableOrUnknown(
          data['observaciones']!,
          _observacionesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GalloEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GalloEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      partidoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partido_id'],
      )!,
      anillo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anillo'],
      )!,
      pesoGramos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_gramos'],
      )!,
      esBase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_base'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      observaciones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observaciones'],
      ),
    );
  }

  @override
  $GallosTable createAlias(String alias) {
    return $GallosTable(attachedDatabase, alias);
  }
}

class GalloEntry extends DataClass implements Insertable<GalloEntry> {
  final int id;
  final int partidoId;
  final String anillo;
  final double pesoGramos;
  final bool esBase;
  final String? color;
  final String? observaciones;
  const GalloEntry({
    required this.id,
    required this.partidoId,
    required this.anillo,
    required this.pesoGramos,
    required this.esBase,
    this.color,
    this.observaciones,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['partido_id'] = Variable<int>(partidoId);
    map['anillo'] = Variable<String>(anillo);
    map['peso_gramos'] = Variable<double>(pesoGramos);
    map['es_base'] = Variable<bool>(esBase);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || observaciones != null) {
      map['observaciones'] = Variable<String>(observaciones);
    }
    return map;
  }

  GallosCompanion toCompanion(bool nullToAbsent) {
    return GallosCompanion(
      id: Value(id),
      partidoId: Value(partidoId),
      anillo: Value(anillo),
      pesoGramos: Value(pesoGramos),
      esBase: Value(esBase),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      observaciones: observaciones == null && nullToAbsent
          ? const Value.absent()
          : Value(observaciones),
    );
  }

  factory GalloEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GalloEntry(
      id: serializer.fromJson<int>(json['id']),
      partidoId: serializer.fromJson<int>(json['partidoId']),
      anillo: serializer.fromJson<String>(json['anillo']),
      pesoGramos: serializer.fromJson<double>(json['pesoGramos']),
      esBase: serializer.fromJson<bool>(json['esBase']),
      color: serializer.fromJson<String?>(json['color']),
      observaciones: serializer.fromJson<String?>(json['observaciones']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'partidoId': serializer.toJson<int>(partidoId),
      'anillo': serializer.toJson<String>(anillo),
      'pesoGramos': serializer.toJson<double>(pesoGramos),
      'esBase': serializer.toJson<bool>(esBase),
      'color': serializer.toJson<String?>(color),
      'observaciones': serializer.toJson<String?>(observaciones),
    };
  }

  GalloEntry copyWith({
    int? id,
    int? partidoId,
    String? anillo,
    double? pesoGramos,
    bool? esBase,
    Value<String?> color = const Value.absent(),
    Value<String?> observaciones = const Value.absent(),
  }) => GalloEntry(
    id: id ?? this.id,
    partidoId: partidoId ?? this.partidoId,
    anillo: anillo ?? this.anillo,
    pesoGramos: pesoGramos ?? this.pesoGramos,
    esBase: esBase ?? this.esBase,
    color: color.present ? color.value : this.color,
    observaciones: observaciones.present
        ? observaciones.value
        : this.observaciones,
  );
  GalloEntry copyWithCompanion(GallosCompanion data) {
    return GalloEntry(
      id: data.id.present ? data.id.value : this.id,
      partidoId: data.partidoId.present ? data.partidoId.value : this.partidoId,
      anillo: data.anillo.present ? data.anillo.value : this.anillo,
      pesoGramos: data.pesoGramos.present
          ? data.pesoGramos.value
          : this.pesoGramos,
      esBase: data.esBase.present ? data.esBase.value : this.esBase,
      color: data.color.present ? data.color.value : this.color,
      observaciones: data.observaciones.present
          ? data.observaciones.value
          : this.observaciones,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GalloEntry(')
          ..write('id: $id, ')
          ..write('partidoId: $partidoId, ')
          ..write('anillo: $anillo, ')
          ..write('pesoGramos: $pesoGramos, ')
          ..write('esBase: $esBase, ')
          ..write('color: $color, ')
          ..write('observaciones: $observaciones')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    partidoId,
    anillo,
    pesoGramos,
    esBase,
    color,
    observaciones,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GalloEntry &&
          other.id == this.id &&
          other.partidoId == this.partidoId &&
          other.anillo == this.anillo &&
          other.pesoGramos == this.pesoGramos &&
          other.esBase == this.esBase &&
          other.color == this.color &&
          other.observaciones == this.observaciones);
}

class GallosCompanion extends UpdateCompanion<GalloEntry> {
  final Value<int> id;
  final Value<int> partidoId;
  final Value<String> anillo;
  final Value<double> pesoGramos;
  final Value<bool> esBase;
  final Value<String?> color;
  final Value<String?> observaciones;
  const GallosCompanion({
    this.id = const Value.absent(),
    this.partidoId = const Value.absent(),
    this.anillo = const Value.absent(),
    this.pesoGramos = const Value.absent(),
    this.esBase = const Value.absent(),
    this.color = const Value.absent(),
    this.observaciones = const Value.absent(),
  });
  GallosCompanion.insert({
    this.id = const Value.absent(),
    required int partidoId,
    required String anillo,
    required double pesoGramos,
    this.esBase = const Value.absent(),
    this.color = const Value.absent(),
    this.observaciones = const Value.absent(),
  }) : partidoId = Value(partidoId),
       anillo = Value(anillo),
       pesoGramos = Value(pesoGramos);
  static Insertable<GalloEntry> custom({
    Expression<int>? id,
    Expression<int>? partidoId,
    Expression<String>? anillo,
    Expression<double>? pesoGramos,
    Expression<bool>? esBase,
    Expression<String>? color,
    Expression<String>? observaciones,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partidoId != null) 'partido_id': partidoId,
      if (anillo != null) 'anillo': anillo,
      if (pesoGramos != null) 'peso_gramos': pesoGramos,
      if (esBase != null) 'es_base': esBase,
      if (color != null) 'color': color,
      if (observaciones != null) 'observaciones': observaciones,
    });
  }

  GallosCompanion copyWith({
    Value<int>? id,
    Value<int>? partidoId,
    Value<String>? anillo,
    Value<double>? pesoGramos,
    Value<bool>? esBase,
    Value<String?>? color,
    Value<String?>? observaciones,
  }) {
    return GallosCompanion(
      id: id ?? this.id,
      partidoId: partidoId ?? this.partidoId,
      anillo: anillo ?? this.anillo,
      pesoGramos: pesoGramos ?? this.pesoGramos,
      esBase: esBase ?? this.esBase,
      color: color ?? this.color,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (partidoId.present) {
      map['partido_id'] = Variable<int>(partidoId.value);
    }
    if (anillo.present) {
      map['anillo'] = Variable<String>(anillo.value);
    }
    if (pesoGramos.present) {
      map['peso_gramos'] = Variable<double>(pesoGramos.value);
    }
    if (esBase.present) {
      map['es_base'] = Variable<bool>(esBase.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (observaciones.present) {
      map['observaciones'] = Variable<String>(observaciones.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GallosCompanion(')
          ..write('id: $id, ')
          ..write('partidoId: $partidoId, ')
          ..write('anillo: $anillo, ')
          ..write('pesoGramos: $pesoGramos, ')
          ..write('esBase: $esBase, ')
          ..write('color: $color, ')
          ..write('observaciones: $observaciones')
          ..write(')'))
        .toString();
  }
}

class $CompadresTableTable extends CompadresTable
    with TableInfo<$CompadresTableTable, CompadreEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompadresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _derbyIdMeta = const VerificationMeta(
    'derbyId',
  );
  @override
  late final GeneratedColumn<int> derbyId = GeneratedColumn<int>(
    'derby_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES derbys (id)',
    ),
  );
  static const VerificationMeta _partidoIdAMeta = const VerificationMeta(
    'partidoIdA',
  );
  @override
  late final GeneratedColumn<int> partidoIdA = GeneratedColumn<int>(
    'partido_id_a',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES partidos (id)',
    ),
  );
  static const VerificationMeta _partidoIdBMeta = const VerificationMeta(
    'partidoIdB',
  );
  @override
  late final GeneratedColumn<int> partidoIdB = GeneratedColumn<int>(
    'partido_id_b',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES partidos (id)',
    ),
  );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    derbyId,
    partidoIdA,
    partidoIdB,
    motivo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compadres';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompadreEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('derby_id')) {
      context.handle(
        _derbyIdMeta,
        derbyId.isAcceptableOrUnknown(data['derby_id']!, _derbyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_derbyIdMeta);
    }
    if (data.containsKey('partido_id_a')) {
      context.handle(
        _partidoIdAMeta,
        partidoIdA.isAcceptableOrUnknown(
          data['partido_id_a']!,
          _partidoIdAMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partidoIdAMeta);
    }
    if (data.containsKey('partido_id_b')) {
      context.handle(
        _partidoIdBMeta,
        partidoIdB.isAcceptableOrUnknown(
          data['partido_id_b']!,
          _partidoIdBMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partidoIdBMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompadreEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompadreEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      derbyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}derby_id'],
      )!,
      partidoIdA: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partido_id_a'],
      )!,
      partidoIdB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partido_id_b'],
      )!,
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      ),
    );
  }

  @override
  $CompadresTableTable createAlias(String alias) {
    return $CompadresTableTable(attachedDatabase, alias);
  }
}

class CompadreEntry extends DataClass implements Insertable<CompadreEntry> {
  final int id;
  final int derbyId;
  final int partidoIdA;
  final int partidoIdB;
  final String? motivo;
  const CompadreEntry({
    required this.id,
    required this.derbyId,
    required this.partidoIdA,
    required this.partidoIdB,
    this.motivo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['derby_id'] = Variable<int>(derbyId);
    map['partido_id_a'] = Variable<int>(partidoIdA);
    map['partido_id_b'] = Variable<int>(partidoIdB);
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(motivo);
    }
    return map;
  }

  CompadresTableCompanion toCompanion(bool nullToAbsent) {
    return CompadresTableCompanion(
      id: Value(id),
      derbyId: Value(derbyId),
      partidoIdA: Value(partidoIdA),
      partidoIdB: Value(partidoIdB),
      motivo: motivo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivo),
    );
  }

  factory CompadreEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompadreEntry(
      id: serializer.fromJson<int>(json['id']),
      derbyId: serializer.fromJson<int>(json['derbyId']),
      partidoIdA: serializer.fromJson<int>(json['partidoIdA']),
      partidoIdB: serializer.fromJson<int>(json['partidoIdB']),
      motivo: serializer.fromJson<String?>(json['motivo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'derbyId': serializer.toJson<int>(derbyId),
      'partidoIdA': serializer.toJson<int>(partidoIdA),
      'partidoIdB': serializer.toJson<int>(partidoIdB),
      'motivo': serializer.toJson<String?>(motivo),
    };
  }

  CompadreEntry copyWith({
    int? id,
    int? derbyId,
    int? partidoIdA,
    int? partidoIdB,
    Value<String?> motivo = const Value.absent(),
  }) => CompadreEntry(
    id: id ?? this.id,
    derbyId: derbyId ?? this.derbyId,
    partidoIdA: partidoIdA ?? this.partidoIdA,
    partidoIdB: partidoIdB ?? this.partidoIdB,
    motivo: motivo.present ? motivo.value : this.motivo,
  );
  CompadreEntry copyWithCompanion(CompadresTableCompanion data) {
    return CompadreEntry(
      id: data.id.present ? data.id.value : this.id,
      derbyId: data.derbyId.present ? data.derbyId.value : this.derbyId,
      partidoIdA: data.partidoIdA.present
          ? data.partidoIdA.value
          : this.partidoIdA,
      partidoIdB: data.partidoIdB.present
          ? data.partidoIdB.value
          : this.partidoIdB,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompadreEntry(')
          ..write('id: $id, ')
          ..write('derbyId: $derbyId, ')
          ..write('partidoIdA: $partidoIdA, ')
          ..write('partidoIdB: $partidoIdB, ')
          ..write('motivo: $motivo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, derbyId, partidoIdA, partidoIdB, motivo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompadreEntry &&
          other.id == this.id &&
          other.derbyId == this.derbyId &&
          other.partidoIdA == this.partidoIdA &&
          other.partidoIdB == this.partidoIdB &&
          other.motivo == this.motivo);
}

class CompadresTableCompanion extends UpdateCompanion<CompadreEntry> {
  final Value<int> id;
  final Value<int> derbyId;
  final Value<int> partidoIdA;
  final Value<int> partidoIdB;
  final Value<String?> motivo;
  const CompadresTableCompanion({
    this.id = const Value.absent(),
    this.derbyId = const Value.absent(),
    this.partidoIdA = const Value.absent(),
    this.partidoIdB = const Value.absent(),
    this.motivo = const Value.absent(),
  });
  CompadresTableCompanion.insert({
    this.id = const Value.absent(),
    required int derbyId,
    required int partidoIdA,
    required int partidoIdB,
    this.motivo = const Value.absent(),
  }) : derbyId = Value(derbyId),
       partidoIdA = Value(partidoIdA),
       partidoIdB = Value(partidoIdB);
  static Insertable<CompadreEntry> custom({
    Expression<int>? id,
    Expression<int>? derbyId,
    Expression<int>? partidoIdA,
    Expression<int>? partidoIdB,
    Expression<String>? motivo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (derbyId != null) 'derby_id': derbyId,
      if (partidoIdA != null) 'partido_id_a': partidoIdA,
      if (partidoIdB != null) 'partido_id_b': partidoIdB,
      if (motivo != null) 'motivo': motivo,
    });
  }

  CompadresTableCompanion copyWith({
    Value<int>? id,
    Value<int>? derbyId,
    Value<int>? partidoIdA,
    Value<int>? partidoIdB,
    Value<String?>? motivo,
  }) {
    return CompadresTableCompanion(
      id: id ?? this.id,
      derbyId: derbyId ?? this.derbyId,
      partidoIdA: partidoIdA ?? this.partidoIdA,
      partidoIdB: partidoIdB ?? this.partidoIdB,
      motivo: motivo ?? this.motivo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (derbyId.present) {
      map['derby_id'] = Variable<int>(derbyId.value);
    }
    if (partidoIdA.present) {
      map['partido_id_a'] = Variable<int>(partidoIdA.value);
    }
    if (partidoIdB.present) {
      map['partido_id_b'] = Variable<int>(partidoIdB.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompadresTableCompanion(')
          ..write('id: $id, ')
          ..write('derbyId: $derbyId, ')
          ..write('partidoIdA: $partidoIdA, ')
          ..write('partidoIdB: $partidoIdB, ')
          ..write('motivo: $motivo')
          ..write(')'))
        .toString();
  }
}

class $RondasTable extends Rondas with TableInfo<$RondasTable, Ronda> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RondasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _derbyIdMeta = const VerificationMeta(
    'derbyId',
  );
  @override
  late final GeneratedColumn<int> derbyId = GeneratedColumn<int>(
    'derby_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES derbys (id)',
    ),
  );
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<int> numero = GeneratedColumn<int>(
    'numero',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _esRondaBaseMeta = const VerificationMeta(
    'esRondaBase',
  );
  @override
  late final GeneratedColumn<bool> esRondaBase = GeneratedColumn<bool>(
    'es_ronda_base',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_ronda_base" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fechaCreacionMeta = const VerificationMeta(
    'fechaCreacion',
  );
  @override
  late final GeneratedColumn<DateTime> fechaCreacion =
      GeneratedColumn<DateTime>(
        'fecha_creacion',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _byePartidosMeta = const VerificationMeta(
    'byePartidos',
  );
  @override
  late final GeneratedColumn<String> byePartidos = GeneratedColumn<String>(
    'bye_partidos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _doblesPartidosMeta = const VerificationMeta(
    'doblesPartidos',
  );
  @override
  late final GeneratedColumn<String> doblesPartidos = GeneratedColumn<String>(
    'dobles_partidos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    derbyId,
    numero,
    esRondaBase,
    fechaCreacion,
    byePartidos,
    doblesPartidos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rondas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ronda> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('derby_id')) {
      context.handle(
        _derbyIdMeta,
        derbyId.isAcceptableOrUnknown(data['derby_id']!, _derbyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_derbyIdMeta);
    }
    if (data.containsKey('numero')) {
      context.handle(
        _numeroMeta,
        numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroMeta);
    }
    if (data.containsKey('es_ronda_base')) {
      context.handle(
        _esRondaBaseMeta,
        esRondaBase.isAcceptableOrUnknown(
          data['es_ronda_base']!,
          _esRondaBaseMeta,
        ),
      );
    }
    if (data.containsKey('fecha_creacion')) {
      context.handle(
        _fechaCreacionMeta,
        fechaCreacion.isAcceptableOrUnknown(
          data['fecha_creacion']!,
          _fechaCreacionMeta,
        ),
      );
    }
    if (data.containsKey('bye_partidos')) {
      context.handle(
        _byePartidosMeta,
        byePartidos.isAcceptableOrUnknown(
          data['bye_partidos']!,
          _byePartidosMeta,
        ),
      );
    }
    if (data.containsKey('dobles_partidos')) {
      context.handle(
        _doblesPartidosMeta,
        doblesPartidos.isAcceptableOrUnknown(
          data['dobles_partidos']!,
          _doblesPartidosMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ronda map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ronda(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      derbyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}derby_id'],
      )!,
      numero: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero'],
      )!,
      esRondaBase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_ronda_base'],
      )!,
      fechaCreacion: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_creacion'],
      )!,
      byePartidos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bye_partidos'],
      )!,
      doblesPartidos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dobles_partidos'],
      )!,
    );
  }

  @override
  $RondasTable createAlias(String alias) {
    return $RondasTable(attachedDatabase, alias);
  }
}

class Ronda extends DataClass implements Insertable<Ronda> {
  final int id;
  final int derbyId;
  final int numero;
  final bool esRondaBase;
  final DateTime fechaCreacion;

  /// IDs de partidos con BYE, separados por comas. Ejemplo: "3,7".
  final String byePartidos;

  /// IDs de partidos con doble pelea, separados por comas. Ejemplo: "5".
  final String doblesPartidos;
  const Ronda({
    required this.id,
    required this.derbyId,
    required this.numero,
    required this.esRondaBase,
    required this.fechaCreacion,
    required this.byePartidos,
    required this.doblesPartidos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['derby_id'] = Variable<int>(derbyId);
    map['numero'] = Variable<int>(numero);
    map['es_ronda_base'] = Variable<bool>(esRondaBase);
    map['fecha_creacion'] = Variable<DateTime>(fechaCreacion);
    map['bye_partidos'] = Variable<String>(byePartidos);
    map['dobles_partidos'] = Variable<String>(doblesPartidos);
    return map;
  }

  RondasCompanion toCompanion(bool nullToAbsent) {
    return RondasCompanion(
      id: Value(id),
      derbyId: Value(derbyId),
      numero: Value(numero),
      esRondaBase: Value(esRondaBase),
      fechaCreacion: Value(fechaCreacion),
      byePartidos: Value(byePartidos),
      doblesPartidos: Value(doblesPartidos),
    );
  }

  factory Ronda.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ronda(
      id: serializer.fromJson<int>(json['id']),
      derbyId: serializer.fromJson<int>(json['derbyId']),
      numero: serializer.fromJson<int>(json['numero']),
      esRondaBase: serializer.fromJson<bool>(json['esRondaBase']),
      fechaCreacion: serializer.fromJson<DateTime>(json['fechaCreacion']),
      byePartidos: serializer.fromJson<String>(json['byePartidos']),
      doblesPartidos: serializer.fromJson<String>(json['doblesPartidos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'derbyId': serializer.toJson<int>(derbyId),
      'numero': serializer.toJson<int>(numero),
      'esRondaBase': serializer.toJson<bool>(esRondaBase),
      'fechaCreacion': serializer.toJson<DateTime>(fechaCreacion),
      'byePartidos': serializer.toJson<String>(byePartidos),
      'doblesPartidos': serializer.toJson<String>(doblesPartidos),
    };
  }

  Ronda copyWith({
    int? id,
    int? derbyId,
    int? numero,
    bool? esRondaBase,
    DateTime? fechaCreacion,
    String? byePartidos,
    String? doblesPartidos,
  }) => Ronda(
    id: id ?? this.id,
    derbyId: derbyId ?? this.derbyId,
    numero: numero ?? this.numero,
    esRondaBase: esRondaBase ?? this.esRondaBase,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    byePartidos: byePartidos ?? this.byePartidos,
    doblesPartidos: doblesPartidos ?? this.doblesPartidos,
  );
  Ronda copyWithCompanion(RondasCompanion data) {
    return Ronda(
      id: data.id.present ? data.id.value : this.id,
      derbyId: data.derbyId.present ? data.derbyId.value : this.derbyId,
      numero: data.numero.present ? data.numero.value : this.numero,
      esRondaBase: data.esRondaBase.present
          ? data.esRondaBase.value
          : this.esRondaBase,
      fechaCreacion: data.fechaCreacion.present
          ? data.fechaCreacion.value
          : this.fechaCreacion,
      byePartidos: data.byePartidos.present
          ? data.byePartidos.value
          : this.byePartidos,
      doblesPartidos: data.doblesPartidos.present
          ? data.doblesPartidos.value
          : this.doblesPartidos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ronda(')
          ..write('id: $id, ')
          ..write('derbyId: $derbyId, ')
          ..write('numero: $numero, ')
          ..write('esRondaBase: $esRondaBase, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('byePartidos: $byePartidos, ')
          ..write('doblesPartidos: $doblesPartidos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    derbyId,
    numero,
    esRondaBase,
    fechaCreacion,
    byePartidos,
    doblesPartidos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ronda &&
          other.id == this.id &&
          other.derbyId == this.derbyId &&
          other.numero == this.numero &&
          other.esRondaBase == this.esRondaBase &&
          other.fechaCreacion == this.fechaCreacion &&
          other.byePartidos == this.byePartidos &&
          other.doblesPartidos == this.doblesPartidos);
}

class RondasCompanion extends UpdateCompanion<Ronda> {
  final Value<int> id;
  final Value<int> derbyId;
  final Value<int> numero;
  final Value<bool> esRondaBase;
  final Value<DateTime> fechaCreacion;
  final Value<String> byePartidos;
  final Value<String> doblesPartidos;
  const RondasCompanion({
    this.id = const Value.absent(),
    this.derbyId = const Value.absent(),
    this.numero = const Value.absent(),
    this.esRondaBase = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.byePartidos = const Value.absent(),
    this.doblesPartidos = const Value.absent(),
  });
  RondasCompanion.insert({
    this.id = const Value.absent(),
    required int derbyId,
    required int numero,
    this.esRondaBase = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.byePartidos = const Value.absent(),
    this.doblesPartidos = const Value.absent(),
  }) : derbyId = Value(derbyId),
       numero = Value(numero);
  static Insertable<Ronda> custom({
    Expression<int>? id,
    Expression<int>? derbyId,
    Expression<int>? numero,
    Expression<bool>? esRondaBase,
    Expression<DateTime>? fechaCreacion,
    Expression<String>? byePartidos,
    Expression<String>? doblesPartidos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (derbyId != null) 'derby_id': derbyId,
      if (numero != null) 'numero': numero,
      if (esRondaBase != null) 'es_ronda_base': esRondaBase,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion,
      if (byePartidos != null) 'bye_partidos': byePartidos,
      if (doblesPartidos != null) 'dobles_partidos': doblesPartidos,
    });
  }

  RondasCompanion copyWith({
    Value<int>? id,
    Value<int>? derbyId,
    Value<int>? numero,
    Value<bool>? esRondaBase,
    Value<DateTime>? fechaCreacion,
    Value<String>? byePartidos,
    Value<String>? doblesPartidos,
  }) {
    return RondasCompanion(
      id: id ?? this.id,
      derbyId: derbyId ?? this.derbyId,
      numero: numero ?? this.numero,
      esRondaBase: esRondaBase ?? this.esRondaBase,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      byePartidos: byePartidos ?? this.byePartidos,
      doblesPartidos: doblesPartidos ?? this.doblesPartidos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (derbyId.present) {
      map['derby_id'] = Variable<int>(derbyId.value);
    }
    if (numero.present) {
      map['numero'] = Variable<int>(numero.value);
    }
    if (esRondaBase.present) {
      map['es_ronda_base'] = Variable<bool>(esRondaBase.value);
    }
    if (fechaCreacion.present) {
      map['fecha_creacion'] = Variable<DateTime>(fechaCreacion.value);
    }
    if (byePartidos.present) {
      map['bye_partidos'] = Variable<String>(byePartidos.value);
    }
    if (doblesPartidos.present) {
      map['dobles_partidos'] = Variable<String>(doblesPartidos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RondasCompanion(')
          ..write('id: $id, ')
          ..write('derbyId: $derbyId, ')
          ..write('numero: $numero, ')
          ..write('esRondaBase: $esRondaBase, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('byePartidos: $byePartidos, ')
          ..write('doblesPartidos: $doblesPartidos')
          ..write(')'))
        .toString();
  }
}

class $EnfrentamientosTable extends Enfrentamientos
    with TableInfo<$EnfrentamientosTable, Enfrentamiento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnfrentamientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _rondaIdMeta = const VerificationMeta(
    'rondaId',
  );
  @override
  late final GeneratedColumn<int> rondaId = GeneratedColumn<int>(
    'ronda_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rondas (id)',
    ),
  );
  static const VerificationMeta _galloAIdMeta = const VerificationMeta(
    'galloAId',
  );
  @override
  late final GeneratedColumn<int> galloAId = GeneratedColumn<int>(
    'gallo_a_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gallos (id)',
    ),
  );
  static const VerificationMeta _galloBIdMeta = const VerificationMeta(
    'galloBId',
  );
  @override
  late final GeneratedColumn<int> galloBId = GeneratedColumn<int>(
    'gallo_b_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gallos (id)',
    ),
  );
  static const VerificationMeta _diferenciaPesoMeta = const VerificationMeta(
    'diferenciaPeso',
  );
  @override
  late final GeneratedColumn<double> diferenciaPeso = GeneratedColumn<double>(
    'diferencia_peso',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultadoMeta = const VerificationMeta(
    'resultado',
  );
  @override
  late final GeneratedColumn<String> resultado = GeneratedColumn<String>(
    'resultado',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _esManualMeta = const VerificationMeta(
    'esManual',
  );
  @override
  late final GeneratedColumn<bool> esManual = GeneratedColumn<bool>(
    'es_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rondaId,
    galloAId,
    galloBId,
    diferenciaPeso,
    resultado,
    esManual,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enfrentamientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Enfrentamiento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ronda_id')) {
      context.handle(
        _rondaIdMeta,
        rondaId.isAcceptableOrUnknown(data['ronda_id']!, _rondaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rondaIdMeta);
    }
    if (data.containsKey('gallo_a_id')) {
      context.handle(
        _galloAIdMeta,
        galloAId.isAcceptableOrUnknown(data['gallo_a_id']!, _galloAIdMeta),
      );
    } else if (isInserting) {
      context.missing(_galloAIdMeta);
    }
    if (data.containsKey('gallo_b_id')) {
      context.handle(
        _galloBIdMeta,
        galloBId.isAcceptableOrUnknown(data['gallo_b_id']!, _galloBIdMeta),
      );
    }
    if (data.containsKey('diferencia_peso')) {
      context.handle(
        _diferenciaPesoMeta,
        diferenciaPeso.isAcceptableOrUnknown(
          data['diferencia_peso']!,
          _diferenciaPesoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_diferenciaPesoMeta);
    }
    if (data.containsKey('resultado')) {
      context.handle(
        _resultadoMeta,
        resultado.isAcceptableOrUnknown(data['resultado']!, _resultadoMeta),
      );
    }
    if (data.containsKey('es_manual')) {
      context.handle(
        _esManualMeta,
        esManual.isAcceptableOrUnknown(data['es_manual']!, _esManualMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Enfrentamiento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Enfrentamiento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rondaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ronda_id'],
      )!,
      galloAId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gallo_a_id'],
      )!,
      galloBId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gallo_b_id'],
      ),
      diferenciaPeso: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diferencia_peso'],
      )!,
      resultado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resultado'],
      ),
      esManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_manual'],
      )!,
    );
  }

  @override
  $EnfrentamientosTable createAlias(String alias) {
    return $EnfrentamientosTable(attachedDatabase, alias);
  }
}

class Enfrentamiento extends DataClass implements Insertable<Enfrentamiento> {
  final int id;
  final int rondaId;
  final int galloAId;
  final int? galloBId;
  final double diferenciaPeso;
  final String? resultado;
  final bool esManual;
  const Enfrentamiento({
    required this.id,
    required this.rondaId,
    required this.galloAId,
    this.galloBId,
    required this.diferenciaPeso,
    this.resultado,
    required this.esManual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ronda_id'] = Variable<int>(rondaId);
    map['gallo_a_id'] = Variable<int>(galloAId);
    if (!nullToAbsent || galloBId != null) {
      map['gallo_b_id'] = Variable<int>(galloBId);
    }
    map['diferencia_peso'] = Variable<double>(diferenciaPeso);
    if (!nullToAbsent || resultado != null) {
      map['resultado'] = Variable<String>(resultado);
    }
    map['es_manual'] = Variable<bool>(esManual);
    return map;
  }

  EnfrentamientosCompanion toCompanion(bool nullToAbsent) {
    return EnfrentamientosCompanion(
      id: Value(id),
      rondaId: Value(rondaId),
      galloAId: Value(galloAId),
      galloBId: galloBId == null && nullToAbsent
          ? const Value.absent()
          : Value(galloBId),
      diferenciaPeso: Value(diferenciaPeso),
      resultado: resultado == null && nullToAbsent
          ? const Value.absent()
          : Value(resultado),
      esManual: Value(esManual),
    );
  }

  factory Enfrentamiento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Enfrentamiento(
      id: serializer.fromJson<int>(json['id']),
      rondaId: serializer.fromJson<int>(json['rondaId']),
      galloAId: serializer.fromJson<int>(json['galloAId']),
      galloBId: serializer.fromJson<int?>(json['galloBId']),
      diferenciaPeso: serializer.fromJson<double>(json['diferenciaPeso']),
      resultado: serializer.fromJson<String?>(json['resultado']),
      esManual: serializer.fromJson<bool>(json['esManual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rondaId': serializer.toJson<int>(rondaId),
      'galloAId': serializer.toJson<int>(galloAId),
      'galloBId': serializer.toJson<int?>(galloBId),
      'diferenciaPeso': serializer.toJson<double>(diferenciaPeso),
      'resultado': serializer.toJson<String?>(resultado),
      'esManual': serializer.toJson<bool>(esManual),
    };
  }

  Enfrentamiento copyWith({
    int? id,
    int? rondaId,
    int? galloAId,
    Value<int?> galloBId = const Value.absent(),
    double? diferenciaPeso,
    Value<String?> resultado = const Value.absent(),
    bool? esManual,
  }) => Enfrentamiento(
    id: id ?? this.id,
    rondaId: rondaId ?? this.rondaId,
    galloAId: galloAId ?? this.galloAId,
    galloBId: galloBId.present ? galloBId.value : this.galloBId,
    diferenciaPeso: diferenciaPeso ?? this.diferenciaPeso,
    resultado: resultado.present ? resultado.value : this.resultado,
    esManual: esManual ?? this.esManual,
  );
  Enfrentamiento copyWithCompanion(EnfrentamientosCompanion data) {
    return Enfrentamiento(
      id: data.id.present ? data.id.value : this.id,
      rondaId: data.rondaId.present ? data.rondaId.value : this.rondaId,
      galloAId: data.galloAId.present ? data.galloAId.value : this.galloAId,
      galloBId: data.galloBId.present ? data.galloBId.value : this.galloBId,
      diferenciaPeso: data.diferenciaPeso.present
          ? data.diferenciaPeso.value
          : this.diferenciaPeso,
      resultado: data.resultado.present ? data.resultado.value : this.resultado,
      esManual: data.esManual.present ? data.esManual.value : this.esManual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Enfrentamiento(')
          ..write('id: $id, ')
          ..write('rondaId: $rondaId, ')
          ..write('galloAId: $galloAId, ')
          ..write('galloBId: $galloBId, ')
          ..write('diferenciaPeso: $diferenciaPeso, ')
          ..write('resultado: $resultado, ')
          ..write('esManual: $esManual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rondaId,
    galloAId,
    galloBId,
    diferenciaPeso,
    resultado,
    esManual,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Enfrentamiento &&
          other.id == this.id &&
          other.rondaId == this.rondaId &&
          other.galloAId == this.galloAId &&
          other.galloBId == this.galloBId &&
          other.diferenciaPeso == this.diferenciaPeso &&
          other.resultado == this.resultado &&
          other.esManual == this.esManual);
}

class EnfrentamientosCompanion extends UpdateCompanion<Enfrentamiento> {
  final Value<int> id;
  final Value<int> rondaId;
  final Value<int> galloAId;
  final Value<int?> galloBId;
  final Value<double> diferenciaPeso;
  final Value<String?> resultado;
  final Value<bool> esManual;
  const EnfrentamientosCompanion({
    this.id = const Value.absent(),
    this.rondaId = const Value.absent(),
    this.galloAId = const Value.absent(),
    this.galloBId = const Value.absent(),
    this.diferenciaPeso = const Value.absent(),
    this.resultado = const Value.absent(),
    this.esManual = const Value.absent(),
  });
  EnfrentamientosCompanion.insert({
    this.id = const Value.absent(),
    required int rondaId,
    required int galloAId,
    this.galloBId = const Value.absent(),
    required double diferenciaPeso,
    this.resultado = const Value.absent(),
    this.esManual = const Value.absent(),
  }) : rondaId = Value(rondaId),
       galloAId = Value(galloAId),
       diferenciaPeso = Value(diferenciaPeso);
  static Insertable<Enfrentamiento> custom({
    Expression<int>? id,
    Expression<int>? rondaId,
    Expression<int>? galloAId,
    Expression<int>? galloBId,
    Expression<double>? diferenciaPeso,
    Expression<String>? resultado,
    Expression<bool>? esManual,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rondaId != null) 'ronda_id': rondaId,
      if (galloAId != null) 'gallo_a_id': galloAId,
      if (galloBId != null) 'gallo_b_id': galloBId,
      if (diferenciaPeso != null) 'diferencia_peso': diferenciaPeso,
      if (resultado != null) 'resultado': resultado,
      if (esManual != null) 'es_manual': esManual,
    });
  }

  EnfrentamientosCompanion copyWith({
    Value<int>? id,
    Value<int>? rondaId,
    Value<int>? galloAId,
    Value<int?>? galloBId,
    Value<double>? diferenciaPeso,
    Value<String?>? resultado,
    Value<bool>? esManual,
  }) {
    return EnfrentamientosCompanion(
      id: id ?? this.id,
      rondaId: rondaId ?? this.rondaId,
      galloAId: galloAId ?? this.galloAId,
      galloBId: galloBId ?? this.galloBId,
      diferenciaPeso: diferenciaPeso ?? this.diferenciaPeso,
      resultado: resultado ?? this.resultado,
      esManual: esManual ?? this.esManual,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rondaId.present) {
      map['ronda_id'] = Variable<int>(rondaId.value);
    }
    if (galloAId.present) {
      map['gallo_a_id'] = Variable<int>(galloAId.value);
    }
    if (galloBId.present) {
      map['gallo_b_id'] = Variable<int>(galloBId.value);
    }
    if (diferenciaPeso.present) {
      map['diferencia_peso'] = Variable<double>(diferenciaPeso.value);
    }
    if (resultado.present) {
      map['resultado'] = Variable<String>(resultado.value);
    }
    if (esManual.present) {
      map['es_manual'] = Variable<bool>(esManual.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnfrentamientosCompanion(')
          ..write('id: $id, ')
          ..write('rondaId: $rondaId, ')
          ..write('galloAId: $galloAId, ')
          ..write('galloBId: $galloBId, ')
          ..write('diferenciaPeso: $diferenciaPeso, ')
          ..write('resultado: $resultado, ')
          ..write('esManual: $esManual')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DerbysTable derbys = $DerbysTable(this);
  late final $PartidosTable partidos = $PartidosTable(this);
  late final $GallosTable gallos = $GallosTable(this);
  late final $CompadresTableTable compadresTable = $CompadresTableTable(this);
  late final $RondasTable rondas = $RondasTable(this);
  late final $EnfrentamientosTable enfrentamientos = $EnfrentamientosTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    derbys,
    partidos,
    gallos,
    compadresTable,
    rondas,
    enfrentamientos,
  ];
}

typedef $$DerbysTableCreateCompanionBuilder =
    DerbysCompanion Function({
      Value<int> id,
      required String nombre,
      Value<DateTime> fechaCreacion,
      Value<int> rondasTotales,
      Value<int> puntosVictoria,
      Value<int> puntosEmpate,
      Value<int> puntosDerrota,
      Value<int> posicionesPremio,
      Value<String> estado,
      Value<double> pesoMinimo,
      Value<double> pesoMaximo,
      Value<double> pesoGalloBase,
      Value<bool> permitirRepeticiones,
      Value<double> diferenciaMaxPeso,
      Value<bool> validacionEstricta,
    });
typedef $$DerbysTableUpdateCompanionBuilder =
    DerbysCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<DateTime> fechaCreacion,
      Value<int> rondasTotales,
      Value<int> puntosVictoria,
      Value<int> puntosEmpate,
      Value<int> puntosDerrota,
      Value<int> posicionesPremio,
      Value<String> estado,
      Value<double> pesoMinimo,
      Value<double> pesoMaximo,
      Value<double> pesoGalloBase,
      Value<bool> permitirRepeticiones,
      Value<double> diferenciaMaxPeso,
      Value<bool> validacionEstricta,
    });

final class $$DerbysTableReferences
    extends BaseReferences<_$AppDatabase, $DerbysTable, Derby> {
  $$DerbysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PartidosTable, List<Partido>> _partidosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.partidos,
    aliasName: $_aliasNameGenerator(db.derbys.id, db.partidos.derbyId),
  );

  $$PartidosTableProcessedTableManager get partidosRefs {
    final manager = $$PartidosTableTableManager(
      $_db,
      $_db.partidos,
    ).filter((f) => f.derbyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_partidosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompadresTableTable, List<CompadreEntry>>
  _compadresTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.compadresTable,
    aliasName: $_aliasNameGenerator(db.derbys.id, db.compadresTable.derbyId),
  );

  $$CompadresTableTableProcessedTableManager get compadresTableRefs {
    final manager = $$CompadresTableTableTableManager(
      $_db,
      $_db.compadresTable,
    ).filter((f) => f.derbyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_compadresTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RondasTable, List<Ronda>> _rondasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rondas,
    aliasName: $_aliasNameGenerator(db.derbys.id, db.rondas.derbyId),
  );

  $$RondasTableProcessedTableManager get rondasRefs {
    final manager = $$RondasTableTableManager(
      $_db,
      $_db.rondas,
    ).filter((f) => f.derbyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rondasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DerbysTableFilterComposer
    extends Composer<_$AppDatabase, $DerbysTable> {
  $$DerbysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rondasTotales => $composableBuilder(
    column: $table.rondasTotales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puntosVictoria => $composableBuilder(
    column: $table.puntosVictoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puntosEmpate => $composableBuilder(
    column: $table.puntosEmpate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puntosDerrota => $composableBuilder(
    column: $table.puntosDerrota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get posicionesPremio => $composableBuilder(
    column: $table.posicionesPremio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoMinimo => $composableBuilder(
    column: $table.pesoMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoMaximo => $composableBuilder(
    column: $table.pesoMaximo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoGalloBase => $composableBuilder(
    column: $table.pesoGalloBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get permitirRepeticiones => $composableBuilder(
    column: $table.permitirRepeticiones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diferenciaMaxPeso => $composableBuilder(
    column: $table.diferenciaMaxPeso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get validacionEstricta => $composableBuilder(
    column: $table.validacionEstricta,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> partidosRefs(
    Expression<bool> Function($$PartidosTableFilterComposer f) f,
  ) {
    final $$PartidosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.derbyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableFilterComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> compadresTableRefs(
    Expression<bool> Function($$CompadresTableTableFilterComposer f) f,
  ) {
    final $$CompadresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compadresTable,
      getReferencedColumn: (t) => t.derbyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompadresTableTableFilterComposer(
            $db: $db,
            $table: $db.compadresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rondasRefs(
    Expression<bool> Function($$RondasTableFilterComposer f) f,
  ) {
    final $$RondasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rondas,
      getReferencedColumn: (t) => t.derbyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RondasTableFilterComposer(
            $db: $db,
            $table: $db.rondas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DerbysTableOrderingComposer
    extends Composer<_$AppDatabase, $DerbysTable> {
  $$DerbysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rondasTotales => $composableBuilder(
    column: $table.rondasTotales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puntosVictoria => $composableBuilder(
    column: $table.puntosVictoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puntosEmpate => $composableBuilder(
    column: $table.puntosEmpate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puntosDerrota => $composableBuilder(
    column: $table.puntosDerrota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get posicionesPremio => $composableBuilder(
    column: $table.posicionesPremio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoMinimo => $composableBuilder(
    column: $table.pesoMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoMaximo => $composableBuilder(
    column: $table.pesoMaximo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoGalloBase => $composableBuilder(
    column: $table.pesoGalloBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get permitirRepeticiones => $composableBuilder(
    column: $table.permitirRepeticiones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diferenciaMaxPeso => $composableBuilder(
    column: $table.diferenciaMaxPeso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get validacionEstricta => $composableBuilder(
    column: $table.validacionEstricta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DerbysTableAnnotationComposer
    extends Composer<_$AppDatabase, $DerbysTable> {
  $$DerbysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rondasTotales => $composableBuilder(
    column: $table.rondasTotales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get puntosVictoria => $composableBuilder(
    column: $table.puntosVictoria,
    builder: (column) => column,
  );

  GeneratedColumn<int> get puntosEmpate => $composableBuilder(
    column: $table.puntosEmpate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get puntosDerrota => $composableBuilder(
    column: $table.puntosDerrota,
    builder: (column) => column,
  );

  GeneratedColumn<int> get posicionesPremio => $composableBuilder(
    column: $table.posicionesPremio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<double> get pesoMinimo => $composableBuilder(
    column: $table.pesoMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pesoMaximo => $composableBuilder(
    column: $table.pesoMaximo,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pesoGalloBase => $composableBuilder(
    column: $table.pesoGalloBase,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get permitirRepeticiones => $composableBuilder(
    column: $table.permitirRepeticiones,
    builder: (column) => column,
  );

  GeneratedColumn<double> get diferenciaMaxPeso => $composableBuilder(
    column: $table.diferenciaMaxPeso,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get validacionEstricta => $composableBuilder(
    column: $table.validacionEstricta,
    builder: (column) => column,
  );

  Expression<T> partidosRefs<T extends Object>(
    Expression<T> Function($$PartidosTableAnnotationComposer a) f,
  ) {
    final $$PartidosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.derbyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableAnnotationComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> compadresTableRefs<T extends Object>(
    Expression<T> Function($$CompadresTableTableAnnotationComposer a) f,
  ) {
    final $$CompadresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compadresTable,
      getReferencedColumn: (t) => t.derbyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompadresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.compadresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rondasRefs<T extends Object>(
    Expression<T> Function($$RondasTableAnnotationComposer a) f,
  ) {
    final $$RondasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rondas,
      getReferencedColumn: (t) => t.derbyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RondasTableAnnotationComposer(
            $db: $db,
            $table: $db.rondas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DerbysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DerbysTable,
          Derby,
          $$DerbysTableFilterComposer,
          $$DerbysTableOrderingComposer,
          $$DerbysTableAnnotationComposer,
          $$DerbysTableCreateCompanionBuilder,
          $$DerbysTableUpdateCompanionBuilder,
          (Derby, $$DerbysTableReferences),
          Derby,
          PrefetchHooks Function({
            bool partidosRefs,
            bool compadresTableRefs,
            bool rondasRefs,
          })
        > {
  $$DerbysTableTableManager(_$AppDatabase db, $DerbysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DerbysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DerbysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DerbysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<int> rondasTotales = const Value.absent(),
                Value<int> puntosVictoria = const Value.absent(),
                Value<int> puntosEmpate = const Value.absent(),
                Value<int> puntosDerrota = const Value.absent(),
                Value<int> posicionesPremio = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<double> pesoMinimo = const Value.absent(),
                Value<double> pesoMaximo = const Value.absent(),
                Value<double> pesoGalloBase = const Value.absent(),
                Value<bool> permitirRepeticiones = const Value.absent(),
                Value<double> diferenciaMaxPeso = const Value.absent(),
                Value<bool> validacionEstricta = const Value.absent(),
              }) => DerbysCompanion(
                id: id,
                nombre: nombre,
                fechaCreacion: fechaCreacion,
                rondasTotales: rondasTotales,
                puntosVictoria: puntosVictoria,
                puntosEmpate: puntosEmpate,
                puntosDerrota: puntosDerrota,
                posicionesPremio: posicionesPremio,
                estado: estado,
                pesoMinimo: pesoMinimo,
                pesoMaximo: pesoMaximo,
                pesoGalloBase: pesoGalloBase,
                permitirRepeticiones: permitirRepeticiones,
                diferenciaMaxPeso: diferenciaMaxPeso,
                validacionEstricta: validacionEstricta,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<int> rondasTotales = const Value.absent(),
                Value<int> puntosVictoria = const Value.absent(),
                Value<int> puntosEmpate = const Value.absent(),
                Value<int> puntosDerrota = const Value.absent(),
                Value<int> posicionesPremio = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<double> pesoMinimo = const Value.absent(),
                Value<double> pesoMaximo = const Value.absent(),
                Value<double> pesoGalloBase = const Value.absent(),
                Value<bool> permitirRepeticiones = const Value.absent(),
                Value<double> diferenciaMaxPeso = const Value.absent(),
                Value<bool> validacionEstricta = const Value.absent(),
              }) => DerbysCompanion.insert(
                id: id,
                nombre: nombre,
                fechaCreacion: fechaCreacion,
                rondasTotales: rondasTotales,
                puntosVictoria: puntosVictoria,
                puntosEmpate: puntosEmpate,
                puntosDerrota: puntosDerrota,
                posicionesPremio: posicionesPremio,
                estado: estado,
                pesoMinimo: pesoMinimo,
                pesoMaximo: pesoMaximo,
                pesoGalloBase: pesoGalloBase,
                permitirRepeticiones: permitirRepeticiones,
                diferenciaMaxPeso: diferenciaMaxPeso,
                validacionEstricta: validacionEstricta,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DerbysTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                partidosRefs = false,
                compadresTableRefs = false,
                rondasRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (partidosRefs) db.partidos,
                    if (compadresTableRefs) db.compadresTable,
                    if (rondasRefs) db.rondas,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (partidosRefs)
                        await $_getPrefetchedData<Derby, $DerbysTable, Partido>(
                          currentTable: table,
                          referencedTable: $$DerbysTableReferences
                              ._partidosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DerbysTableReferences(
                                db,
                                table,
                                p0,
                              ).partidosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.derbyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (compadresTableRefs)
                        await $_getPrefetchedData<
                          Derby,
                          $DerbysTable,
                          CompadreEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DerbysTableReferences
                              ._compadresTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DerbysTableReferences(
                                db,
                                table,
                                p0,
                              ).compadresTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.derbyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rondasRefs)
                        await $_getPrefetchedData<Derby, $DerbysTable, Ronda>(
                          currentTable: table,
                          referencedTable: $$DerbysTableReferences
                              ._rondasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DerbysTableReferences(db, table, p0).rondasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.derbyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DerbysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DerbysTable,
      Derby,
      $$DerbysTableFilterComposer,
      $$DerbysTableOrderingComposer,
      $$DerbysTableAnnotationComposer,
      $$DerbysTableCreateCompanionBuilder,
      $$DerbysTableUpdateCompanionBuilder,
      (Derby, $$DerbysTableReferences),
      Derby,
      PrefetchHooks Function({
        bool partidosRefs,
        bool compadresTableRefs,
        bool rondasRefs,
      })
    >;
typedef $$PartidosTableCreateCompanionBuilder =
    PartidosCompanion Function({
      Value<int> id,
      required int derbyId,
      required String nombre,
      Value<String?> responsable,
      Value<String?> telefono,
      Value<String> estado,
      Value<int> puntos,
      Value<bool> eliminado,
      Value<bool> depositoPagado,
      Value<double> depositoCantidad,
      Value<bool> esComodin,
    });
typedef $$PartidosTableUpdateCompanionBuilder =
    PartidosCompanion Function({
      Value<int> id,
      Value<int> derbyId,
      Value<String> nombre,
      Value<String?> responsable,
      Value<String?> telefono,
      Value<String> estado,
      Value<int> puntos,
      Value<bool> eliminado,
      Value<bool> depositoPagado,
      Value<double> depositoCantidad,
      Value<bool> esComodin,
    });

final class $$PartidosTableReferences
    extends BaseReferences<_$AppDatabase, $PartidosTable, Partido> {
  $$PartidosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DerbysTable _derbyIdTable(_$AppDatabase db) => db.derbys.createAlias(
    $_aliasNameGenerator(db.partidos.derbyId, db.derbys.id),
  );

  $$DerbysTableProcessedTableManager get derbyId {
    final $_column = $_itemColumn<int>('derby_id')!;

    final manager = $$DerbysTableTableManager(
      $_db,
      $_db.derbys,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_derbyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GallosTable, List<GalloEntry>> _gallosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.gallos,
    aliasName: $_aliasNameGenerator(db.partidos.id, db.gallos.partidoId),
  );

  $$GallosTableProcessedTableManager get gallosRefs {
    final manager = $$GallosTableTableManager(
      $_db,
      $_db.gallos,
    ).filter((f) => f.partidoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gallosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PartidosTableFilterComposer
    extends Composer<_$AppDatabase, $PartidosTable> {
  $$PartidosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responsable => $composableBuilder(
    column: $table.responsable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puntos => $composableBuilder(
    column: $table.puntos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminado => $composableBuilder(
    column: $table.eliminado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get depositoPagado => $composableBuilder(
    column: $table.depositoPagado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depositoCantidad => $composableBuilder(
    column: $table.depositoCantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esComodin => $composableBuilder(
    column: $table.esComodin,
    builder: (column) => ColumnFilters(column),
  );

  $$DerbysTableFilterComposer get derbyId {
    final $$DerbysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableFilterComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> gallosRefs(
    Expression<bool> Function($$GallosTableFilterComposer f) f,
  ) {
    final $$GallosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.partidoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableFilterComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PartidosTableOrderingComposer
    extends Composer<_$AppDatabase, $PartidosTable> {
  $$PartidosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responsable => $composableBuilder(
    column: $table.responsable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puntos => $composableBuilder(
    column: $table.puntos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminado => $composableBuilder(
    column: $table.eliminado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get depositoPagado => $composableBuilder(
    column: $table.depositoPagado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depositoCantidad => $composableBuilder(
    column: $table.depositoCantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esComodin => $composableBuilder(
    column: $table.esComodin,
    builder: (column) => ColumnOrderings(column),
  );

  $$DerbysTableOrderingComposer get derbyId {
    final $$DerbysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableOrderingComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PartidosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartidosTable> {
  $$PartidosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get responsable => $composableBuilder(
    column: $table.responsable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<int> get puntos =>
      $composableBuilder(column: $table.puntos, builder: (column) => column);

  GeneratedColumn<bool> get eliminado =>
      $composableBuilder(column: $table.eliminado, builder: (column) => column);

  GeneratedColumn<bool> get depositoPagado => $composableBuilder(
    column: $table.depositoPagado,
    builder: (column) => column,
  );

  GeneratedColumn<double> get depositoCantidad => $composableBuilder(
    column: $table.depositoCantidad,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get esComodin =>
      $composableBuilder(column: $table.esComodin, builder: (column) => column);

  $$DerbysTableAnnotationComposer get derbyId {
    final $$DerbysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableAnnotationComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> gallosRefs<T extends Object>(
    Expression<T> Function($$GallosTableAnnotationComposer a) f,
  ) {
    final $$GallosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.partidoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableAnnotationComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PartidosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PartidosTable,
          Partido,
          $$PartidosTableFilterComposer,
          $$PartidosTableOrderingComposer,
          $$PartidosTableAnnotationComposer,
          $$PartidosTableCreateCompanionBuilder,
          $$PartidosTableUpdateCompanionBuilder,
          (Partido, $$PartidosTableReferences),
          Partido,
          PrefetchHooks Function({bool derbyId, bool gallosRefs})
        > {
  $$PartidosTableTableManager(_$AppDatabase db, $PartidosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartidosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartidosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartidosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> derbyId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> responsable = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<int> puntos = const Value.absent(),
                Value<bool> eliminado = const Value.absent(),
                Value<bool> depositoPagado = const Value.absent(),
                Value<double> depositoCantidad = const Value.absent(),
                Value<bool> esComodin = const Value.absent(),
              }) => PartidosCompanion(
                id: id,
                derbyId: derbyId,
                nombre: nombre,
                responsable: responsable,
                telefono: telefono,
                estado: estado,
                puntos: puntos,
                eliminado: eliminado,
                depositoPagado: depositoPagado,
                depositoCantidad: depositoCantidad,
                esComodin: esComodin,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int derbyId,
                required String nombre,
                Value<String?> responsable = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<int> puntos = const Value.absent(),
                Value<bool> eliminado = const Value.absent(),
                Value<bool> depositoPagado = const Value.absent(),
                Value<double> depositoCantidad = const Value.absent(),
                Value<bool> esComodin = const Value.absent(),
              }) => PartidosCompanion.insert(
                id: id,
                derbyId: derbyId,
                nombre: nombre,
                responsable: responsable,
                telefono: telefono,
                estado: estado,
                puntos: puntos,
                eliminado: eliminado,
                depositoPagado: depositoPagado,
                depositoCantidad: depositoCantidad,
                esComodin: esComodin,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PartidosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({derbyId = false, gallosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gallosRefs) db.gallos],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (derbyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.derbyId,
                                referencedTable: $$PartidosTableReferences
                                    ._derbyIdTable(db),
                                referencedColumn: $$PartidosTableReferences
                                    ._derbyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gallosRefs)
                    await $_getPrefetchedData<
                      Partido,
                      $PartidosTable,
                      GalloEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PartidosTableReferences
                          ._gallosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PartidosTableReferences(db, table, p0).gallosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.partidoId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PartidosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PartidosTable,
      Partido,
      $$PartidosTableFilterComposer,
      $$PartidosTableOrderingComposer,
      $$PartidosTableAnnotationComposer,
      $$PartidosTableCreateCompanionBuilder,
      $$PartidosTableUpdateCompanionBuilder,
      (Partido, $$PartidosTableReferences),
      Partido,
      PrefetchHooks Function({bool derbyId, bool gallosRefs})
    >;
typedef $$GallosTableCreateCompanionBuilder =
    GallosCompanion Function({
      Value<int> id,
      required int partidoId,
      required String anillo,
      required double pesoGramos,
      Value<bool> esBase,
      Value<String?> color,
      Value<String?> observaciones,
    });
typedef $$GallosTableUpdateCompanionBuilder =
    GallosCompanion Function({
      Value<int> id,
      Value<int> partidoId,
      Value<String> anillo,
      Value<double> pesoGramos,
      Value<bool> esBase,
      Value<String?> color,
      Value<String?> observaciones,
    });

final class $$GallosTableReferences
    extends BaseReferences<_$AppDatabase, $GallosTable, GalloEntry> {
  $$GallosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PartidosTable _partidoIdTable(_$AppDatabase db) => db.partidos
      .createAlias($_aliasNameGenerator(db.gallos.partidoId, db.partidos.id));

  $$PartidosTableProcessedTableManager get partidoId {
    final $_column = $_itemColumn<int>('partido_id')!;

    final manager = $$PartidosTableTableManager(
      $_db,
      $_db.partidos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_partidoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GallosTableFilterComposer
    extends Composer<_$AppDatabase, $GallosTable> {
  $$GallosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anillo => $composableBuilder(
    column: $table.anillo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoGramos => $composableBuilder(
    column: $table.pesoGramos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esBase => $composableBuilder(
    column: $table.esBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnFilters(column),
  );

  $$PartidosTableFilterComposer get partidoId {
    final $$PartidosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoId,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableFilterComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GallosTableOrderingComposer
    extends Composer<_$AppDatabase, $GallosTable> {
  $$GallosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anillo => $composableBuilder(
    column: $table.anillo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoGramos => $composableBuilder(
    column: $table.pesoGramos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esBase => $composableBuilder(
    column: $table.esBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnOrderings(column),
  );

  $$PartidosTableOrderingComposer get partidoId {
    final $$PartidosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoId,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableOrderingComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GallosTableAnnotationComposer
    extends Composer<_$AppDatabase, $GallosTable> {
  $$GallosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get anillo =>
      $composableBuilder(column: $table.anillo, builder: (column) => column);

  GeneratedColumn<double> get pesoGramos => $composableBuilder(
    column: $table.pesoGramos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get esBase =>
      $composableBuilder(column: $table.esBase, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => column,
  );

  $$PartidosTableAnnotationComposer get partidoId {
    final $$PartidosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoId,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableAnnotationComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GallosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GallosTable,
          GalloEntry,
          $$GallosTableFilterComposer,
          $$GallosTableOrderingComposer,
          $$GallosTableAnnotationComposer,
          $$GallosTableCreateCompanionBuilder,
          $$GallosTableUpdateCompanionBuilder,
          (GalloEntry, $$GallosTableReferences),
          GalloEntry,
          PrefetchHooks Function({bool partidoId})
        > {
  $$GallosTableTableManager(_$AppDatabase db, $GallosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GallosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GallosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GallosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> partidoId = const Value.absent(),
                Value<String> anillo = const Value.absent(),
                Value<double> pesoGramos = const Value.absent(),
                Value<bool> esBase = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
              }) => GallosCompanion(
                id: id,
                partidoId: partidoId,
                anillo: anillo,
                pesoGramos: pesoGramos,
                esBase: esBase,
                color: color,
                observaciones: observaciones,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int partidoId,
                required String anillo,
                required double pesoGramos,
                Value<bool> esBase = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
              }) => GallosCompanion.insert(
                id: id,
                partidoId: partidoId,
                anillo: anillo,
                pesoGramos: pesoGramos,
                esBase: esBase,
                color: color,
                observaciones: observaciones,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GallosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({partidoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (partidoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.partidoId,
                                referencedTable: $$GallosTableReferences
                                    ._partidoIdTable(db),
                                referencedColumn: $$GallosTableReferences
                                    ._partidoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GallosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GallosTable,
      GalloEntry,
      $$GallosTableFilterComposer,
      $$GallosTableOrderingComposer,
      $$GallosTableAnnotationComposer,
      $$GallosTableCreateCompanionBuilder,
      $$GallosTableUpdateCompanionBuilder,
      (GalloEntry, $$GallosTableReferences),
      GalloEntry,
      PrefetchHooks Function({bool partidoId})
    >;
typedef $$CompadresTableTableCreateCompanionBuilder =
    CompadresTableCompanion Function({
      Value<int> id,
      required int derbyId,
      required int partidoIdA,
      required int partidoIdB,
      Value<String?> motivo,
    });
typedef $$CompadresTableTableUpdateCompanionBuilder =
    CompadresTableCompanion Function({
      Value<int> id,
      Value<int> derbyId,
      Value<int> partidoIdA,
      Value<int> partidoIdB,
      Value<String?> motivo,
    });

final class $$CompadresTableTableReferences
    extends BaseReferences<_$AppDatabase, $CompadresTableTable, CompadreEntry> {
  $$CompadresTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DerbysTable _derbyIdTable(_$AppDatabase db) => db.derbys.createAlias(
    $_aliasNameGenerator(db.compadresTable.derbyId, db.derbys.id),
  );

  $$DerbysTableProcessedTableManager get derbyId {
    final $_column = $_itemColumn<int>('derby_id')!;

    final manager = $$DerbysTableTableManager(
      $_db,
      $_db.derbys,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_derbyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PartidosTable _partidoIdATable(_$AppDatabase db) =>
      db.partidos.createAlias(
        $_aliasNameGenerator(db.compadresTable.partidoIdA, db.partidos.id),
      );

  $$PartidosTableProcessedTableManager get partidoIdA {
    final $_column = $_itemColumn<int>('partido_id_a')!;

    final manager = $$PartidosTableTableManager(
      $_db,
      $_db.partidos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_partidoIdATable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PartidosTable _partidoIdBTable(_$AppDatabase db) =>
      db.partidos.createAlias(
        $_aliasNameGenerator(db.compadresTable.partidoIdB, db.partidos.id),
      );

  $$PartidosTableProcessedTableManager get partidoIdB {
    final $_column = $_itemColumn<int>('partido_id_b')!;

    final manager = $$PartidosTableTableManager(
      $_db,
      $_db.partidos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_partidoIdBTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompadresTableTableFilterComposer
    extends Composer<_$AppDatabase, $CompadresTableTable> {
  $$CompadresTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  $$DerbysTableFilterComposer get derbyId {
    final $$DerbysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableFilterComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PartidosTableFilterComposer get partidoIdA {
    final $$PartidosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoIdA,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableFilterComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PartidosTableFilterComposer get partidoIdB {
    final $$PartidosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoIdB,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableFilterComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompadresTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CompadresTableTable> {
  $$CompadresTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  $$DerbysTableOrderingComposer get derbyId {
    final $$DerbysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableOrderingComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PartidosTableOrderingComposer get partidoIdA {
    final $$PartidosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoIdA,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableOrderingComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PartidosTableOrderingComposer get partidoIdB {
    final $$PartidosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoIdB,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableOrderingComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompadresTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompadresTableTable> {
  $$CompadresTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  $$DerbysTableAnnotationComposer get derbyId {
    final $$DerbysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableAnnotationComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PartidosTableAnnotationComposer get partidoIdA {
    final $$PartidosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoIdA,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableAnnotationComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PartidosTableAnnotationComposer get partidoIdB {
    final $$PartidosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.partidoIdB,
      referencedTable: $db.partidos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartidosTableAnnotationComposer(
            $db: $db,
            $table: $db.partidos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompadresTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompadresTableTable,
          CompadreEntry,
          $$CompadresTableTableFilterComposer,
          $$CompadresTableTableOrderingComposer,
          $$CompadresTableTableAnnotationComposer,
          $$CompadresTableTableCreateCompanionBuilder,
          $$CompadresTableTableUpdateCompanionBuilder,
          (CompadreEntry, $$CompadresTableTableReferences),
          CompadreEntry,
          PrefetchHooks Function({
            bool derbyId,
            bool partidoIdA,
            bool partidoIdB,
          })
        > {
  $$CompadresTableTableTableManager(
    _$AppDatabase db,
    $CompadresTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompadresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompadresTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompadresTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> derbyId = const Value.absent(),
                Value<int> partidoIdA = const Value.absent(),
                Value<int> partidoIdB = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
              }) => CompadresTableCompanion(
                id: id,
                derbyId: derbyId,
                partidoIdA: partidoIdA,
                partidoIdB: partidoIdB,
                motivo: motivo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int derbyId,
                required int partidoIdA,
                required int partidoIdB,
                Value<String?> motivo = const Value.absent(),
              }) => CompadresTableCompanion.insert(
                id: id,
                derbyId: derbyId,
                partidoIdA: partidoIdA,
                partidoIdB: partidoIdB,
                motivo: motivo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompadresTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({derbyId = false, partidoIdA = false, partidoIdB = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (derbyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.derbyId,
                                    referencedTable:
                                        $$CompadresTableTableReferences
                                            ._derbyIdTable(db),
                                    referencedColumn:
                                        $$CompadresTableTableReferences
                                            ._derbyIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (partidoIdA) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.partidoIdA,
                                    referencedTable:
                                        $$CompadresTableTableReferences
                                            ._partidoIdATable(db),
                                    referencedColumn:
                                        $$CompadresTableTableReferences
                                            ._partidoIdATable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (partidoIdB) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.partidoIdB,
                                    referencedTable:
                                        $$CompadresTableTableReferences
                                            ._partidoIdBTable(db),
                                    referencedColumn:
                                        $$CompadresTableTableReferences
                                            ._partidoIdBTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CompadresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompadresTableTable,
      CompadreEntry,
      $$CompadresTableTableFilterComposer,
      $$CompadresTableTableOrderingComposer,
      $$CompadresTableTableAnnotationComposer,
      $$CompadresTableTableCreateCompanionBuilder,
      $$CompadresTableTableUpdateCompanionBuilder,
      (CompadreEntry, $$CompadresTableTableReferences),
      CompadreEntry,
      PrefetchHooks Function({bool derbyId, bool partidoIdA, bool partidoIdB})
    >;
typedef $$RondasTableCreateCompanionBuilder =
    RondasCompanion Function({
      Value<int> id,
      required int derbyId,
      required int numero,
      Value<bool> esRondaBase,
      Value<DateTime> fechaCreacion,
      Value<String> byePartidos,
      Value<String> doblesPartidos,
    });
typedef $$RondasTableUpdateCompanionBuilder =
    RondasCompanion Function({
      Value<int> id,
      Value<int> derbyId,
      Value<int> numero,
      Value<bool> esRondaBase,
      Value<DateTime> fechaCreacion,
      Value<String> byePartidos,
      Value<String> doblesPartidos,
    });

final class $$RondasTableReferences
    extends BaseReferences<_$AppDatabase, $RondasTable, Ronda> {
  $$RondasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DerbysTable _derbyIdTable(_$AppDatabase db) => db.derbys.createAlias(
    $_aliasNameGenerator(db.rondas.derbyId, db.derbys.id),
  );

  $$DerbysTableProcessedTableManager get derbyId {
    final $_column = $_itemColumn<int>('derby_id')!;

    final manager = $$DerbysTableTableManager(
      $_db,
      $_db.derbys,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_derbyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EnfrentamientosTable, List<Enfrentamiento>>
  _enfrentamientosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.enfrentamientos,
    aliasName: $_aliasNameGenerator(db.rondas.id, db.enfrentamientos.rondaId),
  );

  $$EnfrentamientosTableProcessedTableManager get enfrentamientosRefs {
    final manager = $$EnfrentamientosTableTableManager(
      $_db,
      $_db.enfrentamientos,
    ).filter((f) => f.rondaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _enfrentamientosRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RondasTableFilterComposer
    extends Composer<_$AppDatabase, $RondasTable> {
  $$RondasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esRondaBase => $composableBuilder(
    column: $table.esRondaBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get byePartidos => $composableBuilder(
    column: $table.byePartidos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doblesPartidos => $composableBuilder(
    column: $table.doblesPartidos,
    builder: (column) => ColumnFilters(column),
  );

  $$DerbysTableFilterComposer get derbyId {
    final $$DerbysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableFilterComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> enfrentamientosRefs(
    Expression<bool> Function($$EnfrentamientosTableFilterComposer f) f,
  ) {
    final $$EnfrentamientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enfrentamientos,
      getReferencedColumn: (t) => t.rondaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnfrentamientosTableFilterComposer(
            $db: $db,
            $table: $db.enfrentamientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RondasTableOrderingComposer
    extends Composer<_$AppDatabase, $RondasTable> {
  $$RondasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esRondaBase => $composableBuilder(
    column: $table.esRondaBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byePartidos => $composableBuilder(
    column: $table.byePartidos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doblesPartidos => $composableBuilder(
    column: $table.doblesPartidos,
    builder: (column) => ColumnOrderings(column),
  );

  $$DerbysTableOrderingComposer get derbyId {
    final $$DerbysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableOrderingComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RondasTableAnnotationComposer
    extends Composer<_$AppDatabase, $RondasTable> {
  $$RondasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<bool> get esRondaBase => $composableBuilder(
    column: $table.esRondaBase,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get byePartidos => $composableBuilder(
    column: $table.byePartidos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doblesPartidos => $composableBuilder(
    column: $table.doblesPartidos,
    builder: (column) => column,
  );

  $$DerbysTableAnnotationComposer get derbyId {
    final $$DerbysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.derbyId,
      referencedTable: $db.derbys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DerbysTableAnnotationComposer(
            $db: $db,
            $table: $db.derbys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> enfrentamientosRefs<T extends Object>(
    Expression<T> Function($$EnfrentamientosTableAnnotationComposer a) f,
  ) {
    final $$EnfrentamientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enfrentamientos,
      getReferencedColumn: (t) => t.rondaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnfrentamientosTableAnnotationComposer(
            $db: $db,
            $table: $db.enfrentamientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RondasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RondasTable,
          Ronda,
          $$RondasTableFilterComposer,
          $$RondasTableOrderingComposer,
          $$RondasTableAnnotationComposer,
          $$RondasTableCreateCompanionBuilder,
          $$RondasTableUpdateCompanionBuilder,
          (Ronda, $$RondasTableReferences),
          Ronda,
          PrefetchHooks Function({bool derbyId, bool enfrentamientosRefs})
        > {
  $$RondasTableTableManager(_$AppDatabase db, $RondasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RondasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RondasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RondasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> derbyId = const Value.absent(),
                Value<int> numero = const Value.absent(),
                Value<bool> esRondaBase = const Value.absent(),
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<String> byePartidos = const Value.absent(),
                Value<String> doblesPartidos = const Value.absent(),
              }) => RondasCompanion(
                id: id,
                derbyId: derbyId,
                numero: numero,
                esRondaBase: esRondaBase,
                fechaCreacion: fechaCreacion,
                byePartidos: byePartidos,
                doblesPartidos: doblesPartidos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int derbyId,
                required int numero,
                Value<bool> esRondaBase = const Value.absent(),
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<String> byePartidos = const Value.absent(),
                Value<String> doblesPartidos = const Value.absent(),
              }) => RondasCompanion.insert(
                id: id,
                derbyId: derbyId,
                numero: numero,
                esRondaBase: esRondaBase,
                fechaCreacion: fechaCreacion,
                byePartidos: byePartidos,
                doblesPartidos: doblesPartidos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RondasTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({derbyId = false, enfrentamientosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (enfrentamientosRefs) db.enfrentamientos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (derbyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.derbyId,
                                    referencedTable: $$RondasTableReferences
                                        ._derbyIdTable(db),
                                    referencedColumn: $$RondasTableReferences
                                        ._derbyIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (enfrentamientosRefs)
                        await $_getPrefetchedData<
                          Ronda,
                          $RondasTable,
                          Enfrentamiento
                        >(
                          currentTable: table,
                          referencedTable: $$RondasTableReferences
                              ._enfrentamientosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RondasTableReferences(
                                db,
                                table,
                                p0,
                              ).enfrentamientosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rondaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RondasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RondasTable,
      Ronda,
      $$RondasTableFilterComposer,
      $$RondasTableOrderingComposer,
      $$RondasTableAnnotationComposer,
      $$RondasTableCreateCompanionBuilder,
      $$RondasTableUpdateCompanionBuilder,
      (Ronda, $$RondasTableReferences),
      Ronda,
      PrefetchHooks Function({bool derbyId, bool enfrentamientosRefs})
    >;
typedef $$EnfrentamientosTableCreateCompanionBuilder =
    EnfrentamientosCompanion Function({
      Value<int> id,
      required int rondaId,
      required int galloAId,
      Value<int?> galloBId,
      required double diferenciaPeso,
      Value<String?> resultado,
      Value<bool> esManual,
    });
typedef $$EnfrentamientosTableUpdateCompanionBuilder =
    EnfrentamientosCompanion Function({
      Value<int> id,
      Value<int> rondaId,
      Value<int> galloAId,
      Value<int?> galloBId,
      Value<double> diferenciaPeso,
      Value<String?> resultado,
      Value<bool> esManual,
    });

final class $$EnfrentamientosTableReferences
    extends
        BaseReferences<_$AppDatabase, $EnfrentamientosTable, Enfrentamiento> {
  $$EnfrentamientosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RondasTable _rondaIdTable(_$AppDatabase db) => db.rondas.createAlias(
    $_aliasNameGenerator(db.enfrentamientos.rondaId, db.rondas.id),
  );

  $$RondasTableProcessedTableManager get rondaId {
    final $_column = $_itemColumn<int>('ronda_id')!;

    final manager = $$RondasTableTableManager(
      $_db,
      $_db.rondas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rondaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GallosTable _galloAIdTable(_$AppDatabase db) => db.gallos.createAlias(
    $_aliasNameGenerator(db.enfrentamientos.galloAId, db.gallos.id),
  );

  $$GallosTableProcessedTableManager get galloAId {
    final $_column = $_itemColumn<int>('gallo_a_id')!;

    final manager = $$GallosTableTableManager(
      $_db,
      $_db.gallos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_galloAIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GallosTable _galloBIdTable(_$AppDatabase db) => db.gallos.createAlias(
    $_aliasNameGenerator(db.enfrentamientos.galloBId, db.gallos.id),
  );

  $$GallosTableProcessedTableManager? get galloBId {
    final $_column = $_itemColumn<int>('gallo_b_id');
    if ($_column == null) return null;
    final manager = $$GallosTableTableManager(
      $_db,
      $_db.gallos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_galloBIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EnfrentamientosTableFilterComposer
    extends Composer<_$AppDatabase, $EnfrentamientosTable> {
  $$EnfrentamientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diferenciaPeso => $composableBuilder(
    column: $table.diferenciaPeso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultado => $composableBuilder(
    column: $table.resultado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esManual => $composableBuilder(
    column: $table.esManual,
    builder: (column) => ColumnFilters(column),
  );

  $$RondasTableFilterComposer get rondaId {
    final $$RondasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rondaId,
      referencedTable: $db.rondas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RondasTableFilterComposer(
            $db: $db,
            $table: $db.rondas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GallosTableFilterComposer get galloAId {
    final $$GallosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.galloAId,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableFilterComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GallosTableFilterComposer get galloBId {
    final $$GallosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.galloBId,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableFilterComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnfrentamientosTableOrderingComposer
    extends Composer<_$AppDatabase, $EnfrentamientosTable> {
  $$EnfrentamientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diferenciaPeso => $composableBuilder(
    column: $table.diferenciaPeso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultado => $composableBuilder(
    column: $table.resultado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esManual => $composableBuilder(
    column: $table.esManual,
    builder: (column) => ColumnOrderings(column),
  );

  $$RondasTableOrderingComposer get rondaId {
    final $$RondasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rondaId,
      referencedTable: $db.rondas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RondasTableOrderingComposer(
            $db: $db,
            $table: $db.rondas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GallosTableOrderingComposer get galloAId {
    final $$GallosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.galloAId,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableOrderingComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GallosTableOrderingComposer get galloBId {
    final $$GallosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.galloBId,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableOrderingComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnfrentamientosTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnfrentamientosTable> {
  $$EnfrentamientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get diferenciaPeso => $composableBuilder(
    column: $table.diferenciaPeso,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultado =>
      $composableBuilder(column: $table.resultado, builder: (column) => column);

  GeneratedColumn<bool> get esManual =>
      $composableBuilder(column: $table.esManual, builder: (column) => column);

  $$RondasTableAnnotationComposer get rondaId {
    final $$RondasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rondaId,
      referencedTable: $db.rondas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RondasTableAnnotationComposer(
            $db: $db,
            $table: $db.rondas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GallosTableAnnotationComposer get galloAId {
    final $$GallosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.galloAId,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableAnnotationComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GallosTableAnnotationComposer get galloBId {
    final $$GallosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.galloBId,
      referencedTable: $db.gallos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GallosTableAnnotationComposer(
            $db: $db,
            $table: $db.gallos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnfrentamientosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnfrentamientosTable,
          Enfrentamiento,
          $$EnfrentamientosTableFilterComposer,
          $$EnfrentamientosTableOrderingComposer,
          $$EnfrentamientosTableAnnotationComposer,
          $$EnfrentamientosTableCreateCompanionBuilder,
          $$EnfrentamientosTableUpdateCompanionBuilder,
          (Enfrentamiento, $$EnfrentamientosTableReferences),
          Enfrentamiento,
          PrefetchHooks Function({bool rondaId, bool galloAId, bool galloBId})
        > {
  $$EnfrentamientosTableTableManager(
    _$AppDatabase db,
    $EnfrentamientosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnfrentamientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnfrentamientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnfrentamientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> rondaId = const Value.absent(),
                Value<int> galloAId = const Value.absent(),
                Value<int?> galloBId = const Value.absent(),
                Value<double> diferenciaPeso = const Value.absent(),
                Value<String?> resultado = const Value.absent(),
                Value<bool> esManual = const Value.absent(),
              }) => EnfrentamientosCompanion(
                id: id,
                rondaId: rondaId,
                galloAId: galloAId,
                galloBId: galloBId,
                diferenciaPeso: diferenciaPeso,
                resultado: resultado,
                esManual: esManual,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int rondaId,
                required int galloAId,
                Value<int?> galloBId = const Value.absent(),
                required double diferenciaPeso,
                Value<String?> resultado = const Value.absent(),
                Value<bool> esManual = const Value.absent(),
              }) => EnfrentamientosCompanion.insert(
                id: id,
                rondaId: rondaId,
                galloAId: galloAId,
                galloBId: galloBId,
                diferenciaPeso: diferenciaPeso,
                resultado: resultado,
                esManual: esManual,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EnfrentamientosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({rondaId = false, galloAId = false, galloBId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (rondaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rondaId,
                                    referencedTable:
                                        $$EnfrentamientosTableReferences
                                            ._rondaIdTable(db),
                                    referencedColumn:
                                        $$EnfrentamientosTableReferences
                                            ._rondaIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (galloAId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.galloAId,
                                    referencedTable:
                                        $$EnfrentamientosTableReferences
                                            ._galloAIdTable(db),
                                    referencedColumn:
                                        $$EnfrentamientosTableReferences
                                            ._galloAIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (galloBId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.galloBId,
                                    referencedTable:
                                        $$EnfrentamientosTableReferences
                                            ._galloBIdTable(db),
                                    referencedColumn:
                                        $$EnfrentamientosTableReferences
                                            ._galloBIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EnfrentamientosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnfrentamientosTable,
      Enfrentamiento,
      $$EnfrentamientosTableFilterComposer,
      $$EnfrentamientosTableOrderingComposer,
      $$EnfrentamientosTableAnnotationComposer,
      $$EnfrentamientosTableCreateCompanionBuilder,
      $$EnfrentamientosTableUpdateCompanionBuilder,
      (Enfrentamiento, $$EnfrentamientosTableReferences),
      Enfrentamiento,
      PrefetchHooks Function({bool rondaId, bool galloAId, bool galloBId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DerbysTableTableManager get derbys =>
      $$DerbysTableTableManager(_db, _db.derbys);
  $$PartidosTableTableManager get partidos =>
      $$PartidosTableTableManager(_db, _db.partidos);
  $$GallosTableTableManager get gallos =>
      $$GallosTableTableManager(_db, _db.gallos);
  $$CompadresTableTableTableManager get compadresTable =>
      $$CompadresTableTableTableManager(_db, _db.compadresTable);
  $$RondasTableTableManager get rondas =>
      $$RondasTableTableManager(_db, _db.rondas);
  $$EnfrentamientosTableTableManager get enfrentamientos =>
      $$EnfrentamientosTableTableManager(_db, _db.enfrentamientos);
}
