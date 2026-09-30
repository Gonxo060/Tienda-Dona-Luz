import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  User? get _usuario => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    final usuario = _usuario;

    if (usuario == null) {
      if (mounted) {
        setState(() => _cargando = false);
      }
      return;
    }

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final datos = documento.data();

      _nombreController.text =
          (datos?['nombre'] as String?) ??
          usuario.displayName ??
          '';

      _telefonoController.text =
          (datos?['telefono'] as String?) ?? '';
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
          'No fue posible cargar tu perfil.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _guardarPerfil() async {
    final usuario = _usuario;

    if (usuario == null) {
      _mostrarMensaje(
        'No hay un usuario autenticado.',
        error: true,
      );
      return;
    }

    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (nombre.isEmpty) {
      _mostrarMensaje(
        'Ingresa tu nombre.',
        error: true,
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .set({
        'nombre': nombre,
        'telefono': telefono,
        'ultimaActualizacion':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _mostrarMensaje('Perfil actualizado correctamente.');
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
          'No fue posible guardar los cambios.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }


  void _mostrarMensaje(
    String mensaje, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos personales'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : usuario == null
              ? const Center(
                  child: Text(
                    'No hay una sesión activa.',
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            const Color(0xFFE8F5EF),
                        backgroundImage:
                            usuario.photoURL != null
                                ? NetworkImage(
                                    usuario.photoURL!,
                                  )
                                : null,
                        child: usuario.photoURL == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: Color(0xFF087F5B),
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nombreController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon:
                              Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller:
                            _telefonoController,
                        keyboardType:
                            TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon:
                              Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(
                          text: usuario.email ?? '',
                        ),
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon:
                              Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed:
                              _guardando
                                  ? null
                                  : _guardarPerfil,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                ),
                          label: Text(
                            _guardando
                                ? 'Guardando...'
                                : 'Guardar cambios',
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
    );
  }
}







