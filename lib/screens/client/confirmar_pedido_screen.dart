import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/carrito_data.dart';
import '../../data/pedidos_data.dart';
import '../../models/pedido.dart';

class ConfirmarPedidoScreen extends StatefulWidget {
  const ConfirmarPedidoScreen({super.key});

  @override
  State<ConfirmarPedidoScreen> createState() =>
      _ConfirmarPedidoScreenState();
}

class _ConfirmarPedidoScreenState
    extends State<ConfirmarPedidoScreen> {
  final direccionController = TextEditingController();
  final notaController = TextEditingController();

  String metodoPago = 'Efectivo';
  bool domicilio = true;
  bool _guardando = false;
  bool _cargandoDireccion = true;
  String? _direccionPrincipalId;

  @override
  void initState() {
    super.initState();
    _cargarDireccionPrincipal();
  }

  @override
  void dispose() {
    direccionController.dispose();
    notaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDireccionPrincipal() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _cargandoDireccion = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .collection('direcciones')
          .where('principal', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final documento = snapshot.docs.first;
        final datos = documento.data();

        final direccion = (datos['direccion'] ?? '').toString().trim();
        final barrio = (datos['barrio'] ?? '').toString().trim();
        final ciudad = (datos['ciudad'] ?? '').toString().trim();

        final partes = <String>[
          if (direccion.isNotEmpty) direccion,
          if (barrio.isNotEmpty) 'Barrio $barrio',
          if (ciudad.isNotEmpty) ciudad,
        ];

        if (mounted) {
          setState(() {
            _direccionPrincipalId = documento.id;
            direccionController.text = partes.join(', ');
            _cargandoDireccion = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cargandoDireccion = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDireccion = false;
        });
      }
    }
  }

  Widget _imagenDesdeBase64({
    required String imagen,
    double size = 58,
    double radius = 10,
  }) {
    Widget contenido;

    if (imagen.trim().isEmpty) {
      contenido = const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF008F68),
        size: 28,
      );
    } else {
      try {
        contenido = Image.memory(
          base64Decode(imagen.trim()),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _)  {
            return const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF008F68),
              size: 28,
            );
          },
        );
      } catch (_) {
        contenido = const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFF008F68),
          size: 28,
        );
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF006B4F).withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: contenido,
    );
  }

  Future<void> _confirmarPedido() async {
    if (_guardando) return;

    if (direccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registra una dirección principal antes de realizar el pedido.',
          ),
        ),
      );
      return;
    }

    if (CarritoData.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío.'),
        ),
      );
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes iniciar sesión para realizar el pedido.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    final items = CarritoData.items.map((item) {
      return ItemPedido(
        producto: item.producto,
        cantidad: item.cantidad,
        precio: item.producto.precio,
      );
    }).toList();

    final pedido = Pedido(
      id: 'PED-${DateTime.now().millisecondsSinceEpoch}',
      items: items,
      total: CarritoData.total,
      direccion: direccionController.text.trim(),
      metodoPago: metodoPago,
      nota: notaController.text.trim(),
      domicilio: domicilio,
      estado: 'recibido',
      fecha: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .collection('pedidos')
          .doc(pedido.id)
          .set({
        ...pedido.toMap(),
        'uid': usuario.uid,
        'email': usuario.email ?? '',
        'fechaFirestore': FieldValue.serverTimestamp(),
        'archivado': false,
        'fechaArchivado': null,
        'versionDatos': 1,
        if (_direccionPrincipalId != null)
          'direccionId': _direccionPrincipalId,
      });

      PedidosData.agregar(pedido);
      CarritoData.limpiar();

      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151515),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle,
              size: 64,
              color: Color(0xFF006B4F),
            ),
            title: const Text(
              '¡Pedido recibido!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'La Tienda Doña Luz recibió tu pedido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFA1A1AA),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pedido: ${pedido.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: \$${pedido.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF006B4F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Ver mi pedido'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el pedido: $e',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar pedido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del pedido',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            ...CarritoData.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF006B4F),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  children: [
                    _imagenDesdeBase64(
                      imagen: item.producto.imagen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Cantidad: ${item.cantidad} '
                            '${item.producto.unidadVenta}',
                            style: const TextStyle(
                              color: Color(0xFFB8B8B8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF008F68),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Dirección de entrega',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_cargandoDireccion)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Cargando dirección registrada...',
                      style: TextStyle(
                        color: Color(0xFFB8B8B8),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_cargandoDireccion)
              TextField(
                controller: direccionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'Ej. Calle 10 # 20-30, Barrio Centro',
                  border: const OutlineInputBorder(),
                  prefixIcon:
                      const Icon(Icons.location_on_outlined),
                  suffixIcon: _direccionPrincipalId != null
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF008F68),
                        )
                      : null,
                ),
              ),

            if (!_cargandoDireccion &&
                _direccionPrincipalId != null)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF008F68),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Dirección principal registrada',
                      style: TextStyle(
                        color: Color(0xFFB8B8B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            if (!_cargandoDireccion &&
                _direccionPrincipalId == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No tienes una dirección principal registrada. '
                  'Puedes agregarla desde tu perfil.',
                  style: TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            const Text(
              'Método de pago',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            RadioGroup<String>(
              groupValue: metodoPago,
              onChanged: (value) {
                setState(() {
                  metodoPago = value!;
                });
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'Efectivo',
                    title: const Text('Efectivo'),
                  ),
                  RadioListTile<String>(
                    value: 'Transferencia',
                    title: const Text('Transferencia'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Entrega a domicilio'),
              value: domicilio,
              onChanged: (value) {
                setState(() {
                  domicilio = value;
                });
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Nota para la tienda',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: notaController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Ej. Por favor llamar al llegar',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${CarritoData.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _guardando ? null : _confirmarPedido,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _guardando
                        ? 'Guardando pedido...'
                        : 'Confirmar pedido',
                    style:
                        const TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


