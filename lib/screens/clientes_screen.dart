import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _usuariosSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _clientesSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _antiguosSubscription;

  final Map<String, Map<String, dynamic>> _clientes = {};

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciarListeners();
  }

  void _iniciarListeners() {
    final tiendaUid = FirebaseAuth.instance.currentUser?.uid;

    if (tiendaUid == null) {
      _cargando = false;
      _error = 'No hay una sesión de tienda activa.';
      return;
    }

    final firestore = FirebaseFirestore.instance;

    _usuariosSubscription =
        firestore.collection('usuarios').snapshots().listen(
      _actualizarUsuarios,
      onError: (_) {
        _mostrarError('No se pudieron cargar los clientes.');
      },
    );

    _clientesSubscription =
        firestore.collection('clientes').snapshots().listen(
      _actualizarClientes,
      onError: (_) {
        _mostrarError('No se pudieron cargar los clientes.');
      },
    );

    _antiguosSubscription = firestore
        .collection('usuarios')
        .doc(tiendaUid)
        .collection('clientes')
        .snapshots()
        .listen(
      _actualizarClientesAntiguos,
      onError: (_) {
        _mostrarError('No se pudieron cargar los clientes antiguos.');
      },
    );
  }

  void _actualizarUsuarios(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final doc in snapshot.docs) {
      final data = doc.data();

      final uid =
          data['uid']?.toString().trim().isNotEmpty == true
              ? data['uid'].toString().trim()
              : doc.id;

      final anterior = _clientes[uid];

      _clientes[uid] = {
        'uid': uid,
        'nombre': data['nombre']?.toString().trim() ?? '',
        'telefono': data['telefono']?.toString().trim() ?? '',
        'proveedor':
            data['proveedor']?.toString().trim() ??
                anterior?['proveedor'] ??
                '',
      };
    }

    _actualizarVista();
  }

  void _actualizarClientes(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final doc in snapshot.docs) {
      final data = doc.data();

      final uid =
          data['uid']?.toString().trim().isNotEmpty == true
              ? data['uid'].toString().trim()
              : doc.id;

      final anterior = _clientes[uid];

      final nombre = data['nombre']?.toString().trim() ?? '';
      final telefono = data['telefono']?.toString().trim() ?? '';

      _clientes[uid] = {
        'uid': uid,
        'nombre': nombre.isNotEmpty
            ? nombre
            : anterior?['nombre'] ?? '',
        'telefono': telefono.isNotEmpty
            ? telefono
            : anterior?['telefono'] ?? '',
        'proveedor':
            data['proveedor']?.toString().trim().isNotEmpty == true
                ? data['proveedor'].toString().trim()
                : anterior?['proveedor'] ?? '',
      };
    }

    _actualizarVista();
  }

  void _actualizarClientesAntiguos(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final doc in snapshot.docs) {
      final data = doc.data();

      final id = doc.id;

      final nombre = data['nombre']?.toString().trim() ?? '';
      final telefono = data['telefono']?.toString().trim() ?? '';

      final existente = _clientes[id];

      _clientes[id] = {
        'uid': id,
        'nombre':
            nombre.isNotEmpty
                ? nombre
                : existente?['nombre'] ?? '',
        'telefono':
            telefono.isNotEmpty
                ? telefono
                : existente?['telefono'] ?? '',
        'proveedor':
            existente?['proveedor'] ?? 'antiguo',
      };
    }

    _actualizarVista();
  }

  void _actualizarVista() {
    if (!mounted) return;

    setState(() {
      _cargando = false;
      _error = null;
    });
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() {
      _cargando = false;
      _error = mensaje;
    });
  }

  List<Map<String, dynamic>> get _listaClientes {
    final lista = _clientes.values.toList();

    lista.sort((a, b) {
      final nombreA =
          a['nombre']?.toString().toLowerCase() ?? '';

      final nombreB =
          b['nombre']?.toString().toLowerCase() ?? '';

      return nombreA.compareTo(nombreB);
    });

    return lista;
  }

  @override
  void dispose() {
    _usuariosSubscription?.cancel();
    _clientesSubscription?.cancel();
    _antiguosSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Clientes'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Clientes'),
        ),
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    final lista = _listaClientes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body:
          lista.isEmpty
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No hay clientes registrados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Los clientes aparecerán aquí automáticamente.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final cliente = lista[index];

                  final nombre =
                      cliente['nombre']?.toString().trim() ?? '';

                  final telefono =
                      cliente['telefono']?.toString().trim() ?? '';

                  final proveedor =
                      cliente['proveedor']?.toString().trim() ?? '';

                  final inicial =
                      nombre.isNotEmpty
                          ? nombre[0].toUpperCase()
                          : '?';

                  String registro = '';

                  if (proveedor == 'google') {
                    registro = 'Google';
                  } else if (proveedor == 'correo') {
                    registro = 'Cuenta de la app';
                  } else if (proveedor == 'antiguo') {
                    registro = 'Cliente anterior';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF008F68),
                        foregroundColor: Colors.white,
                        child: Text(
                          inicial,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        nombre.isNotEmpty
                            ? nombre
                            : 'Cliente sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (telefono.isNotEmpty)
                            Text('Teléfono: $telefono'),
                          if (registro.isNotEmpty)
                            Text('Registro: $registro'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}