class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String direccion;
  final double saldo;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.direccion = '',
    this.saldo = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'saldo': saldo,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
      direccion: map['direccion']?.toString() ?? '',
      saldo: (map['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Cliente copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? direccion,
    double? saldo,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      saldo: saldo ?? this.saldo,
    );
  }
}



