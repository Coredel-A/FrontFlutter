// Crear un nuevo archivo: lib/widgets/product_recommendation_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';

class ProductRecommendationWidget extends StatefulWidget {
  const ProductRecommendationWidget({Key? key}) : super(key: key);

  @override
  State<ProductRecommendationWidget> createState() =>
      _ProductRecommendationWidgetState();
}

class _ProductRecommendationWidgetState
    extends State<ProductRecommendationWidget> {
  late Future<List<Producto>> _recommendedProductsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cartProvider = Provider.of<CartProvider>(context);
    if (cartProvider.itemCount > 0) {
      _loadRecommendations();
    }
  }

  void _loadRecommendations() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    if (cartProvider.itemCount > 0) {
      setState(() => _isLoading = true);

      final productIds = cartProvider.items.keys.toList();

      _recommendedProductsFuture = apiService.getRecommendedProducts(
        productIds,
      );

      _recommendedProductsFuture
          .then((_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            print('Error cargando recomendaciones: $error');
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    if (cartProvider.itemCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recomendados para ti',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _isLoading
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
            : FutureBuilder<List<Producto>>(
              future: _recommendedProductsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error al cargar recomendaciones'),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay recomendaciones disponibles'),
                    ),
                  );
                } else {
                  final recommendations = snapshot.data!;
                  final limitedRecommendations =
                      recommendations.length > 4
                          ? recommendations.sublist(0, 4)
                          : recommendations;

                  return SizedBox(
                    height: 235,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: limitedRecommendations.length,
                      itemBuilder: (ctx, index) {
                        final producto = limitedRecommendations[index];
                        return SizedBox(
                          width: 160,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ProductCard(
                              producto: producto,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/product-detail',
                                  arguments: producto.id,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
      ],
    );
  }
}
