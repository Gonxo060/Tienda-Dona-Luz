import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/carrito_data.dart';
import '../../models/producto.dart';
import 'confirmar_pedido_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final ValueNotifier<int> _carritoVersion = ValueNotifier<int>(0);

  String _precio(double precio) {
    return '\$${precio.toStringAsFixed(0)}';
  }

  void _actualizarCarrito() {
    _carritoVersion.value++;
  }

  void _agregar(Producto producto) {
    if (!producto.disponible) return;

    CarritoData.agregar(producto);
    _actualizarCarrito();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF242424),
        content: Text(
          '${producto.nombre} agregado al carrito',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: const Duration(milliseconds: 900),
        action: SnackBarAction(
          label: 'VER',
          textColor: const Color(0xFF006B4F),
          onPressed: _mostrarCarrito,
        ),
      ),
    );
  }

  Widget _imagenDesdeBase64({
    required String imagen,
    double size = 52,
    double radius = 10,
  }) {
    Widget contenido;

    if (imagen.isEmpty) {
      contenido = const Icon(
        Icons.shopping_basket_outlined,
        color: Color(0xFF006B4F),
      );
    } else {
      try {
        contenido = Image.memory(
          base64Decode(imagen),
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) =>
              const Icon(
            Icons.shopping_basket_outlined,
            color: Color(0xFF006B4F),
          ),
        );
      } catch (_) {
        contenido = const Icon(
          Icons.shopping_basket_outlined,
          color: Color(0xFF006B4F),
        );
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1508),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF006B4F).withValues(alpha: 0.18),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: contenido,
      ),
    );
  }

  void _mostrarCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (
            modalContext,
            modalSetState,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mi carrito',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${CarritoData.cantidadTotal} productos',
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (CarritoData.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 50,
                              color: Color(0xFF71717A),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tu carrito está vacío',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: CarritoData.items.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 16,
                            color: Color(0xFF292929),
                          ),
                          itemBuilder: (_, index) {
                            final item = CarritoData.items[index];

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                _imagenDesdeBase64(
                                  imagen: item.producto.imagen,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.producto.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.cantidad} ${item.producto.unidadVenta}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFA1A1AA),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _precio(item.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF006B4F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        modalSetState(() {
                                          CarritoData.disminuir(
                                            item.producto,
                                          );
                                        });
                                        _actualizarCarrito();
                                      },
                                      color: const Color(0xFFA1A1AA),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      '${item.cantidad}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          item.producto.disponible
                                              ? () {
                                                  modalSetState(() {
                                                    CarritoData.agregar(
                                                      item.producto,
                                                    );
                                                  });
                                                  _actualizarCarrito();
                                                }
                                              : null,
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color:
                                            item.producto.disponible
                                                ? const Color(0xFF008F68)
                                                : const Color(0xFF52525B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (CarritoData.items.isNotEmpty) ...[
                      const Divider(
                        height: 24,
                        color: Color(0xFF292929),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _precio(CarritoData.total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006B4F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(modalContext);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ConfirmarPedidoScreen(),
                              ),
                            ).then((_) {
                              _actualizarCarrito();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008F68),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continuar pedido',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _carritoVersion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        title: const Text(
          'Comprar productos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _carritoVersion,
            builder: (context, _, child) {
              return IconButton(
                onPressed: _mostrarCarrito,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                    ),
                    if (CarritoData.cantidadTotal > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${CarritoData.cantidadTotal}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _CatalogoBody(
        onAgregar: _agregar,
      ),
    );
  }
}

class _CatalogoBody extends StatefulWidget {
  final ValueChanged<Producto> onAgregar;

  const _CatalogoBody({
    required this.onAgregar,
  });

  @override
  State<_CatalogoBody> createState() => _CatalogoBodyState();
}

class _CatalogoBodyState extends State<_CatalogoBody> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String categoriaSeleccionada = 'Todos';

  String _precio(double precio) {
    return '\$${precio.toStringAsFixed(0)}';
  }

  List<Producto> _productosDesdeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Producto(
        id: doc.id,
        nombre: data['nombre']?.toString() ?? '',
        categoria: data['categoria']?.toString() ?? '',
        precio: (data['precio'] as num?)?.toDouble() ?? 0,
        stock: (data['stock'] as num?)?.toInt() ?? 0,
        imagen: data['imagen']?.toString() ?? '',
        disponible: data['disponible'] as bool? ?? true,
        unidadVenta:
            data['unidadVenta']?.toString() ?? 'unidad',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('productos')
          .orderBy('nombre')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar el catálogo:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF008F68),
            ),
          );
        }

        final productos =
            _productosDesdeSnapshot(snapshot.data!);

        final categorias = <String>[
          'Todos',
          ...{
            for (final producto in productos)
              if (producto.categoria.trim().isNotEmpty)
                producto.categoria.trim(),
          },
        ];

        if (!categorias.contains(categoriaSeleccionada)) {
          categoriaSeleccionada = 'Todos';
        }

        final filtrados =
            categoriaSeleccionada == 'Todos'
                ? productos
                : productos
                    .where(
                      (producto) =>
                          producto.categoria ==
                          categoriaSeleccionada,
                    )
                    .toList();

        final visibles = filtrados
            .where(
              (producto) => producto.disponible,
            )
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final int columnas =
                constraints.maxWidth >= 1000
                    ? 5
                    : constraints.maxWidth >= 700
                        ? 4
                        : constraints.maxWidth >= 480
                            ? 3
                            : 2;

            return Column(
              children: [
                Container(
                  color: const Color(0xFF101010),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12,
                  ),
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categorias.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final categoria =
                            categorias[index];

                        final activa =
                            categoria ==
                                categoriaSeleccionada;

                        return ChoiceChip(
                          label: Text(categoria),
                          selected: activa,
                          onSelected: (_) {
                            setState(() {
                              categoriaSeleccionada =
                                  categoria;
                            });
                          },
                          selectedColor:
                              const Color(0xFF008F68),
                          backgroundColor:
                              const Color(0xFF1C1C1C),
                          labelStyle: TextStyle(
                            color: activa
                                ? Colors.white
                                : const Color(0xFFA1A1AA),
                            fontWeight:
                                FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: activa
                                ? const Color(0xFF008F68)
                                : const Color(0xFF303030),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(22),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: visibles.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay productos disponibles.',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final desplazamiento = Tween<Offset>(
                              begin: const Offset(0, 0.025),
                              end: Offset.zero,
                            ).animate(animation);

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: desplazamiento,
                                child: child,
                              ),
                            );
                          },
                          child: GridView.builder(
                            key: ValueKey(categoriaSeleccionada),
                            padding: const EdgeInsets.all(14),
                            itemCount: visibles.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columnas,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 205,
                            ),
                            itemBuilder: (_, index) {
                              final producto = visibles[index];

                              return _ProductoCard(
                                key: ValueKey(producto.id),
                                producto: producto,
                                precio: _precio(producto.precio),
                                onAgregar: () => widget.onAgregar(producto),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final String precio;
  final VoidCallback onAgregar;

  const _ProductoCard({
    super.key,
    required this.producto,
    required this.precio,
    required this.onAgregar,
  });

  Widget _imagen() {
    if (producto.imagen.isEmpty) {
      return const Icon(
        Icons.shopping_basket_outlined,
        size: 30,
        color: Color(0xFF006B4F),
      );
    }

    try {
      return Image.memory(
        base64Decode(producto.imagen),
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) =>
            const Icon(
          Icons.shopping_basket_outlined,
          size: 30,
          color: Color(0xFF006B4F),
        ),
      );
    } catch (_) {
      return const Icon(
        Icons.shopping_basket_outlined,
        size: 30,
        color: Color(0xFF006B4F),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF292929),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1508),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF006B4F)
                      .withValues(alpha: 0.14),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imagen(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              producto.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$precio / ${producto.unidadVenta}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006B4F),
                    ),
                  ),
                ),
                Material(
                  color: const Color(0xFF008F68),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onAgregar,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    overlayColor:
                        WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




