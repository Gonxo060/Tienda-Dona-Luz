import 'package:cloud_firestore/cloud_firestore.dart';

class ResumenVentasService {
  static String fechaClave(DateTime fecha) {
    return '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  static int _cantidadProductos(Map<String, dynamic> data) {
    final items = data['items'];

    if (items is! List) {
      return 0;
    }

    int total = 0;

    for (final item in items) {
      if (item is Map) {
        final cantidad = item['cantidad'];

        if (cantidad is num) {
          total += cantidad.toInt();
        }
      }
    }

    return total;
  }

  static void registrarEntrega({
    required Transaction transaction,
    required Map<String, dynamic> data,
    required DateTime fecha,
  }) {
    final clave = fechaClave(fecha);

    final total =
        (data['total'] as num?)?.toDouble() ?? 0;

    final productosVendidos =
        _cantidadProductos(data);

    final metodoPago =
        data['metodoPago']?.toString().trim().toLowerCase() ?? '';

    final domicilio =
        data['domicilio'] == true;

    final resumenRef = FirebaseFirestore.instance
        .collection('resumenVentas')
        .doc(clave);

    transaction.set(
      resumenRef,
      {
        'fechaClave': clave,
        'totalVentas': FieldValue.increment(total),
        'pedidosEntregados': FieldValue.increment(1),
        'productosVendidos':
            FieldValue.increment(productosVendidos),
        'domicilios': FieldValue.increment(
          domicilio ? 1 : 0,
        ),
        'efectivo': FieldValue.increment(
          metodoPago == 'efectivo' ? total : 0,
        ),
        'transferencia': FieldValue.increment(
          metodoPago == 'transferencia'
              ? total
              : 0,
        ),
        'otrosMedios': FieldValue.increment(
          metodoPago.isEmpty ||
                  (metodoPago != 'efectivo' &&
                      metodoPago != 'transferencia')
              ? total
              : 0,
        ),
        'actualizadaEn':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}



