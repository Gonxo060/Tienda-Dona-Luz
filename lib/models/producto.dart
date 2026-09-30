class Producto {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String imagen;
  final bool disponible;
  final String unidadVenta;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    this.stock = 0,
    this.imagen = '',
    this.disponible = true,
    this.unidadVenta = 'unidad',
  });

  Producto copyWith({
    String? id,
    String? nombre,
    String? categoria,
    double? precio,
    int? stock,
    String? imagen,
    bool? disponible,
    String? unidadVenta,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      imagen: imagen ?? this.imagen,
      disponible: disponible ?? this.disponible,
      unidadVenta: unidadVenta ?? this.unidadVenta,
    );
  }
}



