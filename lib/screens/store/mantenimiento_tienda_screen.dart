import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _fondo = Color(0xFF080808);
const Color _panel = Color(0xFF151515);
const Color _naranja = Color(0xFF006B4F);
const Color _verde = Color(0xFF22C55E);
const Color _azul = Color(0xFF38BDF8);

class MantenimientoTiendaScreen extends StatefulWidget {
  const MantenimientoTiendaScreen({super.key});

  @override
  State<MantenimientoTiendaScreen> createState() =>
      _MantenimientoTiendaScreenState();
}

class _MantenimientoTiendaScreenState
    extends State<MantenimientoTiendaScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _cargando = true;
  bool _archivando = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _pedidosParaArchivar = [];

  int _totalPedidos = 0;
  int _totalArchivados = 0;
  DateTime? _fechaCorte;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  DateTime _obtenerFecha(Map<String, dynamic> data) {
    final firestore = data['fechaFirestore'];

    if (firestore is Timestamp) {
      return firestore.toDate().toLocal();
    }

    final fecha = data['fecha']?.toString();

    if (fecha != null) {
      final parsed = DateTime.tryParse(fecha);

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return DateTime(1970);
  }

  DateTime _fechaLimite() {
    final ahora = DateTime.now();

    return DateTime(
      ahora.year - 1,
      ahora.month,
      ahora.day,
    );
  }

  bool _sePuedeArchivar(
    Map<String, dynamic> data,
    DateTime limite,
  ) {
    if (data['archivado'] == true) {
      return false;
    }

    final estado =
        data['estado']?.toString().toLowerCase() ?? '';

    final esFinalizado =
        estado == 'entregado' ||
        estado == 'cancelado';

    if (!esFinalizado) {
      return false;
    }

    return _obtenerFecha(data).isBefore(limite);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
    });

    try {
      final snapshot = await _firestore
          .collectionGroup('pedidos')
          .get();

      final limite = _fechaLimite();

      final paraArchivar =
          <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      int archivados = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['archivado'] == true) {
          archivados++;
        }

        if (_sePuedeArchivar(data, limite)) {
          paraArchivar.add(doc);
        }
      }

      if (!mounted) return;

      setState(() {
        _totalPedidos = snapshot.docs.length;
        _totalArchivados = archivados;
        _pedidosParaArchivar = paraArchivar;
        _fechaCorte = limite;
        _cargando = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo revisar el historial: '
            '${e.message ?? e.code}',
          ),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    }
  }

  Future<void> _archivarPedidos() async {
    if (_archivando ||
        _pedidosParaArchivar.isEmpty) {
      return;
    }

    final cantidad = _pedidosParaArchivar.length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panel,
          title: const Text(
            'Archivar historial',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Se marcarán $cantidad pedidos como archivados. '
            'No se eliminarán.',
            style: const TextStyle(
              color: Color(0xFFA1A1AA),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Archivar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      _archivando = true;
    });

    try {
      for (
        var inicio = 0;
        inicio < _pedidosParaArchivar.length;
        inicio += 400
      ) {
        final fin = (inicio + 400) >
                _pedidosParaArchivar.length
            ? _pedidosParaArchivar.length
            : inicio + 400;

        final batch = _firestore.batch();

        for (
          var i = inicio;
          i < fin;
          i++
        ) {
          final doc = _pedidosParaArchivar[i];

          batch.update(
            doc.reference,
            {
              'archivado': true,
              'fechaArchivado':
                  FieldValue.serverTimestamp(),
            },
          );
        }

        await batch.commit();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$cantidad pedidos archivados correctamente.',
          ),
          backgroundColor: const Color(0xFF14532D),
        ),
      );

      await _cargarDatos();
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _archivando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo completar el archivado: '
            '${e.message ?? e.code}',
          ),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    }
  }

  String _fechaTexto(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mantenimiento',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: _naranja,
              ),
            )
          : RefreshIndicator(
              color: _naranja,
              backgroundColor: _panel,
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  30,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF24150A),
                          Color(0xFF151515),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF3A2411),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.cleaning_services_rounded,
                          color: _naranja,
                          size: 30,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mantenimiento de datos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Organiza el historial sin eliminar pedidos.',
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _DatoCard(
                          icono:
                              Icons.receipt_long_rounded,
                          titulo: 'Pedidos',
                          valor:
                              '$_totalPedidos',
                          color: _azul,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DatoCard(
                          icono:
                              Icons.archive_outlined,
                          titulo: 'Archivados',
                          valor:
                              '$_totalArchivados',
                          color: _verde,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _DatoCard(
                    icono:
                        Icons.auto_delete_outlined,
                    titulo:
                        'Listos para archivar',
                    valor:
                        '${_pedidosParaArchivar.length}',
                    color:
                        _pedidosParaArchivar.isEmpty
                            ? _verde
                            : _naranja,
                    anchoCompleto: true,
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF292929),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Política de conservación',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fechaCorte == null
                              ? '12 meses'
                              : 'Se revisan pedidos anteriores '
                                  'al ${_fechaTexto(_fechaCorte!)}.',
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Solo se archivan pedidos en estado '
                          'entregado o cancelado. Los pedidos '
                          'activos no se tocan.',
                          style: TextStyle(
                            color: Color(0xFF777780),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed:
                          _archivando ||
                                  _pedidosParaArchivar.isEmpty
                              ? null
                              : _archivarPedidos,
                      icon: _archivando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.archive_rounded,
                            ),
                      label: Text(
                        _archivando
                            ? 'Archivando...'
                            : _pedidosParaArchivar
                                    .isEmpty
                                ? 'No hay pedidos para archivar'
                                : 'Archivar '
                                    '${_pedidosParaArchivar.length} pedidos',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_pedidosParaArchivar.isNotEmpty)
                    ..._pedidosParaArchivar
                        .take(20)
                        .map(
                          (doc) => _PedidoAntiguoCard(
                            data: doc.data(),
                            fecha:
                                _obtenerFecha(
                              doc.data(),
                            ),
                          ),
                        )
                  else
                    Container(
                      padding:
                          const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(
                            0xFF242424,
                          ),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _verde,
                            size: 42,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Historial en orden',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'No hay pedidos antiguos que necesiten archivarse.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF777780),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _DatoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final bool anchoCompleto;

  const _DatoCard({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    this.anchoCompleto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: anchoCompleto ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF292929),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icono,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF777780),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoAntiguoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime fecha;

  const _PedidoAntiguoCard({
    required this.data,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final id = data['id']?.toString() ?? 'Sin ID';
    final estado =
        data['estado']?.toString() ?? 'Sin estado';
    final total =
        (data['total'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF292929),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            color: _naranja,
            size: 24,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #$id',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Fecha: '
                  '${fecha.day.toString().padLeft(2, '0')}/'
                  '${fecha.month.toString().padLeft(2, '0')}/'
                  '${fecha.year} · $estado',
                  style: const TextStyle(
                    color: Color(0xFF777780),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${total.round()}',
            style: const TextStyle(
              color: _naranja,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}





