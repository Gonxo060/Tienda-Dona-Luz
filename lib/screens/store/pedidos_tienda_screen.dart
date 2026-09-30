import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/pedido.dart';

const String _uidTienda = 'rIaFe7m83VOllbxzMJNftWE93aj2';

class PedidosTiendaScreen extends StatefulWidget {
  const PedidosTiendaScreen({super.key});

  @override
  State<PedidosTiendaScreen> createState() => _PedidosTiendaScreenState();
}

class _PedidosTiendaScreenState extends State<PedidosTiendaScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _precio(double valor) {
    return '\$${valor.toStringAsFixed(0)}';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'recibido':
        return const Color(0xFF006B4F);
      case 'preparando':
        return const Color(0xFF008F68);
      case 'listo':
        return const Color(0xFF22C55E);
      case 'en_camino':
        return const Color(0xFF60A5FA);
      case 'entregado':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFA1A1AA);
    }
  }

  String _nombreEstado(String estado) {
    switch (estado) {
      case 'recibido':
        return 'Recibido';
      case 'preparando':
        return 'Preparando';
      case 'listo':
        return 'Listo para entregar';
      case 'en_camino':
        return 'En camino';
      case 'entregado':
        return 'Entregado';
      default:
        return estado;
    }
  }

  Future<void> _cambiarEstado(
    String uidCliente,
    Pedido pedido,
    String estado,
  ) async {
    try {
      if (estado == 'preparando') {
        await _asignarDomiciliarioAutomatico(uidCliente, pedido);
      }

      await _firestore
          .collection('usuarios')
          .doc(uidCliente)
          .collection('pedidos')
          .doc(pedido.id)
          .update({
        'estado': estado,
        'fechaEstadoFirestore':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido actualizado: ${_nombreEstado(estado)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF222222),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible actualizar el pedido.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
    }
  }
  Future<void> _asignarDomiciliarioAutomatico(
    String uidCliente,
    Pedido pedido,
  ) async {
    final resultado = await _firestore
        .collection('usuarios')
        .doc(_uidTienda)
        .collection('domiciliarios')
        .get();

    final disponibles = resultado.docs.where((doc) {
      final data = doc.data();
      return (data['activo'] as bool? ?? true) &&
          (data['disponible'] as bool? ?? true);
    }).toList();

    if (disponibles.isEmpty) return;

    final domiciliario = disponibles.first;
    final data = domiciliario.data();

    await _firestore.runTransaction((transaction) async {
      final actual = await transaction.get(domiciliario.reference);
      final actualData = actual.data() ?? {};

      if (!(actualData['activo'] as bool? ?? true) ||
          !(actualData['disponible'] as bool? ?? true)) {
        return;
      }

      transaction.update(domiciliario.reference, {
        'disponible': false,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      final pedidoRef = _firestore
          .collection('usuarios')
          .doc(uidCliente)
          .collection('pedidos')
          .doc(pedido.id);

      transaction.update(pedidoRef, {
        'domiciliarioId': domiciliario.id,
        'domiciliarioNombre':
            data['nombre']?.toString() ?? '',
        'domiciliarioTelefono':
            data['telefono']?.toString() ?? '',
        'fechaAsignacionDomiciliario':
            FieldValue.serverTimestamp(),
      });
    });
  }
  Future<void> _asignarDomiciliario(
    BuildContext context,
    String uidCliente,
    Pedido pedido,
  ) async {
    try {
      final resultado = await _firestore
          .collection('usuarios')
          .doc(_uidTienda)
          .collection('domiciliarios')
          .get();

      final disponibles = resultado.docs.where((doc) {
        return doc.data()['activo'] as bool? ?? true;
      }).toList();

      if (!context.mounted) return;

      if (disponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay domiciliarios disponibles.',
            ),
            backgroundColor: Color(0xFF7F1D1D),
          ),
        );
        return;
      }

      final seleccionado =
          await showDialog<DocumentSnapshot<Map<String, dynamic>>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151515),
            title: const Text(
              'Asignar domiciliario',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: disponibles.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Colors.white12),
                itemBuilder: (context, index) {
                  final doc = disponibles[index];
                  final data = doc.data();

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF006B4F),
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      data['nombre']?.toString() ?? 'Sin nombre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      data['telefono']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    onTap: () => Navigator.pop(
                      dialogContext,
                      doc,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );

      if (seleccionado == null) return;

      final data = seleccionado.data();

      await _firestore
          .collection('usuarios')
          .doc(uidCliente)
          .collection('pedidos')
          .doc(pedido.id)
          .update({
        'domiciliarioId': seleccionado.id,
        'domiciliarioNombre':
            data?['nombre']?.toString() ?? '',
        'domiciliarioTelefono':
            data?['telefono']?.toString() ?? '',
        'fechaAsignacionDomiciliario':
            FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido asignado a '
            '${data?['nombre']?.toString() ?? 'domiciliario'}.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo asignar: ${e.message ?? e.code}',
          ),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    }
  }


  Stream<QuerySnapshot<Map<String, dynamic>>>
      _pedidosStream() {
    return _firestore
        .collectionGroup('pedidos')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pedidosStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF080808),
            appBar: AppBar(
              backgroundColor: const Color(0xFF080808),
              foregroundColor: Colors.white,
              title: const Text(
                'Pedidos de la tienda',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: _error(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF080808),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF008F68),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        docs.sort((a, b) {
          final fechaA = a.data()['fechaFirestore'];
          final fechaB = b.data()['fechaFirestore'];

          if (fechaA is Timestamp && fechaB is Timestamp) {
            return fechaB.compareTo(fechaA);
          }

          return 0;
        });

        return Scaffold(
          backgroundColor: const Color(0xFF080808),
          appBar: AppBar(
            backgroundColor: const Color(0xFF080808),
            foregroundColor: Colors.white,
            title: const Text(
              'Pedidos de la tienda',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008F68),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${docs.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: docs.isEmpty
              ? _vacio()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    try {
                      final pedido = Pedido.fromMap(data);

                      final partes =
                          doc.reference.path.split('/');

                      final uidCliente =
                          partes.length >= 2
                              ? partes[1]
                              : '';

                      return _PedidoCard(
                        pedido: pedido,
                        precio: _precio,
                        colorEstado: _colorEstado,
                        nombreEstado: _nombreEstado,
                        domiciliarioNombre:
                            data['domiciliarioNombre']?.toString(),
                        onEstado: (pedido, estado) {
                          _cambiarEstado(
                            uidCliente,
                            pedido,
                            estado,
                          );
                        },
                        onAsignar: () {
                          _asignarDomiciliario(
                            context,
                            uidCliente,
                            pedido,
                          );
                        },
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  },
                ),
        );
      },
    );
  }
  Widget _vacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: const Color(0xFF52525B),
            ),
            const SizedBox(height: 18),
            const Text(
              'No hay pedidos todavía',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando un cliente realice un pedido, aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: Color(0xFFEF4444),
            ),
            SizedBox(height: 16),
            Text(
              'No se pudieron cargar los pedidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Verifica la conexión con Firebase.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final String Function(double) precio;
  final Color Function(String) colorEstado;
  final String Function(String) nombreEstado;
  final String? domiciliarioNombre;
  final void Function(Pedido, String) onEstado;
  final VoidCallback onAsignar;

  const _PedidoCard({
    required this.pedido,
    required this.precio,
    required this.colorEstado,
    required this.nombreEstado,
    required this.domiciliarioNombre,
    required this.onEstado,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(pedido.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF151515),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Colors.white10,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pedido #${pedido.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nombreEstado(pedido.estado),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ...pedido.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '  €',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.producto.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      precio(item.subtotal),
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  precio(pedido.total),
                  style: const TextStyle(
                    color: Color(0xFF006B4F),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            if (pedido.domicilio) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      pedido.direccion.isEmpty
                          ? 'Domicilio sin dirección'
                          : pedido.direccion,
                      style: const TextStyle(
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (pedido.metodoPago.isNotEmpty) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 19,
                    color: Color(0xFF006B4F),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    pedido.metodoPago,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ],

            if (pedido.nota.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                'Nota: ${pedido.nota}',
                style: const TextStyle(
                  color: Color(0xFFA1A1AA),
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (domiciliarioNombre != null &&
                domiciliarioNombre!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B4F)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF006B4F)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining_rounded,
                      color: Color(0xFF006B4F),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Domiciliario: $domiciliarioNombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            _AccionesEstado(
              pedido: pedido,
              domiciliarioNombre: domiciliarioNombre,
              onEstado: onEstado,
              onAsignar: onAsignar,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionesEstado extends StatelessWidget {
  final Pedido pedido;
  final String? domiciliarioNombre;
  final void Function(Pedido, String) onEstado;
  final VoidCallback onAsignar;

  const _AccionesEstado({
    required this.pedido,
    required this.domiciliarioNombre,
    required this.onEstado,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    switch (pedido.estado) {
      case 'recibido':
        return _boton(
          icono: Icons.check_rounded,
          texto: 'Aceptar pedido',
          estado: 'preparando',
        );

      case 'preparando':
        return _boton(
          icono: Icons.inventory_2_outlined,
          texto: 'Marcar listo para entregar',
          estado: 'listo',
        );

      case 'listo':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _mensaje(
              Icons.delivery_dining_rounded,
              domiciliarioNombre == null ||
                      domiciliarioNombre!.isEmpty
                  ? 'Esperando domiciliario'
                  : 'Domiciliario asignado',
              const Color(0xFF22C55E),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: onAsignar,
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                ),
                label: Text(
                  domiciliarioNombre == null ||
                          domiciliarioNombre!.isEmpty
                      ? 'Asignar domiciliario'
                      : 'Cambiar domiciliario',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );

      case 'en_camino':
        return _mensaje(
          Icons.delivery_dining,
          'Pedido en camino',
          const Color(0xFF60A5FA),
        );

      case 'entregado':
        return _mensaje(
          Icons.check_circle,
          'Pedido entregado',
          const Color(0xFF22C55E),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _boton({
    required IconData icono,
    required String texto,
    required String estado,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: () => onEstado(pedido, estado),
        icon: Icon(icono),
        label: Text(
          texto,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _mensaje(
    IconData icono,
    String texto,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




