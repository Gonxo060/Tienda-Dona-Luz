import 'package:flutter/material.dart';
import '../../data/pedidos_data.dart';
import '../../models/pedido.dart';

class DomiciliarioScreen extends StatefulWidget {
  const DomiciliarioScreen({super.key});

  @override
  State<DomiciliarioScreen> createState() => _DomiciliarioScreenState();
}

class _DomiciliarioScreenState extends State<DomiciliarioScreen> {
  List<Pedido> get pedidos => PedidosData.pedidos
      .where((pedido) => pedido.estado == 'listo' || pedido.estado == 'en_camino')
      .toList();

  void _cambiarEstado(Pedido pedido, String estado) {
    setState(() {
      pedido.estado = estado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domiciliario'),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),
      body: pedidos.isEmpty
          ? const Center(
              child: Text(
                'No hay pedidos para entregar',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${pedido.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Dirección: ${pedido.direccion}'),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${pedido.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (pedido.estado == 'listo')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _cambiarEstado(pedido, 'en_camino'),
                              icon: const Icon(Icons.delivery_dining),
                              label: const Text('Recoger y salir'),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _cambiarEstado(pedido, 'entregado'),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Marcar como entregado'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}




