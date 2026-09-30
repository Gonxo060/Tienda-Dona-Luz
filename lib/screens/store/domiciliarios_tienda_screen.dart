import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const String _uidTienda = 'rIaFe7m83VOllbxzMJNftWE93aj2';

class DomiciliariosTiendaScreen extends StatelessWidget {
  const DomiciliariosTiendaScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uidTienda)
          .collection('domiciliarios');

  Future<void> _formulario(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? documento,
  }) async {
    final nombreController = TextEditingController(
      text: documento?.data()?['nombre']?.toString() ?? '',
    );

    final telefonoController = TextEditingController(
      text: documento?.data()?['telefono']?.toString() ?? '',
    );

    bool disponible =
        documento?.data()?['activo'] as bool? ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151515),
              title: Text(
                documento == null
                    ? 'Agregar domiciliario'
                    : 'Editar domiciliario',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: telefonoController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: disponible,
                    onChanged: (value) {
                      setState(() => disponible = value);
                    },
                    title: const Text(
                      'Disponible',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final nombre =
                        nombreController.text.trim();
                    final telefono =
                        telefonoController.text.trim();

                    if (nombre.isEmpty) return;

                    final datos = <String, dynamic>{
                      'nombre': nombre,
                      'telefono': telefono,
                      'activo': disponible,
                      'disponible': disponible,
                      'actualizadoEn':
                          FieldValue.serverTimestamp(),
                    };

                    if (documento == null) {
                      datos['creadoEn'] =
                          FieldValue.serverTimestamp();

                      await _ref.add(datos);
                    } else {
                      await _ref
                          .doc(documento.id)
                          .update(datos);
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    telefonoController.dispose();
  }

  Future<void> _eliminar(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final nombre =
        documento.data()?['nombre']?.toString() ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Eliminar domiciliario',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Deseas eliminar a $nombre?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _ref.doc(documento.id).delete();
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _pedidosDeDomiciliario(String domiciliarioId) async {
    final resultado = await FirebaseFirestore.instance
        .collectionGroup('pedidos')
        .where(
          'domiciliarioId',
          isEqualTo: domiciliarioId,
        )
        .get();

    return resultado.docs;
  }

  Future<void> _cambiarEstadoPedido(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> pedidoDoc,
    String estado,
    String domiciliarioId,
  ) async {
    try {
      await pedidoDoc.reference.update({
        'estado': estado,
        'fechaEstadoFirestore':
            FieldValue.serverTimestamp(),
      });

      if (estado == 'entregado') {
        await _ref.doc(domiciliarioId).update({
          'disponible': true,
          'activo': true,
          'actualizadoEn':
              FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estado == 'en_camino'
                ? 'Pedido marcado como En camino.'
                : 'Pedido entregado. Domiciliario disponible.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF222222),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible actualizar el pedido.',
          ),
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
    }
  }

  String _estadoTexto(String estado) {
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

  Color _estadoColor(String estado) {
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

  void _mostrarPedidos(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> domiciliario,
  ) {
    final data = domiciliario.data() ?? {};
    final nombre =
        data['nombre']?.toString() ?? 'Domiciliario';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF080808),
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return FutureBuilder<
                List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: _pedidosDeDomiciliario(domiciliario.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No fue posible cargar los pedidos.\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                }

                final pedidos = snapshot.data ?? [];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        12,
                        12,
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
                              'Pedidos de $nombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pedidos.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 58,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'No tiene pedidos asignados.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            30,
                          ),
                          itemCount: pedidos.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pedido = pedidos[index];
                            final data = pedido.data();

                            final estado =
                                data['estado']?.toString() ??
                                    'recibido';

                            final direccion =
                                data['direccion']?.toString() ??
                                    '';

                            final total =
                                (data['total'] as num?)
                                        ?.toDouble() ??
                                    0;

                            final items =
                                data['items'] as List<dynamic>? ??
                                    [];

                            return Card(
                              color: const Color(0xFF151515),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Pedido #${pedido.id}',
                                            style:
                                                const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _estadoColor(
                                              estado,
                                            ).withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(20),
                                          ),
                                          child: Text(
                                            _estadoTexto(estado),
                                            style: TextStyle(
                                              color: _estadoColor(
                                                estado,
                                              ),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (direccion.isNotEmpty)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color:
                                                Color(0xFF006B4F),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              direccion,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${items.length} producto(s) • '
                                      '\$${total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    if (estado == 'listo')
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          style:
                                              FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(
                                              0xFF60A5FA,
                                            ),
                                            foregroundColor:
                                                Colors.white,
                                          ),
                                          onPressed: () =>
                                              _cambiarEstadoPedido(
                                            context,
                                            pedido,
                                            'en_camino',
                                            domiciliario.id,
                                          ),
                                          icon: const Icon(
                                            Icons.local_shipping,
                                          ),
                                          label: const Text(
                                            'Iniciar entrega',
                                          ),
                                        ),
                                      )
                                    else if (estado == 'en_camino')
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          style:
                                              FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(
                                              0xFF22C55E,
                                            ),
                                            foregroundColor:
                                                Colors.white,
                                          ),
                                          onPressed: () =>
                                              _cambiarEstadoPedido(
                                            context,
                                            pedido,
                                            'entregado',
                                            domiciliario.id,
                                          ),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: const Text(
                                            'Marcar como entregado',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        title: const Text('Domiciliarios'),
        actions: [
          IconButton(
            onPressed: () => _formulario(context),
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF006B4F),
        foregroundColor: Colors.white,
        onPressed: () => _formulario(context),
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
        ),
        label: const Text('Agregar'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ref.orderBy('nombre').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar domiciliarios:\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delivery_dining_rounded,
                      size: 64,
                      color: Color(0xFF006B4F),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay domiciliarios registrados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pulsa Agregar para registrar el primero.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: docs.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final nombre =
                  data['nombre']?.toString() ?? 'Sin nombre';

              final telefono =
                  data['telefono']?.toString() ?? '';

              final activo =
                  data['activo'] as bool? ?? true;

              final disponible =
                  data['disponible'] as bool? ?? activo;

              return Card(
                color: const Color(0xFF151515),
                child: ListTile(
                  onTap: () => _mostrarPedidos(context, doc),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006B4F)
                          .withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Color(0xFF006B4F),
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    telefono.isEmpty
                        ? (disponible
                            ? 'Disponible'
                            : 'No disponible')
                        : '$telefono • '
                          '${disponible ? 'Disponible' : 'No disponible'}',
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF222222),
                    onSelected: (value) {
                      if (value == 'pedidos') {
                        _mostrarPedidos(context, doc);
                      }

                      if (value == 'editar') {
                        _formulario(
                          context,
                          documento: doc,
                        );
                      }

                      if (value == 'eliminar') {
                        _eliminar(context, doc);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'pedidos',
                        child: Text(
                          'Ver pedidos',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'editar',
                        child: Text(
                          'Editar',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



