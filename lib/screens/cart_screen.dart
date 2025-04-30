import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../models/orden_detalle_item.dart';
import '../screens/payment_screen.dart';
import '../widgets/product_recommendation_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        actions: [
          if (cartProvider.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('¿Estás seguro?'),
                        content: const Text('¿Deseas vaciar el carrito?'),
                        actions: [
                          TextButton(
                            child: const Text('No'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Sí'),
                            onPressed: () {
                              cartProvider.clear();
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          cartProvider.itemCount == 0
              ? const Center(
                child: Text(
                  'El carrito está vacío',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartProvider.items.length,
                          itemBuilder: (ctx, i) {
                            final cartItem =
                                cartProvider.items.values.toList()[i];
                            final product = cartItem.producto;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 4,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: ListTile(
                                  leading:
                                      product.imagen != null
                                          ? Image.network(
                                            product.imagen!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.image_not_supported,
                                                size: 50,
                                              );
                                            },
                                          )
                                          : const Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                          ),
                                  title: Text(product.nombre),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Precio: \$${product.precio.toStringAsFixed(2)}',
                                      ),
                                      Text(
                                        'Subtotal: \$${cartItem.subtotal.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                  trailing: SizedBox(
                                    width: 120,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            cartProvider.decrementItem(
                                              product.id,
                                            );
                                          },
                                        ),
                                        Text('${cartItem.cantidad}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            cartProvider.addItem(product);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (cartProvider.itemCount > 0)
                          const ProductRecommendationWidget(),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total (${cartProvider.totalItems} items):',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              final isLoggedIn =
                                  await apiService.isUserLoggedIn();

                              if (!isLoggedIn) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Debes iniciar sesión para realizar una compra',
                                    ),
                                  ),
                                );
                                Navigator.pushNamed(context, '/login');
                                return;
                              }
                              _showCheckoutDialog(
                                context,
                                cartProvider,
                                apiService,
                              );
                            },
                            child: const Text(
                              'PROCEDER AL PAGO',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  void _showCheckoutDialog(
    BuildContext context,
    CartProvider cartProvider,
    ApiService apiService,
  ) {
    String tipoEnvio = 'domicilio';
    String formaPago = 'efectivo';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Finalizar Compra'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Método de envío:'),
                        RadioListTile<String>(
                          title: const Text('Envío a domicilio'),
                          value: 'domicilio',
                          groupValue: tipoEnvio,
                          onChanged: (value) {
                            setState(() {
                              tipoEnvio = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Recoger en tienda'),
                          value: 'sucursal',
                          groupValue: tipoEnvio,
                          onChanged: (value) {
                            setState(() {
                              tipoEnvio = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Forma de pago:'),
                        RadioListTile<String>(
                          title: const Text('Efectivo'),
                          value: 'efectivo',
                          groupValue: formaPago,
                          onChanged: (value) {
                            setState(() {
                              formaPago = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text(
                            'Tarjeta de crédito/débito (Stripe)',
                          ),
                          value: 'tarjeta',
                          groupValue: formaPago,
                          onChanged: (value) {
                            setState(() {
                              formaPago = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Transferencia bancaria'),
                          value: 'transferencia',
                          groupValue: formaPago,
                          onChanged: (value) {
                            setState(() {
                              formaPago = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Confirmar Compra'),
                      onPressed: () async {
                        final detalles =
                            cartProvider.items.values
                                .map(
                                  (item) => OrdenDetalleItem(
                                    productoId: item.producto.id,
                                    cantidad: item.cantidad,
                                    precioUnitario: item.producto.precio,
                                  ),
                                )
                                .toList();
                        if (formaPago == 'tarjeta') {
                          Navigator.of(ctx).pop();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => StripePaymentScreen(
                                    amount: cartProvider.totalAmount,
                                    items: detalles,
                                    tipoEnvio: tipoEnvio,
                                  ),
                            ),
                          );
                          return;
                        }
                        try {
                          final usuario = await apiService.getUserProfile();

                          final ordenId = await apiService.createOrder(
                            usuario.id,
                            detalles,
                            tipoEnvio,
                            formaPago,
                          );

                          if (!context.mounted) return;

                          cartProvider.clear();

                          Navigator.of(ctx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '¡Compra exitosa! Orden #$ordenId creada.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) return;

                          Navigator.of(ctx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al procesar la compra: $error',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }
}
