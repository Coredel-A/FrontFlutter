import 'package:flutter/foundation.dart';
import '../models/producto.dart';

class CartItem {
  final Producto producto;
  int cantidad;

  CartItem({required this.producto, this.cantidad = 1});

  double get subtotal => producto.precio * cantidad;
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  int get totalItems {
    return _items.values.fold(0, (sum, item) => sum + item.cantidad);
  }

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  bool isInCart(int productId) {
    return _items.containsKey(productId);
  }

  void addItem(Producto producto, {int cantidad = 1}) {
    if (_items.containsKey(producto.id)) {
      _items.update(
        producto.id,
        (existingItem) => CartItem(
          producto: existingItem.producto,
          cantidad: existingItem.cantidad + cantidad,
        ),
      );
    } else {
      _items.putIfAbsent(
        producto.id,
        () => CartItem(producto: producto, cantidad: cantidad),
      );
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
    } else if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) =>
            CartItem(producto: existingItem.producto, cantidad: newQuantity),
      );
      notifyListeners();
    }
  }

  void decrementItem(int productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.cantidad > 1) {
        _items.update(
          productId,
          (existingItem) => CartItem(
            producto: existingItem.producto,
            cantidad: existingItem.cantidad - 1,
          ),
        );
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
