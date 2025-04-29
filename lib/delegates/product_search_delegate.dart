import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

class ProductSearchDelegate extends SearchDelegate<int?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Ingresa un término para buscar productos'),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return FutureBuilder<List<Producto>>(
      future: apiService.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No se encontraron productos'),
          );
        } else {
          final productos = snapshot.data!;
          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ListTile(
                leading: producto.imagen != null
                    ? Image.network(
                        producto.imagen!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(producto.nombre),
                subtitle: Text('${producto.marca} - \$${producto.precio}'),
                onTap: () {
                  // Devolvemos el ID del producto seleccionado
                  close(context, producto.id);
                },
              );
            },
          );
        }
      },
    );
  }
}