import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import 'seguimiento_pedido_screen.dart';

class MisPedidosScreen extends StatelessWidget {
  const MisPedidosScreen({super.key});

  String _estadoTexto(String estado) {
    switch (estado) {
      case 'recibido':
        return 'Pedido recibido';
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

  IconData _estadoIcono(String estado) {
    switch (estado) {
      case 'recibido':
        return Icons.shopping_bag;
      case 'preparando':
        return Icons.inventory_2;
      case 'listo':
        return Icons.check_circle_outline;
      case 'en_camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} • $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: _EstadoVacio(
          titulo: 'Inicia sesión',
          mensaje: 'Necesitas iniciar sesión para ver tus pedidos.',
        ),
      );
    }

    final pedidosRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('pedidos')
        .orderBy('fechaFirestore', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text(
          'Mis pedidos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pedidosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006B4F),
              ),
            );
          }

          if (snapshot.hasError) {
            return _EstadoVacio(
              titulo: 'No se pudieron cargar los pedidos',
              mensaje: 'Verifica tu conexión e inténtalo nuevamente.',
              icono: Icons.error_outline,
              colorIcono: const Color(0xFFEF4444),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          if (documentos.isEmpty) {
            return const _EstadoVacio(
              titulo: 'No tienes pedidos todavía',
              mensaje:
                  'Cuando realices una compra, tus pedidos aparecerán aquí.',
            );
          }

          final pedidos = documentos.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());

            if (data['id'] == null || data['id'].toString().isEmpty) {
              data['id'] = doc.id;
            }

            return Pedido.fromMap(data);
          }).toList();

          return AnimatedSwitcher(
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];

                return _PedidoCard(
                  pedido: pedido,
                  estadoTexto: _estadoTexto(pedido.estado),
                  estadoColor: _estadoColor(pedido.estado),
                  estadoIcono: _estadoIcono(pedido.estado),
                  fecha: _fecha(pedido.fecha),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final String estadoTexto;
  final Color estadoColor;
  final IconData estadoIcono;
  final String fecha;

  const _PedidoCard({
    required this.pedido,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoIcono,
    required this.fecha,
  });

  void _abrirSeguimiento(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeguimientoPedidoScreen(
          pedido: pedido,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151515),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirSeguimiento(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      estadoIcono,
                      color: estadoColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${pedido.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fecha,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      estadoIcono,
                      color: estadoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        estadoTexto,
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: Color(0xFF006B4F),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pedido.items.length} producto(s)',
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${pedido.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006B4F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.payment_outlined,
                    size: 19,
                    color: Color(0xFFA1A1AA),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pedido.metodoPago,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),

              if (pedido.domicilio) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 19,
                      color: Color(0xFFA1A1AA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pedido.direccion.isEmpty
                            ? 'Sin dirección'
                            : pedido.direccion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _abrirSeguimiento(context),
                  icon: const Icon(
                    Icons.location_searching,
                    color: Color(0xFF006B4F),
                  ),
                  label: const Text(
                    'Ver seguimiento',
                    style: TextStyle(
                      color: Color(0xFF006B4F),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF006B4F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final IconData icono;
  final Color colorIcono;

  const _EstadoVacio({
    this.titulo = 'No tienes pedidos todavía',
    this.mensaje =
        'Cuando realices una compra, tus pedidos aparecerán aquí.',
    this.icono = Icons.shopping_bag,
    this.colorIcono = const Color(0xFF006B4F),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorIcono.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                size: 65,
                color: colorIcono,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}







