import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../models/orden_detalle_item.dart';

class StripePaymentScreen extends StatefulWidget {
  final double amount;
  final List<OrdenDetalleItem> items;
  final String tipoEnvio;

  const StripePaymentScreen({
    Key? key,
    required this.amount,
    required this.items,
    required this.tipoEnvio,
  }) : super(key: key);

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con Tarjeta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de la compra',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Productos: ${widget.items.length}'),
                    Text('Método de envío: ${widget.tipoEnvio}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total a pagar:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '\$${widget.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });

                      try {
                        // 1. Crear Payment Intent en el servidor
                        final amountInCents = (widget.amount * 100).round();
                        final clientSecret = await apiService.createPaymentIntent(amountInCents);

                        // 2. Configurar los datos del pago
                        await Stripe.instance.initPaymentSheet(
                          paymentSheetParameters: SetupPaymentSheetParameters(
                            paymentIntentClientSecret: clientSecret,
                            merchantDisplayName: 'Tu Tienda Online',
                            style: ThemeMode.system,
                          ),
                        );

                        // 3. Mostrar hoja de pago de Stripe
                        await Stripe.instance.presentPaymentSheet();

                        // 4. Pago completado con éxito, crear la orden
                        final usuario = await apiService.getUserProfile();
                        final ordenId = await apiService.createOrder(
                          usuario.id,
                          widget.items,
                          widget.tipoEnvio,
                          'tarjeta', // Forma de pago
                        );

                        if (!mounted) return;

                        // 5. Limpiar carrito y regresar
                        cartProvider.clear();
                        Navigator.of(context).popUntil((route) => route.isFirst);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Pago exitoso! Orden #$ordenId creada.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          _errorMessage = e.toString();
                          _isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'PAGAR AHORA',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}