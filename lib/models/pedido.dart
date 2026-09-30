import 'producto.dart';

class ItemPedido {
  final Producto producto;
  final int cantidad;
  final double precio;

  ItemPedido({
    required this.producto,
    required this.cantidad,
    required this.precio,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toMap() {
    return {
      'producto': {
        'id': producto.id,
        'nombre': producto.nombre,
        'categoria': producto.categoria,
        'precio': producto.precio,
        'stock': producto.stock,
        'imagen': producto.imagen,
        'disponible': producto.disponible,
        'unidadVenta': producto.unidadVenta,
      },
      'cantidad': cantidad,
      'precio': precio,
    };
  }

  factory ItemPedido.fromMap(Map<String, dynamic> map) {
    final productoMap =
        Map<String, dynamic>.from(map['producto'] ?? {});

    return ItemPedido(
      producto: Producto(
        id: productoMap['id']?.toString() ?? '',
        nombre: productoMap['nombre']?.toString() ?? '',
        categoria: productoMap['categoria']?.toString() ?? '',
        precio: (productoMap['precio'] as num?)?.toDouble() ?? 0,
        stock: (productoMap['stock'] as num?)?.toInt() ?? 0,
        imagen: productoMap['imagen']?.toString() ?? '',
        disponible: productoMap['disponible'] as bool? ?? true,
        unidadVenta: productoMap['unidadVenta']?.toString() ?? 'unidad',
      ),
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
      precio: (map['precio'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Pedido {
  final String id;
  final List<ItemPedido> items;
  final double total;
  final String direccion;
  final String metodoPago;
  final String nota;
  final bool domicilio;
  String estado;
  final DateTime fecha;

  Pedido({
    required this.id,
    required this.items,
    required this.total,
    required this.direccion,
    required this.metodoPago,
    required this.nota,
    required this.domicilio,
    this.estado = 'recibido',
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'direccion': direccion,
      'metodoPago': metodoPago,
      'nota': nota,
      'domicilio': domicilio,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    final itemsData = map['items'] as List<dynamic>? ?? [];

    return Pedido(
      id: map['id']?.toString() ?? '',
      items: itemsData
          .map(
            (item) => ItemPedido.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      direccion: map['direccion']?.toString() ?? '',
      metodoPago: map['metodoPago']?.toString() ?? '',
      nota: map['nota']?.toString() ?? '',
      domicilio: map['domicilio'] as bool? ?? false,
      estado: map['estado']?.toString() ?? 'recibido',
      fecha: DateTime.tryParse(
            map['fecha']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}



