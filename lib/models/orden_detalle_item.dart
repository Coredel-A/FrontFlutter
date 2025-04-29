class OrdenDetalleItem {
  final int productoId;
  final int cantidad;
  final double precioUnitario;

  OrdenDetalleItem({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
    };
  }
}
