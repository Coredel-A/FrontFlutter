import 'orden_detalle.dart';

class Orden {
  final int id;
  final String usuario;
  final int usuarioId;
  final String fechaCreacion;
  final String estado;
  final String tipoEnvio;
  final String formaPago;
  final double total;
  final String seguimiento;
  final List<OrdenDetalle> detalles;

  Orden({
    required this.id,
    required this.usuario,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.estado,
    required this.tipoEnvio,
    required this.formaPago,
    required this.total,
    required this.seguimiento,
    required this.detalles,
  });

  factory Orden.fromJson(Map<String, dynamic> json) {
    var detallesJson = json['detalles'] as List;
    List<OrdenDetalle> detallesList =
        detallesJson.map((e) => OrdenDetalle.fromJson(e)).toList();

    return Orden(
      id: json['id'],
      usuario: json['usuario'],
      usuarioId: json['usuario_id'],
      fechaCreacion: json['fecha_creacion'],
      estado: json['estado'],
      tipoEnvio: json['tipo_envio'],
      formaPago: json['forma_pago'],
      total: json['total'].toDouble(),
      seguimiento: json['seguimiento'],
      detalles: detallesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'estado': estado,
      'tipo_envio': tipoEnvio,
      'forma_pago': formaPago,
      'total': total,
      'seguimiento': seguimiento,
      'detalles': detalles.map((e) => e.toJson()).toList(),
    };
  }
}

