class DireccionEnvio {
  final int id;
  final int usuarioId;
  final String direccion;
  final String ciudad;
  final String departamento;
  final String pais;
  final String codigoPostal;
  final String telefonoContacto;

  DireccionEnvio({
    required this.id,
    required this.usuarioId,
    required this.direccion,
    required this.ciudad,
    required this.departamento,
    required this.pais,
    required this.codigoPostal,
    required this.telefonoContacto,
  });

  factory DireccionEnvio.fromJson(Map<String, dynamic> json) {
    return DireccionEnvio(
      id: json['id'],
      usuarioId: json['usuario'] is int ? json['usuario'] : json['usuario']['id'],
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      departamento: json['departamento'],
      pais: json['pais'],
      codigoPostal: json['codigo_postal'],
      telefonoContacto: json['telefono_contacto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': usuarioId,
      'direccion': direccion,
      'ciudad': ciudad,
      'departamento': departamento,
      'pais': pais,
      'codigo_postal': codigoPostal,
      'telefono_contacto': telefonoContacto,
    };
  }
}
