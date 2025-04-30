import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart';
import '../models/categoria.dart';
import '../models/usuario.dart';
import '../models/orden_detalle_item.dart';
import '../models/sucursal.dart';
import '../models/direccion_envio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.100.209:8000/api';
  String? accessToken;
  String? refreshToken;

  Future<void> _saveUserSession(
    String accessToken,
    String refreshToken,
    Usuario user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);

    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.nombre);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.rol);

    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      accessToken = token;
      refreshToken = prefs.getString('refresh_token');
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    accessToken = null;
    refreshToken = null;
  }

  Future<Usuario> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final access = data['access'];
      final refresh = data['refresh'];
      final userData = data['user'];

      final user = Usuario.fromJson(userData);

      await _saveUserSession(access, refresh, user);

      return user;
    } else {
      if (response.statusCode == 400) {
        throw Exception('Credenciales incorrectas');
      } else {
        throw Exception('Error al iniciar sesión');
      }
    }
  }

  Future<Usuario> register(
    String nombre,
    String email,
    String password,
    String telefono,
    BuildContext context,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/registro/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'telefono': telefono,
        'rol': 'cliente',
      }),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 201) {
      final data = json.decode(response.body);

      return await login(email, password, context);
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      if (error.containsKey('email')) {
        throw Exception('El correo electrónico ya está en uso');
      } else {
        throw Exception('Error en los datos proporcionados');
      }
    } else {
      throw Exception('Error al registrar usuario');
    }
  }

  Future<Usuario> getUserProfile() async {
    final isLoggedIn = await isUserLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Usuario no autenticado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      try {
        await _refreshAuthToken();

        return await getUserProfile();
      } catch (e) {
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al obtener perfil de usuario');
    }
  }

  Future<void> _refreshAuthToken() async {
    if (refreshToken == null) {
      throw Exception('No hay token de refresco disponible');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['access'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newAccessToken);

      accessToken = newAccessToken;
    } else {
      await logout();
      throw Exception('No se pudo refrescar la sesión');
    }
  }

  Future<List<Categoria>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/productos/categorias'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Categoria.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  Future<List<Producto>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/productos/productos'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }

  Future<List<Producto>> getProductsByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/productos/productos/?categoria=$categoryId'),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('Datos recibidos: $data');

        if (data is List) {
          return data.map((json) => Producto.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('results')) {
          List<dynamic> productsData = data['results'];
          return productsData.map((json) => Producto.fromJson(json)).toList();
        } else {
          throw Exception('No se encontraron productos en esta categoría');
        }
      } else {
        throw Exception('Error al cargar productos por categoría');
      }
    } catch (e) {
      print('Error cargando datos: $e');
      throw Exception('Error al cargar productos: $e');
    }
  }

  Future<Producto> getProductById(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/productos/productos/$productId/'),
    );
    if (response.statusCode == 200) {
      return Producto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al cargar el producto');
    }
  }

  Future<List<Producto>> searchProducts(String query) async {
    try {
      print('API: Buscando productos con query: "$query"');

      final encodedQuery = Uri.encodeComponent(query);
      final url = '$baseUrl/productos/productos/?search=$encodedQuery';

      print('API: URL de búsqueda: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final productos = data.map((json) => Producto.fromJson(json)).toList();

        print('API: Encontrados ${productos.length} productos para "$query"');

        return productos;
      } else {
        print(
          'API: Error en búsqueda - Código de estado ${response.statusCode}',
        );
        print('API: Respuesta: ${response.body}');
        throw Exception('Error al buscar productos: ${response.statusCode}');
      }
    } catch (e) {
      print('API: Error en searchProducts: $e');

      return [];
    }
  }

  Future<List<DireccionEnvio>> getUserAddresses() async {
    if (accessToken == null) throw Exception('Usuario no autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/direcciones-envio/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DireccionEnvio.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      try {
        await _refreshAuthToken();
        return await getUserAddresses();
      } catch (e) {
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al obtener direcciones de envío');
    }
  }

  Future<int> createAddress(
    String direccion,
    String ciudad,
    String departamento,
    String pais,
    String codigoPostal,
    String telefonoContacto,
  ) async {
    if (accessToken == null) throw Exception('Usuario no autenticado');

    final Map<String, dynamic> body = {
      'direccion': direccion,
      'ciudad': ciudad,
      'departamento': departamento,
      'pais': pais,
      'codigo_postal': codigoPostal,
      'telefono_contacto': telefonoContacto,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/direcciones-envio/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'];
    } else if (response.statusCode == 401) {
      try {
        await _refreshAuthToken();
        return await createAddress(
          direccion,
          ciudad,
          departamento,
          pais,
          codigoPostal,
          telefonoContacto,
        );
      } catch (e) {
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al crear dirección de envío: ${response.body}');
    }
  }

  Future<int> createOrder(
    int usuarioId,
    List<OrdenDetalleItem> detalles,
    String tipoEnvio,
    String formaPago, {
    int? direccionId,
    int? sucursalId,
  }) async {
    if (accessToken == null) throw Exception('Usuario no autenticado');

    final detalleMapeado = detalles.map((item) => item.toJson()).toList();

    String backendTipoEnvio;
    if (tipoEnvio == 'domicilio') {
      backendTipoEnvio = 'envio';
    } else if (tipoEnvio == 'sucursal') {
      backendTipoEnvio = 'recoger';
    } else {
      backendTipoEnvio = tipoEnvio;
    }

    final Map<String, dynamic> body = {
      'usuario_id': usuarioId,
      'tipo_envio': backendTipoEnvio,
      'forma_pago': formaPago,
      'estado': 'pendiente',
      'detalles': detalleMapeado,
    };

    if (backendTipoEnvio == 'envio' && direccionId != null) {
      body['direccion_envio_id'] = direccionId;
    } else if (backendTipoEnvio == 'recoger' && sucursalId != null) {
      body['sucursal_retiro_id'] = sucursalId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/ordenes/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'];
    } else if (response.statusCode == 401) {
      try {
        await _refreshAuthToken();
        return await createOrder(
          usuarioId,
          detalles,
          tipoEnvio,
          formaPago,
          direccionId: direccionId,
          sucursalId: sucursalId,
        );
      } catch (e) {
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al crear orden: ${response.body}');
    }
  }

  Future<List<Sucursal>> getSucursales() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sucursales/sucursales/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is List) {
        return data.map((json) => Sucursal.fromJson(json)).toList();
      } else if (data is Map && data['results'] != null) {
        return (data['results'] as List)
            .map((json) => Sucursal.fromJson(json))
            .toList();
      } else {
        throw Exception('Formato inesperado de respuesta');
      }
    } else if (response.statusCode == 401) {
      try {
        await _refreshAuthToken();
        return await getSucursales();
      } catch (e) {
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al obtener sucursales');
    }
  }

  Future<String> createPaymentIntent(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ordenes/create-payment-intent/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': accessToken != null ? 'Bearer $accessToken' : '',
      },
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['client_secret'];
    } else {
      throw Exception('Error al crear el intent de pago');
    }
  }

  Future<List<Producto>> getRecommendedProducts(List<int> productIds) async {
    try {
      final isLoggedIn = await isUserLoggedIn();
      if (!isLoggedIn) {
        print('Error: Usuario no autenticado para obtener recomendaciones.');
        return [];
      }

      final itemsInCart = await Future.wait(
        productIds.map((id) async {
          final producto = await getProductById(id);
          return producto.nombre;
        }),
      );

      final response = await http.post(
        Uri.parse('$baseUrl/ordenes/sugerencias/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({'productos': itemsInCart}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('sugerencias') && data['sugerencias'] is List) {
          List<dynamic> suggestions = data['sugerencias'];

          final List<Producto> productos =
              suggestions
                  .map((json) => Producto.fromJson(json))
                  .where((producto) => !productIds.contains(producto.id))
                  .toList();

          return productos;
        }
        return [];
      } else if (response.statusCode == 401) {
        try {
          await _refreshAuthToken();
          return await getRecommendedProducts(productIds);
        } catch (e) {
          print('Error al renovar token: $e');
          await logout();
          return [];
        }
      } else {
        print(
          'Error al obtener recomendaciones: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Excepción al obtener recomendaciones: $e');
      return [];
    }
  }
}
