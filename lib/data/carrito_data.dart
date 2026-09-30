import '../models/producto.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
  });

  double get subtotal => producto.precio * cantidad;
}

class CarritoData {
  static final List<ItemCarrito> items = [];

  static double get total =>
      items.fold(0, (suma, item) => suma + item.subtotal);

  static int get cantidadTotal =>
      items.fold(0, (suma, item) => suma + item.cantidad);

  static void agregar(Producto producto) {
    final indice = items.indexWhere(
      (item) => item.producto.id == producto.id,
    );

    if (!producto.disponible) return;

    if (indice >= 0) {
      items[indice].cantidad++;
    } else {
      items.add(ItemCarrito(producto: producto));
    }
  }

  static void disminuir(Producto producto) {
    final indice = items.indexWhere(
      (item) => item.producto.id == producto.id,
    );

    if (indice < 0) return;

    if (items[indice].cantidad > 1) {
      items[indice].cantidad--;
    } else {
      items.removeAt(indice);
    }
  }

  static void limpiar() {
    items.clear();
  }
}






