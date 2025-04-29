class Categoria {
  final int id;
  final String nombre;
  final String descripcion;
  final String? imagen;  // Añadimos el campo imagen como opcional

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagen,  // Opcional porque puede ser null
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      imagen: json['imagen'],  // Capturamos la URL de la imagen
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
