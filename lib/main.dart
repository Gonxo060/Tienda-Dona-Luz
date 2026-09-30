import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/client/catalogo_screen.dart';
import 'screens/client/mis_pedidos_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/perfil_screen.dart';
import 'screens/client/direcciones_screen.dart';
import 'models/producto.dart';

const Color verde = Color(0xFF087F5B);
const Color verdeSuave = Color(0xFFE8F5EF);
const Color crema = Color(0xFFF7F5EE);
const Color naranja = Color(0xFFF59F00);
const Color texto = Color(0xFF17211D);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TiendaDonaLuzApp());
}

class TiendaDonaLuzApp extends StatelessWidget {
  const TiendaDonaLuzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tienda Doña Luz',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF008F68),
          onPrimary: Colors.white,
          secondary: Color(0xFF006B4F),
          onSecondary: Colors.black,
          surface: Color(0xFF151515),
          onSurface: Colors.white,
          error: Color(0xFFEF4444),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF080808),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF151515),
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF101010),
          indicatorColor: Color(0xFF008F68),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF151515),
          labelStyle: TextStyle(
            color: Color(0xFFA1A1AA),
          ),
          prefixIconColor: Color(0xFF006B4F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(
              color: Color(0xFF008F68),
              width: 1.5,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Color(0xFF008F68),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF006B4F),
          foregroundColor: Colors.black,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF222222),
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: Color(0xFF006B4F),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    Timer(const Duration(seconds: 7), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 850),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, _) => const LoginScreen(),
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.96,
                  end: 1.0,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050505),
              Color(0xFF12100B),
              Color(0xFF1A1307),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _LogoGrande(),
                  const SizedBox(height: 24),
                  const Text(
                    'Tienda Doña Luz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todo lo que necesitas, cerca de ti',
                    style: TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 38),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        Color(0xFF006B4F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoGrande extends StatelessWidget {
  const _LogoGrande();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: verde,
            size: 62,
          ),
          Positioned(
            top: 17,
            right: 16,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: naranja,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int _indice = 0;

  final TextEditingController _busquedaController =
      TextEditingController();

  String _categoriaSeleccionada = 'Todos';

  List<String> _categorias = ['Todos'];

  final List<Producto> _productosFirestore = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _productosSubscription;

  @override
  void initState() {
    super.initState();

    _productosSubscription = FirebaseFirestore.instance
        .collection('productos')
        .orderBy('nombre')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        final productos = snapshot.docs.map((doc) {
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

        final categorias = <String>{};

        for (final producto in productos) {
          final categoria = producto.categoria.trim();

          if (categoria.isNotEmpty) {
            categorias.add(categoria);
          }
        }

        final categoriasOrdenadas = categorias.toList()..sort();

        setState(() {
          _productosFirestore
            ..clear()
            ..addAll(productos);

          _categorias = [
            'Todos',
            ...categoriasOrdenadas,
          ];

          if (!_categorias.contains(_categoriaSeleccionada)) {
            _categoriaSeleccionada = 'Todos';
          }
        });
      },
      onError: (error) {
        debugPrint('[INICIO] Error Firestore: $error');
      },
    );
  }

  @override
  void dispose() {
    _productosSubscription?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  void _abrir(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => pantalla,
      ),
    );
  }

  void _navegar(int indice) {
    if (indice == 0) {
      setState(() {
        _indice = 0;
      });
      return;
    }

    if (indice == 1) {
      _abrir(const CatalogoScreen());
      return;
    }

    if (indice == 2) {
      _abrir(const MisPedidosScreen());
      return;
    }

    if (indice == 3) {
      _mostrarPerfil();
    }
  }

  void _mostrarPerfil() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFF2A1A08),
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF006B4F),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mi perfil',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Administra tus datos y direcciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFA1A1AA),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF006B4F),
                  ),
                  title: const Text(
                    'Datos personales',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA1A1AA),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _abrir(const PerfilScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF006B4F),
                  ),
                  title: const Text(
                    'Mis direcciones',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA1A1AA),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _abrir(const DireccionesScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA1A1AA),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await FirebaseAuth.instance.signOut();

                    if (!mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Producto> get _productosFiltrados {
    final textoBusqueda =
        _busquedaController.text.trim().toLowerCase();

    return _productosFirestore.where((producto) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todos' ||
              producto.categoria == _categoriaSeleccionada;

      final coincideBusqueda =
          textoBusqueda.isEmpty ||
              producto.nombre.toLowerCase().contains(textoBusqueda);

      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  int get _productosDisponibles {
    return _productosFirestore.where((producto) {
      return producto.disponible && producto.stock > 0;
    }).length;
  }


  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    const _LogoPequeno(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tienda Doña Luz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Compra fácil. Cerca de ti.',
                            style: TextStyle(
                              color: Color(0xFF8F8F98),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconoAccion(
                      icono: Icons.shopping_bag_outlined,
                      tooltip: 'Comprar',
                      onTap: () {
                        _abrir(const CatalogoScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF24150A),
                        Color(0xFF151515),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF3A2411),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hola 👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              '¿Qué quieres comprar hoy?',
                              style: TextStyle(
                                color: Color(0xFFB4B4BC),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _MiniDato(
                                  icono:
                                      Icons.check_circle_outline_rounded,
                                  valor:
                                      '$_productosDisponibles',
                                  texto: 'disponibles',
                                ),
                                const SizedBox(width: 18),
                                _MiniDato(
                                  icono:
                                      Icons.inventory_2_outlined,
                                  valor:
                                      '${_productosFirestore.length}',
                                  texto: 'productos',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFF008F68)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF008F68)
                                .withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Color(0xFF006B4F),
                          size: 31,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: TextField(
                  controller: _busquedaController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF006B4F),
                    ),
                    suffixIcon:
                        _busquedaController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _busquedaController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                              )
                            : const Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF777780),
                              ),
                    filled: true,
                    fillColor: const Color(0xFF151515),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF242424),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF242424),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF008F68),
                        width: 1.4,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  0,
                ),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categorias.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final categoria =
                          _categorias[index];

                      final seleccionada =
                          categoria ==
                              _categoriaSeleccionada;

                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _categoriaSeleccionada =
                                categoria;
                          });
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 180),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            color: seleccionada
                                ? const Color(0xFF008F68)
                                : const Color(0xFF151515),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: seleccionada
                                  ? const Color(0xFF008F68)
                                  : const Color(0xFF292929),
                            ),
                          ),
                          alignment:
                              Alignment.center,
                          child: Text(
                            categoria,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: seleccionada
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  25,
                  20,
                  12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compra lo que necesitas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Productos disponibles en tienda',
                            style: TextStyle(
                              color: Color(0xFF76767F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _abrir(const CatalogoScreen());
                      },
                      child: const Text(
                        'Ver todos',
                        style: TextStyle(
                          color: Color(0xFF006B4F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (productos.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    30,
                    20,
                    40,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius:
                          BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF242424),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          color: Color(0xFF006B4F),
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No encontramos productos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _productosFirestore.isEmpty
                              ? 'Cargando catálogo...'
                              : 'Prueba con otra búsqueda o categoría.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF777780),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  28,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final producto =
                          productos[index];

                      return _ProductoInicioCard(
                        producto: producto,
                        onTap: () {
                          _abrir(
                            const CatalogoScreen(),
                          );
                        },
                      );
                    },
                    childCount:
                        productos.length > 4
                            ? 4
                            : productos.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  30,
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF242424),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006B4F)
                              .withValues(alpha: 0.11),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Color(0xFF006B4F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu compra, fácil y segura',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Haz tu pedido y consulta su estado desde la app.',
                              style: TextStyle(
                                color: Color(0xFF777780),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF101010),
          indicatorColor:
              const Color(0xFF008F68).withValues(alpha: 0.16),
          labelTextStyle:
              WidgetStateProperty.all(
            const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: _navegar,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: Color(0xFF8A8A92),
              ),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: Color(0xFF006B4F),
              ),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF8A8A92),
              ),
              selectedIcon: Icon(
                Icons.shopping_bag_rounded,
                color: Color(0xFF006B4F),
              ),
              label: 'Comprar',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF8A8A92),
              ),
              selectedIcon: Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF006B4F),
              ),
              label: 'Pedidos',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF8A8A92),
              ),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: Color(0xFF006B4F),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPequeno extends StatelessWidget {
  const _LogoPequeno();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF33200E),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: Color(0xFF008F68),
            size: 28,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: Color(0xFF006B4F),
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

