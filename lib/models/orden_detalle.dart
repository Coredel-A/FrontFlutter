class OrdenDetalle {
  final int id;
  final String producto; 
  final int productoId;
  final int cantidad;
  final double precioUnitario;

  OrdenDetalle({
    required this.id,
    required this.producto,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory OrdenDetalle.fromJson(Map<String, dynamic> json) {
    return OrdenDetalle(
      id: json['id'],
      producto: json['producto'],
      productoId: json['producto_id'],
      cantidad: json['cantidad'],
      precioUnitario: json['precio_unitario'].toDouble(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
    };
  }
}
