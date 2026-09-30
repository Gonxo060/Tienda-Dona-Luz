import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../services/resumen_ventas_service.dart';

class DomiciliarioScreen extends StatelessWidget {
  final String domiciliarioId;
  final String nombre;
  final String telefono;

  const DomiciliarioScreen({
    super.key,
    required this.domiciliarioId,
    required this.nombre,
    required this.telefono,
  });

  static const naranja = Color(0xFF008F68);
  static const fondo = Color(0xFF080808);
  static const tarjeta = Color(0xFF151515);
  static const texto = Colors.white;

  Stream<QuerySnapshot<Map<String, dynamic>>> _pedidosStream() {
    return FirebaseFirestore.instance
        .collectionGroup('pedidos')
        .snapshots();
  }

  Future<void> _tomarPedido(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final actual = await transaction.get(doc.reference);

        if (!actual.exists) {
          throw Exception('El pedido ya no existe.');
        }

        final data = actual.data() ?? <String, dynamic>{};
        final estadoActual = data['estado']?.toString() ?? '';
        final domiciliarioActual =
            data['domiciliarioId']?.toString() ?? '';

        if (estadoActual != 'preparando') {
          throw Exception('Este pedido ya no está disponible.');
        }

        if (domiciliarioActual.isNotEmpty) {
          throw Exception(
            'Este pedido ya fue tomado por otro domiciliario.',
          );
        }

        transaction.update(doc.reference, {
          'domiciliarioId': domiciliarioId,
          'domiciliarioNombre': nombre,
          'domiciliarioTelefono': telefono,
          'estado': 'listo',
          'fechaEstadoFirestore': FieldValue.serverTimestamp(),
        });
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido tomado correctamente.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
    String estado,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final actual = await transaction.get(doc.reference);
          final data = actual.data();

          if (data == null) {
            throw StateError('El pedido ya no existe.');
          }

          final asignadoA =
              data['domiciliarioId']?.toString() ==
                  domiciliarioId;

          if (!asignadoA) {
            throw StateError(
              'Este pedido no está asignado a este domiciliario.',
            );
          }

          final estadoActual =
              data['estado']?.toString() ?? '';

          final transicionValida =
              (estadoActual == 'listo' &&
                  estado == 'en_camino') ||
              (estadoActual == 'en_camino' &&
                  estado == 'entregado');

          if (!transicionValida) {
            throw StateError(
              'Transición no válida: '
              '$estadoActual → $estado',
            );
          }

          transaction.update(
            doc.reference,
            {
              'estado': estado,
              'fechaEstadoFirestore':
                  FieldValue.serverTimestamp(),
            },
          );

          if (estado == 'entregado') {
            ResumenVentasService.registrarEntrega(
              transaction: transaction,
              data: data,
              fecha: DateTime.now(),
            );
          }
        },
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estado == 'en_camino'
                ? 'Pedido marcado como en camino.'
                : 'Pedido marcado como entregado.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible actualizar el pedido: $e',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: texto,
        elevation: 0,
        title: const Text(
          'Mis entregas',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pedidosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No fue posible cargar los pedidos.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: naranja,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final pedidos = docs
              .where(
                (doc) =>
                    (doc.data()['domiciliarioId']?.toString() == domiciliarioId) || (doc.data()['estado']?.toString() == 'preparando' && (doc.data()['domiciliarioId'] == null || doc.data()['domiciliarioId'].toString().isEmpty)),
              )
              .map(
                (doc) => (
                  doc: doc,
                  pedido: Pedido.fromMap(doc.data()),
                  email: doc.data()['email']?.toString() ?? '',
                ),
              )
              .toList();

          pedidos.sort(
            (a, b) => b.pedido.fecha.compareTo(a.pedido.fecha),
          );

          return Column(
            children: [
              _EncabezadoDomiciliario(
                nombre: nombre,
                telefono: telefono,
              ),
              Expanded(
                child: pedidos.isEmpty
                    ? const _SinPedidos()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          30,
                        ),
                        itemCount: pedidos.length,
                        itemBuilder: (context, index) {
                          final item = pedidos[index];

                          return _PedidoDomiciliarioCard(
                            doc: item.doc,
                            pedido: item.pedido,
                            email: item.email,
                            onTomar:
                                item.doc.data()['domiciliarioId'] == null ||
                                        item.doc.data()['domiciliarioId']
                                            .toString()
                                            .isEmpty
                                    ? () {
                                        _tomarPedido(
                                          context,
                                          item.doc,
                                        );
                                      }
                                    : null,
                            onEstado: (estado) {
                              _cambiarEstado(
                                context,
                                item.doc,
                                estado,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EncabezadoDomiciliario extends StatelessWidget {
  final String nombre;
  final String telefono;

  const _EncabezadoDomiciliario({
    required this.nombre,
    required this.telefono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF303030),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF008F68).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: Color(0xFF008F68),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DOMICILIARIO',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  telefono,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinPedidos extends StatelessWidget {
  const _SinPedidos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.local_shipping_outlined,
            color: Colors.white24,
            size: 70,
          ),
          SizedBox(height: 16),
          Text(
            'No hay pedidos asignados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Los pedidos que la tienda te asigne apareceran aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoDomiciliarioCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final Pedido pedido;
  final String email;
  final ValueChanged<String> onEstado;
    final VoidCallback? onTomar;

  const _PedidoDomiciliarioCard({
    required this.doc,
    required this.pedido,
    required this.email,
    required this.onEstado,
      this.onTomar,
  });

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'listo':
        return const Color(0xFF008F68);
      case 'en_camino':
        return Colors.blueAccent;
      case 'entregado':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  String _estadoTexto(String estado) {
    switch (estado) {
      case 'listo':
        return 'LISTO PARA ENTREGAR';
      case 'en_camino':
        return 'EN CAMINO';
      case 'entregado':
        return 'ENTREGADO';
      default:
        return estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(pedido.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF008F68),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido #${pedido.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _estadoTexto(pedido.estado),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Dato(
            icono: Icons.location_on_outlined,
            titulo: 'Dirección',
            valor: pedido.direccion,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Dato(
              icono: Icons.email_outlined,
              titulo: 'Cliente',
              valor: email,
            ),
          ],
          const SizedBox(height: 10),
          _Dato(
            icono: Icons.payments_outlined,
            titulo: 'Pago',
            valor: pedido.metodoPago,
          ),
          const SizedBox(height: 10),
          _Dato(
            icono: Icons.shopping_bag_outlined,
            titulo: 'Productos',
            valor: '${pedido.items.length} producto(s)',
          ),
          if (pedido.nota.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _Dato(
              icono: Icons.notes_outlined,
              titulo: 'Nota',
              valor: pedido.nota,
            ),
          ],
          const SizedBox(height: 14),
          const Divider(
            color: Color(0xFF292929),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '\$${pedido.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF008F68),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (pedido.estado == 'preparando' && onTomar != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTomar,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('Tomar pedido'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF008F68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (pedido.estado == 'listo')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onEstado('en_camino'),
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Marcar en camino'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF008F68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (pedido.estado == 'en_camino')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onEstado('entregado'),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Marcar como entregado'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF008F68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (pedido.estado == 'entregado')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Entrega completada',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _Dato({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          color: Colors.white38,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor.isEmpty ? 'No registrada' : valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}















