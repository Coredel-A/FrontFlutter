import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../models/orden_detalle_item.dart';
import '../models/sucursal.dart';
import '../models/direccion_envio.dart';

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
  String? _direccion;
  int? _direccionSeleccionadaId;
  int? _sucursalSeleccionada;
  List<Sucursal> _sucursales = [];
  List<DireccionEnvio> _direcciones = [];

  @override
  void initState() {
    super.initState();
    if (widget.tipoEnvio == 'sucursal') {
      _cargarSucursales();
    } else if (widget.tipoEnvio == 'domicilio') {
      _cargarDirecciones();
    }
  }

  Future<void> _cargarDirecciones() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final direcciones = await apiService.getUserAddresses();
      setState(() {
        _direcciones = direcciones;
        if (_direcciones.isNotEmpty) {
          _direccionSeleccionadaId = _direcciones.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar direcciones: $e';
      });
    }
  }

  Future<void> _cargarSucursales() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final sucursales = await apiService.getSucursales();
      setState(() {
        _sucursales = sucursales;
        if (_sucursales.isNotEmpty) {
          _sucursalSeleccionada = _sucursales.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar sucursales: $e';
      });
    }
  }

  Widget _buildDireccionEnvioUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dirección de envío:'),
        const SizedBox(height: 8),
        if (_direcciones.isNotEmpty) ...[
          DropdownButtonFormField<int>(
            value: _direccionSeleccionadaId,
            items:
                _direcciones
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text('${d.direccion}, ${d.ciudad}'),
                      ),
                    )
                    .toList(),
            onChanged:
                (value) => setState(() {
                  _direccionSeleccionadaId = value;
                }),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Seleccionar dirección guardada',
            ),
          ),
          const SizedBox(height: 8),
          Text('O ingrese una nueva dirección:'),
        ],
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ingrese su dirección',
          ),
          onChanged: (value) => _direccion = value,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Pago con Tarjeta')),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${widget.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.tipoEnvio == 'domicilio') ...[
              _buildDireccionEnvioUI(),
            ] else if (widget.tipoEnvio == 'sucursal') ...[
              const Text('Seleccionar sucursal:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _sucursalSeleccionada,
                items:
                    _sucursales
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nombre),
                          ),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() {
                      _sucursalSeleccionada = value;
                    }),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
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
              onPressed:
                  _isLoading
                      ? null
                      : () async {
                        if (widget.tipoEnvio == 'domicilio') {
                          if ((_direccionSeleccionadaId == null ||
                                  _direcciones.isEmpty) &&
                              (_direccion == null ||
                                  _direccion!.trim().isEmpty)) {
                            setState(() {
                              _errorMessage =
                                  'Por favor seleccione o ingrese una dirección de envío.';
                            });
                            return;
                          }
                          if (_direccion != null &&
                              _direccion!.trim().isNotEmpty &&
                              _direccionSeleccionadaId == null) {}
                        } else if (widget.tipoEnvio == 'sucursal') {
                          if (_sucursalSeleccionada == null) {
                            setState(() {
                              _errorMessage =
                                  'Por favor selecciona una sucursal.';
                            });
                            return;
                          }
                        }
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        try {
                          final amountInCents = (widget.amount * 100).round();
                          final clientSecret = await apiService
                              .createPaymentIntent(amountInCents);
                          await Stripe.instance.initPaymentSheet(
                            paymentSheetParameters: SetupPaymentSheetParameters(
                              paymentIntentClientSecret: clientSecret,
                              merchantDisplayName: 'Tu Tienda Online',
                              style: ThemeMode.system,
                            ),
                          );

                          await Stripe.instance.presentPaymentSheet();

                          final usuario = await apiService.getUserProfile();
                          final ordenId = await apiService.createOrder(
                            usuario.id,
                            widget.items,
                            widget.tipoEnvio,
                            'tarjeta',
                            direccionId: _direccionSeleccionadaId,
                            sucursalId: _sucursalSeleccionada,
                          );

                          if (!mounted) return;

                          cartProvider.clear();
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '¡Pago exitoso! Orden #$ordenId creada.',
                              ),
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
              child:
                  _isLoading
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