class _IconoAccion extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  const _IconoAccion({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icono,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String texto;

  const _MiniDato({
    required this.icono,
    required this.valor,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          color: const Color(0xFF006B4F),
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF777780),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ProductoInicioCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const _ProductoInicioCard({
    required this.producto,
    required this.onTap,
  });

  String _precio(double precio) {
    return '\$${precio.toStringAsFixed(0)}';
  }

  Widget _imagenProducto() {
    if (producto.imagen.isEmpty) {
      return const Icon(
        Icons.shopping_basket_rounded,
        color: Color(0xFF006B4F),
        size: 48,
      );
    }

    try {
      return Image.memory(
        base64Decode(producto.imagen),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.shopping_basket_rounded,
            color: Color(0xFF006B4F),
            size: 48,
          );
        },
      );
    } catch (_) {
      return const Icon(
        Icons.shopping_basket_rounded,
        color: Color(0xFF006B4F),
        size: 48,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponible =
        producto.disponible && producto.stock > 0;

    final stockBajo =
        disponible && producto.stock <= 5;

    return Material(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF21170D),
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(17),
                        child: _imagenProducto(),
                      ),
                    ),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: disponible
                              ? const Color(0xFF111111)
                              : const Color(0xFF3A1515),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          disponible
                              ? (stockBajo
                                  ? 'Pocos'
                                  : 'Disponible')
                              : 'Agotado',
                          style: TextStyle(
                            color: disponible
                                ? const Color(0xFF006B4F)
                                : const Color(0xFFEF4444),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: disponible
                              ? const Color(0xFF008F68)
                              : const Color(0xFF303030),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                producto.unidadVenta,
                style: const TextStyle(
                  color: Color(0xFF777780),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _precio(producto.precio),
                      style: const TextStyle(
                        color: Color(0xFF006B4F),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (disponible)
                    Text(
                      '${producto.stock}',
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}











