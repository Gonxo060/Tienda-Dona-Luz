import '../models/pedido.dart';

class PedidosData {
  static final List<Pedido> pedidos = [];

  static void agregar(Pedido pedido) {
    pedidos.insert(0, pedido);
  }
}



