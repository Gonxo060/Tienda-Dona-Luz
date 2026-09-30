import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/productos_data.dart';
import '../../models/producto.dart';

class ProductosInventarioScreen extends StatefulWidget {
  final bool soloStockBajo;

  const ProductosInventarioScreen({
    super.key,
    this.soloStockBajo = false,
  });

  @override
  State<ProductosInventarioScreen> createState() =>
      _ProductosInventarioScreenState();
}

class _ProductosInventarioScreenState
    extends State<ProductosInventarioScreen> {
  static const int _maxImagenBytes = 500 * 1024;

  static const List<String> unidadesVenta = [
    'unidad',
    'libra',
    'kilogramo',
    'gramo',
    'litro',
    'mililitro',
    'docena',
    'paquete',
    'caja',
  ];

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ImagePicker _picker = ImagePicker();

  CollectionReference<Map<String, dynamic>> get _productosRef =>
      _firestore.collection('productos');

  bool _preparando = true;

  @override
  void initState() {
    super.initState();
    _prepararCatalogo();
  }

  Future<void> _prepararCatalogo() async {
    try {
      final existente = await _productosRef.limit(1).get();

      if (existente.docs.isEmpty) {
        final batch = _firestore.batch();

        for (final producto in ProductosData.productos) {
          batch.set(
            _productosRef.doc(producto.id),
            {
              'id': producto.id,
              'nombre': producto.nombre,
              'categoria': producto.categoria,
              'precio': producto.precio,
              'stock': producto.stock,
              'imagen': producto.imagen,
              'disponible': producto.disponible,
              'unidadVenta': producto.unidadVenta,
              'creadoEn': FieldValue.serverTimestamp(),
              'actualizadoEn': FieldValue.serverTimestamp(),
            },
          );
        }

        await batch.commit();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo preparar el catálogo: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _preparando = false;
        });
      }
    }
  }

  Producto _productoDesdeDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
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
  }

  Future<XFile?> _elegirFoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 800,
        maxHeight: 800,
      );
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo seleccionar la foto: $e',
          ),
        ),
      );

      return null;
    }
  }

  Future<String?> _fotoBase64(XFile foto) async {
    final bytes = await foto.readAsBytes();

    if (bytes.length > _maxImagenBytes) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La foto es demasiado grande. '
            'Selecciona una imagen más pequeña.',
          ),
        ),
      );

      return null;
    }

    return base64Encode(bytes);
  }

  Future<String?> _guardarProducto({
    required Producto? producto,
    required String nombre,
    required String categoria,
    required double precio,
    required int stock,
    required String unidadVenta,
    required bool disponible,
    required XFile? foto,
    required bool quitarFoto,
  }) async {
    try {
      final id = producto?.id ?? _productosRef.doc().id;

      String imagen = producto?.imagen ?? '';

      if (quitarFoto) {
        imagen = '';
      }

      if (foto != null) {
        final nuevaImagen = await _fotoBase64(foto);

        if (nuevaImagen == null) {
          return 'La foto no pudo guardarse.';
        }

        imagen = nuevaImagen;
      }

      await _productosRef.doc(id).set(
        {
          'id': id,
          'nombre': nombre.trim(),
          'categoria': categoria.trim(),
          'precio': precio,
          'stock': stock,
          'imagen': imagen,
          'disponible': disponible,
          'unidadVenta': unidadVenta,
          if (producto == null)
            'creadoEn': FieldValue.serverTimestamp(),
          'actualizadoEn':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (e) {
      return 'No se pudo guardar el producto: $e';
    }
  }

  Future<void> _mostrarProducto({
    Producto? producto,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _ProductoDialog(
          producto: producto,
          unidadesVenta: unidadesVenta,
          elegirFoto: _elegirFoto,
          guardarProducto: ({
            required String nombre,
            required String categoria,
            required double precio,
            required int stock,
            required String unidadVenta,
            required bool disponible,
            required XFile? foto,
            required bool quitarFoto,
          }) {
            return _guardarProducto(
              producto: producto,
              nombre: nombre,
              categoria: categoria,
              precio: precio,
              stock: stock,
              unidadVenta: unidadVenta,
              disponible: disponible,
              foto: foto,
              quitarFoto: quitarFoto,
            );
          },
        );
      },
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            producto == null
                ? 'Producto creado correctamente.'
                : 'Producto actualizado correctamente.',
          ),
        ),
      );
    }
  }

  Future<void> _eliminarProducto(
    Producto producto,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Eliminar producto',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Quieres eliminar "${producto.nombre}"?',
            style: const TextStyle(
              color: Color(0xFFD4D4D8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _productosRef.doc(producto.id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar: $e',
          ),
        ),
      );
    }
  }

  Widget _fotoLista(Producto producto) {
    if (producto.imagen.isEmpty) {
      return const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF006B4F),
        size: 30,
      );
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          base64Decode(producto.imagen),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF006B4F),
            size: 30,
          ),
        ),
      );
    } catch (_) {
      return const Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF006B4F),
        size: 30,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        title: const Text(
          'Productos e inventario',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nuevo producto',
            onPressed: _preparando
                ? null
                : () => _mostrarProducto(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: _preparando
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarProducto(),
              backgroundColor: const Color(0xFF008F68),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            ),
      body: _preparando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF008F68),
              ),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream: _productosRef
                  .orderBy('nombre')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudo cargar el inventario:\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF008F68),
                    ),
                  );
                }

                final todosLosProductos = snapshot.data!.docs
                    .map(_productoDesdeDoc)
                    .toList();

                final productos = widget.soloStockBajo
                    ? todosLosProductos
                        .where((producto) => producto.stock < 20)
                        .toList()
                    : todosLosProductos;

                if (productos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay productos registrados.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    100,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final stockBajo =
                        producto.stock < 20;

                    return Card(
                      color: const Color(0xFF151515),
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Color(0xFF292929),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1C1508),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child:
                                  _fotoLista(producto),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto.nombre,
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style:
                                        const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    producto.categoria,
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFFA1A1AA),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${producto.precio.toStringAsFixed(0)}'
                                    ' / ${producto.unidadVenta}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFF006B4F),
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        stockBajo
                                            ? Icons
                                                .warning_amber_rounded
                                            : Icons
                                                .inventory_2_outlined,
                                        size: 17,
                                        color: stockBajo
                                            ? const Color(0xFF008F68)
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Stock: ${producto.stock}',
                                        style:
                                            const TextStyle(
                                          color:
                                              Color(0xFFA1A1AA),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        producto.disponible
                                            ? 'Disponible'
                                            : 'No disponible',
                                        style:
                                            TextStyle(
                                          color:
                                              producto
                                                      .disponible
                                                  ? const Color(
                                                      0xFF22C55E,
                                                    )
                                                  : const Color(
                                                      0xFFEF4444,
                                                    ),
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              iconColor: Colors.white,
                              onSelected: (opcion) {
                                if (opcion == 'editar') {
                                  _mostrarProducto(
                                    producto: producto,
                                  );
                                } else {
                                  _eliminarProducto(
                                    producto,
                                  );
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'editar',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'eliminar',
                                  child: Text('Eliminar'),
                                ),
                              ],
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

class _ProductoDialog extends StatefulWidget {
  final Producto? producto;
  final List<String> unidadesVenta;
  final Future<XFile?> Function() elegirFoto;

  final Future<String?> Function({
    required String nombre,
    required String categoria,
    required double precio,
    required int stock,
    required String unidadVenta,
    required bool disponible,
    required XFile? foto,
    required bool quitarFoto,
  }) guardarProducto;

  const _ProductoDialog({
    required this.producto,
    required this.unidadesVenta,
    required this.elegirFoto,
    required this.guardarProducto,
  });

  @override
  State<_ProductoDialog> createState() =>
      _ProductoDialogState();
}

class _ProductoDialogState
    extends State<_ProductoDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _precioController;
  late final TextEditingController _stockController;

  late String _unidadVenta;
  late bool _disponible;

  XFile? _fotoNueva;
  bool _quitarFoto = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.producto?.nombre ?? '',
    );

    _categoriaController = TextEditingController(
      text: widget.producto?.categoria ?? '',
    );

    _precioController = TextEditingController(
      text: widget.producto == null
          ? ''
          : widget.producto!.precio
              .toStringAsFixed(0),
    );

    _stockController = TextEditingController(
      text: widget.producto == null
          ? ''
          : widget.producto!.stock.toString(),
    );

    _unidadVenta =
        widget.producto?.unidadVenta ?? 'unidad';

    _disponible =
        widget.producto?.disponible ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Widget _preview() {
    if (_fotoNueva != null) {
      return Image.file(
        File(_fotoNueva!.path),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                const Icon(
          Icons.broken_image_outlined,
          size: 42,
          color: Color(0xFF71717A),
        ),
      );
    }

    if (_quitarFoto) {
      return const Icon(
        Icons.image_not_supported_outlined,
        size: 42,
        color: Color(0xFF71717A),
      );
    }

    final imagen =
        widget.producto?.imagen ?? '';

    if (imagen.isEmpty) {
      return const Icon(
        Icons.add_photo_alternate_outlined,
        size: 42,
        color: Color(0xFF71717A),
      );
    }

    try {
      return Image.memory(
        base64Decode(imagen),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                const Icon(
          Icons.broken_image_outlined,
          size: 42,
          color: Color(0xFF71717A),
        ),
      );
    } catch (_) {
      return const Icon(
        Icons.broken_image_outlined,
        size: 42,
        color: Color(0xFF71717A),
      );
    }
  }

  Future<void> _seleccionarFoto() async {
    final seleccionada =
        await widget.elegirFoto();

    if (!mounted || seleccionada == null) {
      return;
    }

    setState(() {
      _fotoNueva = seleccionada;
      _quitarFoto = false;
    });
  }

  Future<void> _guardar() async {
    final nombre =
        _nombreController.text.trim();

    final categoria =
        _categoriaController.text.trim();

    final precio =
        double.tryParse(
      _precioController.text.trim(),
    );

    final stock =
        int.tryParse(
      _stockController.text.trim(),
    );

    if (nombre.isEmpty ||
        categoria.isEmpty ||
        precio == null ||
        precio < 0 ||
        stock == null ||
        stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa correctamente todos los campos.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    final error =
        await widget.guardarProducto(
      nombre: nombre,
      categoria: categoria,
      precio: precio,
      stock: stock,
      unidadVenta: _unidadVenta,
      disponible: _disponible,
      foto: _fotoNueva,
      quitarFoto: _quitarFoto,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );

      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tieneFoto =
        (widget.producto?.imagen.isNotEmpty ??
                false) ||
            _fotoNueva != null;

    return AlertDialog(
      backgroundColor:
          const Color(0xFF151515),
      title: Text(
        widget.producto == null
            ? 'Nuevo producto'
            : 'Editar producto',
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(14),
              child: Container(
                width: 260,
                height: 160,
                color:
                    const Color(0xFF222222),
                child: _preview(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment:
                  WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _guardando
                      ? null
                      : _seleccionarFoto,
                  icon: const Icon(
                    Icons
                        .photo_library_outlined,
                  ),
                  label: Text(
                    tieneFoto
                        ? 'Cambiar foto'
                        : 'Agregar foto',
                  ),
                ),
                if (tieneFoto)
                  TextButton.icon(
                    onPressed: _guardando
                        ? null
                        : () {
                            setState(() {
                              _fotoNueva = null;
                              _quitarFoto = true;
                            });
                          },
                    icon: const Icon(
                      Icons.delete_outline,
                      color:
                          Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Quitar foto',
                      style: TextStyle(
                        color:
                            Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  _nombreController,
              enabled: !_guardando,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration:
                  const InputDecoration(
                labelText:
                    'Nombre del producto',
                labelStyle: TextStyle(
                  color:
                      Color(0xFFA1A1AA),
                ),
                prefixIcon: Icon(
                  Icons
                      .shopping_bag_outlined,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller:
                  _categoriaController,
              enabled: !_guardando,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'Categoría',
                labelStyle: TextStyle(
                  color:
                      Color(0xFFA1A1AA),
                ),
                prefixIcon: Icon(
                  Icons.category_outlined,
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _unidadVenta,
              dropdownColor:
                  const Color(0xFF202020),
              decoration:
                  const InputDecoration(
                labelText:
                    'Unidad de venta',
                labelStyle: TextStyle(
                  color:
                      Color(0xFFA1A1AA),
                ),
                prefixIcon: Icon(
                  Icons.straighten_outlined,
                ),
              ),
              items: widget.unidadesVenta
                  .map<
                      DropdownMenuItem<
                          String>>(
                    (unidad) =>
                        DropdownMenuItem<
                            String>(
                      value: unidad,
                      child: Text(
                        unidad,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _guardando
                  ? null
                  : (valor) {
                      if (valor == null) {
                        return;
                      }

                      setState(() {
                        _unidadVenta =
                            valor;
                      });
                    },
            ),
            const SizedBox(height: 10),
            TextField(
              controller:
                  _precioController,
              enabled: !_guardando,
              style: const TextStyle(
                color: Colors.white,
              ),
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'Precio',
                labelStyle: TextStyle(
                  color:
                      Color(0xFFA1A1AA),
                ),
                prefixIcon: Icon(
                  Icons.attach_money,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller:
                  _stockController,
              enabled: !_guardando,
              style: const TextStyle(
                color: Colors.white,
              ),
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Stock',
                labelStyle: TextStyle(
                  color:
                      Color(0xFFA1A1AA),
                ),
                prefixIcon: Icon(
                  Icons.inventory_2_outlined,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Producto disponible',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              value: _disponible,
              activeThumbColor:
                  const Color(0xFF008F68),
              onChanged: _guardando
                  ? null
                  : (valor) {
                      setState(() {
                        _disponible =
                            valor;
                      });
                    },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () => Navigator.pop(
                    context,
                    false,
                  ),
          child: const Text(
            'Cancelar',
          ),
        ),
        FilledButton.icon(
          onPressed:
              _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.save_outlined,
                ),
          label:
              const Text('Guardar'),
        ),
      ],
    );
  }
}





