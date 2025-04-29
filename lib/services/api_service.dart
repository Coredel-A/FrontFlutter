// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart';
import '../models/categoria.dart';
import '../models/usuario.dart';
import '../models/orden_detalle_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.100.209:8000/api';
  String? accessToken;
  String? refreshToken;

  // Método para guardar tokens y datos de usuario
  Future<void> _saveUserSession(String accessToken, String refreshToken, Usuario user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    
    // Guardar datos básicos del usuario
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.nombre);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.rol);
    
    // Actualiza el token en la instancia actual
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  // Método para verificar si hay un usuario autenticado
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

  // Método para cerrar sesión
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

  // Iniciar sesión
  Future<Usuario> login(String email, String password, BuildContext context) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('BODY: ${response.body}');   

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final access = data['access'];
      final refresh = data['refresh'];
      final userData = data['user'];
      
      // Crear un objeto Usuario a partir de los datos recibidos
      final user = Usuario.fromJson(userData);
      
      // Guardar la sesión del usuario
      await _saveUserSession(access, refresh, user);
      
      return user;
    } else {
      // Manejar diferentes tipos de errores
      if (response.statusCode == 400) {
        throw Exception('Credenciales incorrectas');
      } else {
        throw Exception('Error al iniciar sesión');
      }
    }
  }

  // Registrar usuario
  Future<Usuario> register(String nombre, String email, String password, String telefono, BuildContext context) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/registro/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'telefono': telefono,
        'rol': 'cliente', // Por defecto asignamos rol cliente
      }),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      
      // Como el registro es exitoso, intentamos iniciar sesión automáticamente
      return await login(email, password, context);
    } else if (response.statusCode == 400) {
      // Intentar obtener el mensaje de error específico
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

  // Añadir método para obtener datos del perfil
  Future<Usuario> getUserProfile() async {
    // Verificar si hay token primero
    final isLoggedIn = await isUserLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Usuario no autenticado');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      // Token inválido o expirado, intentar refrescar el token
      try {
        await _refreshAuthToken();
        // Reintentar la solicitud con el nuevo token
        return await getUserProfile();
      } catch (e) {
        // Si no se puede refrescar, cerrar sesión
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al obtener perfil de usuario');
    }
  }

  // Método para refrescar el token
  Future<void> _refreshAuthToken() async {
    if (refreshToken == null) {
      throw Exception('No hay token de refresco disponible');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'refresh': refreshToken,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['access'];
      
      // Actualizar el token en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newAccessToken);
      
      // Actualizar el token en la instancia actual
      accessToken = newAccessToken;
    } else {
      // Si no se puede refrescar, forzar cierre de sesión
      await logout();
      throw Exception('No se pudo refrescar la sesión');
    }
  }

  // Obtener categorías
  Future<List<Categoria>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/productos/categorias'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Categoria.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  // Obtener productos
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
      final response = await http.get(Uri.parse('$baseUrl/productos/productos/?categoria=$categoryId'));
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('Datos recibidos: $data');
        
        if (data is List) {
          // La respuesta es una lista directamente
          return data.map((json) => Producto.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('results')) {
          // La respuesta está paginada
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


  // Obtener producto por ID
  Future<Producto> getProductById(int productId) async {
    final response = await http.get(Uri.parse('$baseUrl/productos/productos/$productId/'));
    if (response.statusCode == 200) {
      return Producto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al cargar el producto');
    }
  }
  
  // Función para realizar la búsqueda de productos
  Future<List<Producto>> searchProducts(String query) async {
    try {
      // Agregar log para depuración
      print('API: Buscando productos con query: "$query"');
      
      // CORRECCIÓN: Usar parámetro de búsqueda correcto con ?search=
      // Importante: Codificar el query para manejar espacios y caracteres especiales
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$baseUrl/productos/productos/?search=$encodedQuery';
      
      print('API: URL de búsqueda: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Con http, decodificar el cuerpo de la respuesta desde JSON
        final List<dynamic> data = json.decode(response.body);
        final productos = data.map((json) => Producto.fromJson(json)).toList();
        
        // Log para depuración
        print('API: Encontrados ${productos.length} productos para "$query"');
        
        return productos;
      } else {
        print('API: Error en búsqueda - Código de estado ${response.statusCode}');
        print('API: Respuesta: ${response.body}');
        throw Exception('Error al buscar productos: ${response.statusCode}');
      }
    } catch (e) {
      print('API: Error en searchProducts: $e');
      
      // En caso de error, intentar con búsqueda menos estricta si es posible
      // Por ahora, solo devolvemos una lista vacía
      return [];
    }
  }
  // Crear orden
  Future<int> createOrder(int usuarioId, List<OrdenDetalleItem> detalles, String tipoEnvio, String formaPago) async {
    if (accessToken == null) throw Exception('Usuario no autenticado');

    final detalleMapeado = detalles.map((item) => item.toJson()).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/ordenes/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'usuario_id': usuarioId,
        'tipo_envio': tipoEnvio,
        'forma_pago': formaPago,
        'estado': 'pendiente',
        'detalles': detalleMapeado,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'];
    } else if (response.statusCode == 401) {
      // Token inválido o expirado, intentar refrescar
      try {
        await _refreshAuthToken();
        // Reintentar con el nuevo token
        return await createOrder(usuarioId, detalles, tipoEnvio, formaPago);
      } catch (e) {
        await logout();
        throw Exception('Sesión expirada, inicie sesión nuevamente');
      }
    } else {
      throw Exception('Error al crear orden');
    }
  }

  // Añadir a api_service.dart
  Future<String> createPaymentIntent(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ordenes/create-payment-intent/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': accessToken != null ? 'Bearer $accessToken' : '',
      },
      body: json.encode({
        'amount': amount, // El monto debe estar en centavos (100 = $1.00)
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['client_secret'];
    } else {
      throw Exception('Error al crear el intent de pago');
    }
  }

  // Obtener productos recomendados basados en los productos del carrito
  Future<List<Producto>> getRecommendedProducts(List<int> productIds) async {
    try {
      // Transforma los IDs a nombres para mantener compatibilidad con el backend
      final itemsInCart = await Future.wait(
        productIds.map((id) async {
          final producto = await getProductById(id);
          return producto.nombre;
        })
      );
      
      final response = await http.post(
        Uri.parse('$baseUrl/ordenes/sugerencias/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'productos': itemsInCart,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('sugerencias') && data['sugerencias'] is List) {
          List<dynamic> suggestions = data['sugerencias'];
          
          // Filtramos productos que ya están en el carrito
          final List<Producto> productos = suggestions
              .map((json) => Producto.fromJson(json))
              .where((producto) => !productIds.contains(producto.id))
              .toList();
          
          return productos;
        }
        return [];
      } else {
        print('Error al obtener recomendaciones: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Excepción al obtener recomendaciones: $e');
      // Si hay un error, regresamos una lista vacía en lugar de lanzar una excepción
      // para no interrumpir la experiencia del usuario
      return [];
    }
  }

}
