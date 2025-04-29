class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final String pais;
  final String telefono;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.pais,
    required this.telefono,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      pais: json['pais'],
      telefono: json['telefono'],
    );
  }
}
