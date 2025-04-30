import 'categoria.dart';

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final String especificaciones;
  final String marca;
  final String modelo;
  final double precio;
  final Categoria categoria;
  final String? imagen;  // Cambiado de 'imagenes' a 'imagen' para coincidir con el backend
  final String estado;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.especificaciones,
    required this.marca,
    required this.modelo,
    required this.precio,
    required this.categoria,
    this.imagen,  // Ahora es opcional
    required this.estado,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      especificaciones: json['especificaciones'],
      marca: json['marca'],
      modelo: json['modelo'],
      precio: json['precio'] is String 
        ? double.parse(json['precio']) 
        : (json['precio'] as num).toDouble(),
      categoria: Categoria.fromJson(json['categoria']),
      imagen: json['imagen'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'especificaciones': especificaciones,
      'marca': marca,
      'modelo': modelo,
      'precio': precio,
      'categoria_id': categoria.id,  
      'imagen': imagen,
      'estado': estado,
    };
  }
}