import '../models/producto.dart';

class ProductosData {
  static final List<Producto> productos = [
    Producto(
      id: '1',
      nombre: 'Arroz Diana 1 kg',
      categoria: 'Granos',
      precio: 4500,
      stock: 20,
      unidadVenta: 'kilogramo',
    ),
    Producto(
      id: '2',
      nombre: 'Leche Entera 1 L',
      categoria: 'Lácteos',
      precio: 4200,
      stock: 15,
      unidadVenta: 'litro',
    ),
    Producto(
      id: '3',
      nombre: 'Huevos x12',
      categoria: 'Huevos',
      precio: 8500,
      stock: 10,
      unidadVenta: 'docena',
    ),
    Producto(
      id: '4',
      nombre: 'Pan tajado',
      categoria: 'Panadería',
      precio: 5500,
      stock: 12,
      unidadVenta: 'paquete',
    ),
    Producto(
      id: '5',
      nombre: 'Gaseosa 1.5 L',
      categoria: 'Bebidas',
      precio: 6500,
      stock: 18,
      unidadVenta: 'unidad',
    ),
    Producto(
      id: '6',
      nombre: 'Azúcar 1 kg',
      categoria: 'Granos',
      precio: 3800,
      stock: 20,
      unidadVenta: 'kilogramo',
    ),
  ];
}




