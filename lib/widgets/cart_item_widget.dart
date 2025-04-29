import 'package:flutter/material.dart';
import '../models/cart_item.dart'; // Modelo de CartItem

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;

  const CartItemWidget(this.cartItem);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(cartItem.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
      title: Text(cartItem.name),
      subtitle: Text('\$${cartItem.price.toStringAsFixed(2)}'),
      trailing: Text('x${cartItem.quantity}'),
    );
  }
}
