import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  ProductDetailScreenState createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends State<ProductDetailScreen> {
  Producto? producto;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final loadedProduct = await apiService.getProductById(widget.productId);
      setState(() {
        producto = loadedProduct;
      });
    } catch (e) {
      print('Error loading product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body:
          producto == null
              ? const Center(child: CircularProgressIndicator())
              : _buildProductDetail(context, producto!, cartProvider),
    );
  }

  Widget _buildProductDetail(
    BuildContext context,
    Producto producto,
    CartProvider cartProvider,
  ) {
    final bool isInCart = cartProvider.isInCart(producto.id);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.imagen != null)
              Center(
                child: Image.network(
                  producto.imagen!,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 200);
                  },
                ),
              ),

            const SizedBox(height: 16),

            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Marca: ${producto.marca}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Modelo: ${producto.modelo}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Precio: \$${producto.precio.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text('Descripción', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 8),

            Text(producto.descripcion),

            const SizedBox(height: 16),

            Text(
              'Especificaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(producto.especificaciones),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(isInCart ? Icons.check : Icons.add_shopping_cart),
                label: Text(isInCart ? 'En el carrito' : 'Añadir al carrito'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (!isInCart) {
                    cartProvider.addItem(producto);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('¡Producto añadido al carrito!'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'VER CARRITO',
                          onPressed: () {
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/cart');
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                child: const Text('Comprar ahora'),
                onPressed: () {
                  if (!isInCart) {
                    cartProvider.addItem(producto);
                  }
                  Navigator.pushNamed(context, '/cart');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
