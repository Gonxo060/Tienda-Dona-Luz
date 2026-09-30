import 'package:flutter/material.dart';
import '../../models/pedido.dart';

class SeguimientoPedidoScreen extends StatelessWidget {
  final Pedido pedido;

  const SeguimientoPedidoScreen({
    super.key,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento del pedido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido ${pedido.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${pedido.total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _estado('Pedido recibido', pedido.estado == 'recibido'),
            _estado('Preparando', pedido.estado == 'preparando'),
            _estado('Listo para entregar', pedido.estado == 'listo'),
            _estado('En camino', pedido.estado == 'en_camino'),
            _estado('Entregado', pedido.estado == 'entregado'),
          ],
        ),
      ),
    );
  }

  Widget _estado(String texto, bool activo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          Icon(
            activo ? Icons.check_circle : Icons.radio_button_unchecked,
            color: activo ? Colors.green : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 14),
          Text(
            texto,
            style: TextStyle(
              fontSize: 17,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              color: activo ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}




