import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/pedido.dart';

class VentasReportesScreen extends StatefulWidget {
  const VentasReportesScreen({super.key});

  @override
  State<VentasReportesScreen> createState() =>
      _VentasReportesScreenState();
}

class _VentasReportesScreenState
    extends State<VentasReportesScreen> {
  final TextEditingController _busquedaController =
      TextEditingController();

  String _filtro = 'Todo';
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ventasStream() {
    return FirebaseFirestore.instance
        .collectionGroup('pedidos')
        .where('estado', isEqualTo: 'entregado')
        .snapshots();
  }

  String _precio(double valor) {
    return '\$${valor.toStringAsFixed(0)}';
  }

  DateTime? _fechaInicio() {
    final ahora = DateTime.now();

    switch (_filtro) {
      case 'Hoy':
        return DateTime(
          ahora.year,
          ahora.month,
          ahora.day,
        );

      case '7 días':
        return ahora.subtract(
          const Duration(days: 7),
        );

      case '30 días':
        return ahora.subtract(
          const Duration(days: 30),
        );

      default:
        return null;
    }
  }

  bool _cumpleFecha(Pedido pedido) {
    final inicio = _fechaInicio();

    if (inicio == null) {
      return true;
    }

    return pedido.fecha.isAfter(inicio) ||
        pedido.fecha.isAtSameMomentAs(inicio);
  }

  bool _cumpleBusqueda(Pedido pedido) {
    final texto = _busqueda.trim().toLowerCase();

    if (texto.isEmpty) {
      return true;
    }

    return pedido.id.toLowerCase().contains(texto) ||
        pedido.metodoPago.toLowerCase().contains(texto) ||
        pedido.direccion.toLowerCase().contains(texto) ||
        pedido.nota.toLowerCase().contains(texto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ventas y reportes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ventasStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _error(snapshot.error);
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006B4F),
              ),
            );
          }

          final pedidos = <Pedido>[];

          for (final doc in snapshot.data?.docs ?? []) {
            try {
              final pedido = Pedido.fromMap(doc.data());

              if (pedido.estado == 'entregado') {
                pedidos.add(pedido);
              }
            } catch (_) {}
          }

          pedidos.sort(
            (a, b) => b.fecha.compareTo(a.fecha),
          );

          final pedidosFiltrados = pedidos
              .where(_cumpleFecha)
              .where(_cumpleBusqueda)
              .toList();

          return _contenido(
            pedidos,
            pedidosFiltrados,
          );
        },
      ),
    );
  }

  Widget _contenido(
    List<Pedido> todosLosPedidos,
    List<Pedido> pedidos,
  ) {
    final totalVentas = pedidos.fold<double>(
      0,
      (suma, pedido) => suma + pedido.total,
    );

    final productosVendidos = pedidos.fold<int>(
      0,
      (suma, pedido) =>
          suma +
          pedido.items.fold<int>(
            0,
            (total, item) => total + item.cantidad,
          ),
    );

    final efectivo = pedidos
        .where(
          (pedido) =>
              pedido.metodoPago.toLowerCase() ==
              'efectivo',
        )
        .fold<double>(
          0,
          (suma, pedido) => suma + pedido.total,
        );

    final transferencia = pedidos
        .where(
          (pedido) =>
              pedido.metodoPago.toLowerCase() ==
              'transferencia',
        )
        .fold<double>(
          0,
          (suma, pedido) => suma + pedido.total,
        );

    return RefreshIndicator(
      color: const Color(0xFF006B4F),
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          30,
        ),
        children: [
          _encabezado(
            totalVentas,
            pedidos.length,
          ),
          const SizedBox(height: 16),
          _filtros(),
          const SizedBox(height: 14),
          _buscador(),
          const SizedBox(height: 18),
          _resumen(
            totalVentas,
            pedidos.length,
            productosVendidos,
          ),
          const SizedBox(height: 20),
          _tituloSeccion(
            'Métodos de pago',
            Icons.payments_outlined,
          ),
          const SizedBox(height: 10),
          _pagoCard(
            'Efectivo',
            efectivo,
            Icons.money_rounded,
          ),
          const SizedBox(height: 8),
          _pagoCard(
            'Transferencia',
            transferencia,
            Icons.account_balance_rounded,
          ),
          const SizedBox(height: 22),
          _tituloSeccion(
            'Historial de ventas',
            Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 10),
          if (pedidos.isEmpty)
            _sinResultados()
          else
            ...pedidos.map(_ventaCard),
        ],
      ),
    );
  }

  Widget _encabezado(
    double total,
    int cantidad,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF006B4F),
            Color(0xFFE67700),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ventas realizadas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _precio(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$cantidad pedido(s) entregado(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          'Hoy',
          '7 días',
          '30 días',
          'Todo',
        ].map((filtro) {
          final activo = _filtro == filtro;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filtro),
              selected: activo,
              onSelected: (_) {
                setState(() {
                  _filtro = filtro;
                });
              },
              selectedColor:
                  const Color(0xFF006B4F),
              backgroundColor:
                  const Color(0xFF18181B),
              labelStyle: TextStyle(
                color: activo
                    ? Colors.white
                    : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: activo
                    ? const Color(0xFF006B4F)
                    : Colors.white12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buscador() {
    return TextField(
      controller: _busquedaController,
      onChanged: (value) {
        setState(() {
          _busqueda = value;
        });
      },
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar pedido, método o dirección...',
        hintStyle: const TextStyle(
          color: Colors.white38,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF006B4F),
        ),
        suffixIcon: _busqueda.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _busquedaController.clear();
                  setState(() {
                    _busqueda = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                ),
              ),
        filled: true,
        fillColor: const Color(0xFF151515),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _resumen(
    double total,
    int pedidos,
    int productos,
  ) {
    return Row(
      children: [
        Expanded(
          child: _miniCard(
            Icons.attach_money_rounded,
            'Total',
            _precio(total),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniCard(
            Icons.receipt_long_rounded,
            'Pedidos',
            '$pedidos',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniCard(
            Icons.inventory_2_rounded,
            'Unidades',
            '$productos',
          ),
        ),
      ],
    );
  }

  Widget _miniCard(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icono,
            color: const Color(0xFF006B4F),
            size: 25,
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(
    String titulo,
    IconData icono,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          color: const Color(0xFF006B4F),
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _pagoCard(
    String titulo,
    double valor,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF006B4F)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: const Color(0xFF006B4F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _precio(valor),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ventaCard(Pedido pedido) {
    final cantidad = pedido.items.fold<int>(
      0,
      (suma, item) => suma + item.cantidad,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF006B4F),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${pedido.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$cantidad unidad(es) · '
                      '${pedido.metodoPago}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _precio(pedido.total),
                style: const TextStyle(
                  color: Color(0xFF006B4F),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(
            color: Colors.white10,
            height: 1,
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  pedido.direccion.isEmpty
                      ? 'Sin dirección registrada'
                      : pedido.direccion,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (pedido.nota.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Nota: ${pedido.nota}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 17,
              ),
              const SizedBox(width: 6),
              const Text(
                'Entregado',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _fechaTexto(pedido.fecha),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fechaTexto(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Widget _sinResultados() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 55,
            color: Colors.white24,
          ),
          SizedBox(height: 12),
          Text(
            'No hay ventas para este filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No se pudieron cargar las ventas.\n\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}



