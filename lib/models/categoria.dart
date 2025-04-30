class Categoria {
  final int id;
  final String nombre;
  final String descripcion;
  final String? imagen;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagen,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      imagen: json['imagen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen': imagen,
    };
  }
}
