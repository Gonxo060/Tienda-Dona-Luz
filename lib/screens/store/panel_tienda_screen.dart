import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pedidos_tienda_screen.dart';
import '../products/productos_inventario_screen.dart';
import 'ventas_reportes_screen.dart';
import 'domiciliarios_tienda_screen.dart';
import 'mantenimiento_tienda_screen.dart';
import '../auth/login_screen.dart';
import '../clientes_screen.dart';

const Color _verde = Color(0xFF10B981);
const Color _verdeClaro = Color(0xFF06281E);
const Color _fondo = Color(0xFF080808);
const Color _naranja = Color(0xFF006B4F);
const Color _azul = Color(0xFF10B981);
const Color _morado = Color(0xFF006B4F);
const Color _carbon = Color(0xFF242424);
const Color _texto = Colors.white;

class PanelTiendaScreen extends StatelessWidget {
  const PanelTiendaScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            _LogoTienda(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
              'Tienda Do\u00F1a Luz',
                    style: TextStyle(
                      color: _texto,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Panel administrativo',
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
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collectionGroup('pedidos')
                .where(
                  'estado',
                  isEqualTo: 'recibido',
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('[NOTIFICACION] ERROR FIRESTORE: ${snapshot.error}');
              } else {
                debugPrint(
                  '[NOTIFICACION] PEDIDOS RECIBIDOS: ${snapshot.data?.docs.length ?? 0}',
                );
              }

              final cantidad = snapshot.data?.docs.length ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Pedidos nuevos',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PedidosTiendaScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    if (cantidad > 0)
                      Positioned(
                        right: -3,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF080808),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            cantidad > 99 ? '99+' : '$cantidad',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                ),
              ),
              child: IconButton(
                    tooltip: 'Cerrar sesi\u00F3n',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                    'Buenos d\u00EDas',
                style: TextStyle(
                  color: _texto,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                    'Aqu\u00ED tienes el resumen de tu tienda.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),

              const SizedBox(height: 16),

              _AvisoPedidoNuevo(
                onTap: () => _abrir(
                  context,
                  const PedidosTiendaScreen(),
                ),
              ),

              const SizedBox(height: 16),
              const _VentasPrincipal(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ResumenCard(
                      icono: Icons.receipt_long_rounded,
                      titulo: 'Pedidos',
                      valor: '0',
                      color: _azul,
                      onTap: () => _abrir(
                        context,
                        const PedidosTiendaScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResumenCard(
                      icono: Icons.inventory_2_rounded,
                      titulo: 'Productos',
                      valor: '6',
                      color: _verde,
                      onTap: () => _abrir(
                        context,
                        const ProductosInventarioScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('productos')
                          .snapshots(),
                      builder: (context, snapshot) {
                        var stockBajo = 0;

                        if (snapshot.hasData) {
                          stockBajo = snapshot.data!.docs.where((doc) {
                            final stock =
                                (doc.data()['stock'] as num?)?.toInt() ?? 0;
                            return stock < 10;
                          }).length;
                        }

                        return _ResumenCard(
                          icono: Icons.warning_amber_rounded,
                          titulo: 'Stock bajo',
                          valor: '$stockBajo',
                          color: _naranja,
                          onTap: () => _abrir(
                            context,
                            const ProductosInventarioScreen(
                              soloStockBajo: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const _TituloSeccion(
                    titulo: 'Acciones r\u00E1pidas',
                    subtitulo: 'Accede r\u00E1pidamente a las funciones principales',
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _AccionCard(
                      icono: Icons.bar_chart_rounded,
                      titulo: 'Ventas',
                      subtitulo: 'Ver movimientos',
                      color: _naranja,
                      onTap: () => _abrir(
                        context,
                        const VentasReportesScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const _TituloSeccion(
                    titulo: 'Gesti\u00F3n',
                    subtitulo: 'Administra las \u00E1reas de tu tienda',
              ),
              const SizedBox(height: 14),

              _MenuCard(
                icono: Icons.receipt_long_rounded,
                titulo: 'Pedidos nuevos',
                subtitulo: 'Revisar y aceptar pedidos de clientes',
                color: _azul,
                 fondo: _carbon,
                onTap: () => _abrir(
                  context,
                  const PedidosTiendaScreen(),
                ),
              ),

              const SizedBox(height: 10),

              _MenuCard(
                icono: Icons.inventory_2_rounded,
                titulo: 'Productos e inventario',
                subtitulo: 'Precios, existencias y disponibilidad',
                color: _verde,
                 fondo: _carbon,
                onTap: () => _abrir(
                  context,
                  const ProductosInventarioScreen(),
                ),
              ),

              const SizedBox(height: 10),

              _MenuCard(
                icono: Icons.delivery_dining_rounded,
                titulo: 'Domiciliarios',
                    subtitulo: 'Administra las \u00E1reas de tu tienda',
                color: _naranja,
                 fondo: _carbon,
                onTap: () => _abrir(
                  context,
                  const DomiciliariosTiendaScreen(),
                ),
              ),

              const SizedBox(height: 10),

              _MenuCard(
                icono: Icons.people_alt_rounded,
                titulo: 'Clientes',
                subtitulo: 'Clientes y direcciones',
                color: _morado,
                 fondo: _carbon,
                onTap: () => _abrir(
                  context,
                  const ClientesScreen(),
                ),
              ),

              const SizedBox(height: 10),

              _MenuCard(

                icono: Icons.cleaning_services_rounded,

                titulo: 'Mantenimiento',

                subtitulo: 'Revisar y organizar el historial',

                color: _naranja,
                 fondo: _carbon,

                onTap: () => _abrir(

                  context,

                  const MantenimientoTiendaScreen(),

                ),

              ),

              const SizedBox(height: 18),

              _MenuCard(

                icono: Icons.bar_chart_rounded,

                titulo: 'Ventas y reportes',
                subtitulo: 'Consultar ventas y movimientos',
                color: _naranja,
                 fondo: _carbon,
                onTap: () => _abrir(
                  context,
                  const VentasReportesScreen(),
                ),
              ),

              const SizedBox(height: 28),

              const _TituloSeccion(
                titulo: 'Actividad reciente',
                      subtitulo: 'Estado actual',
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Color(0xFF151515),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFF242424),
                  ),
                ),
                child: const Column(
                  children: [
                    _ActividadRow(
                      icono: Icons.inventory_2_rounded,
                      titulo: 'Inventario',
                      subtitulo: '6 productos registrados',
                      estado: 'Actualizado',
                      color: _verde,
                    ),
                    Divider(height: 24),
                    _ActividadRow(
                      icono: Icons.receipt_long_rounded,
                      titulo: 'Pedidos',
                      subtitulo: 'No hay pedidos pendientes',
                          estado: 'Al d\u00EDa',
                      color: _azul,
                    ),
                    Divider(height: 24),
                    _ActividadRow(
                      icono: Icons.bar_chart_rounded,
                      titulo: 'Ventas',
                          subtitulo: 'A\u00FAn no hay movimientos registrados',
                      estado: 'Sin ventas',
                      color: _naranja,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoTienda extends StatelessWidget {
  const _LogoTienda();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _verdeClaro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: _verde,
            size: 27,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: _naranja,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VentasPrincipal extends StatelessWidget {
  const _VentasPrincipal();

  DateTime? _fechaEntrega(Map<String, dynamic> data) {
    final valor = data['fechaEstadoFirestore'];

    if (valor is Timestamp) {
      return valor.toDate().toLocal();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();

    final inicioHoy = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    final finHoy = inicioHoy.add(
      const Duration(days: 1),
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('pedidos')
          .where(
            'estado',
            isEqualTo: 'entregado',
          )
          .snapshots(),
      builder: (context, snapshot) {
        double ventasHoy = 0;
        int cantidadVentasHoy = 0;

        if (!snapshot.hasError) {
          for (final doc in snapshot.data?.docs ?? []) {
            final data = doc.data();
            final fechaEntrega = _fechaEntrega(data);

            if (fechaEntrega == null) {
              continue;
            }

            if (!fechaEntrega.isBefore(inicioHoy) &&
                fechaEntrega.isBefore(finHoy)) {
              ventasHoy +=
                  (data['total'] as num?)?.toDouble() ?? 0;
              cantidadVentasHoy++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _verde,
                Color(0xFFC2410C),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ventas de hoy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${ventasHoy.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$cantidadVentasHoy '
                      '${cantidadVentasHoy == 1 ? 'venta' : 'ventas'} '
                      'registradas',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _TituloSeccion extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _TituloSeccion({
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: _texto,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitulo,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final VoidCallback onTap;

  const _ResumenCard({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titulo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  color: color,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color fondo;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    this.fondo = const Color(0xFF111111),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActividadRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String estado;
  final Color color;

  const _ActividadRow({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.estado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icono,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: _texto,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          estado,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}









class _AvisoPedidoNuevo extends StatelessWidget {
  final VoidCallback onTap;

  const _AvisoPedidoNuevo({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('pedidos')
          .where(
            'estado',
            isEqualTo: 'recibido',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final cantidad = snapshot.data?.docs.length ?? 0;

        if (cantidad == 0) {
          return const SizedBox.shrink();
        }

        final textoCantidad = cantidad == 1
            ? 'Hay 1 pedido esperando atención.'
            : 'Hay $cantidad pedidos esperando atención.';

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7F1D1D),
                  Color(0xFF3F1111),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.60),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.10),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NUEVO PEDIDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textoCantidad,
                        style: const TextStyle(
                          color: Color(0xFFFECACA),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}









