class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String rol;
  final String? puesto;
  final int? sucursalId;
  final String estado;
  final String fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    required this.rol,
    this.puesto,
    this.sucursalId,
    required this.estado,
    required this.fechaRegistro,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      telefono: json['telefono'],
      rol: json['rol'],
      puesto: json['puesto'],
      sucursalId: json['sucursal'] != null ? json['sucursal'] : null,
      estado: json['estado'],
      fechaRegistro: json['fecha_registro'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'puesto': puesto,
      'sucursal': sucursalId,
      'estado': estado,
      'fecha_registro': fechaRegistro,
    };
  }
}
