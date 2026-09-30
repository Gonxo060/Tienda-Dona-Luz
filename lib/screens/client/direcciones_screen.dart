import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DireccionesScreen extends StatefulWidget {
  const DireccionesScreen({super.key});

  @override
  State<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends State<DireccionesScreen> {
  User? get _usuario => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _direcciones {
    final usuario = _usuario;

    if (usuario == null) return null;

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('direcciones');
  }

  Future<void> _mostrarFormulario({
    DocumentSnapshot<Map<String, dynamic>>? documento,
  }) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _FormularioDireccion(
          documento: documento,
          coleccion: _direcciones,
        );
      },
    );

    if (guardado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dirección guardada correctamente.'),
        ),
      );
    }
  }

  Future<void> _eliminar(
    DocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar dirección'),
          content: const Text(
            '¿Quieres eliminar esta dirección?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await documento.reference.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirección eliminada.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible eliminar la dirección.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    final coleccion = _direcciones;

    if (usuario == null || coleccion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis direcciones'),
        ),
        body: const Center(
          child: Text('No hay una sesión activa.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis direcciones'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: coleccion
            .orderBy('principal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No fue posible cargar tus direcciones.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          if (documentos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tienes direcciones guardadas.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Agrega una dirección para usarla en tus pedidos.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: documentos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final documento = documentos[index];
              final datos = documento.data();

              final nombre =
                  (datos['nombre'] as String?) ?? 'Dirección';

              final direccion =
                  (datos['direccion'] as String?) ?? '';

              final barrio =
                  (datos['barrio'] as String?) ?? '';

              final ciudad =
                  (datos['ciudad'] as String?) ?? '';

              final principal =
                  (datos['principal'] as bool?) ?? false;

              final tieneUbicacion =
                  datos['latitud'] != null &&
                  datos['longitud'] != null;

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: Icon(
                      principal
                          ? Icons.star_rounded
                          : Icons.location_on_outlined,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (principal)
                        const Chip(
                          label: Text('Principal'),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            direccion,
                            if (barrio.isNotEmpty) barrio,
                            if (ciudad.isNotEmpty) ciudad,
                          ].join(', '),
                        ),
                        if (tieneUbicacion) ...[
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 15,
                                color: Color(0xFF008F68),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Ubicación GPS guardada',
                                style: TextStyle(
                                  color: Color(0xFF008F68),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (valor) {
                      if (valor == 'editar') {
                        _mostrarFormulario(
                          documento: documento,
                        );
                      } else if (valor == 'eliminar') {
                        _eliminar(documento);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FormularioDireccion extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>>? documento;
  final CollectionReference<Map<String, dynamic>>? coleccion;

  const _FormularioDireccion({
    required this.documento,
    required this.coleccion,
  });

  @override
  State<_FormularioDireccion> createState() =>
      _FormularioDireccionState();
}

class _FormularioDireccionState
    extends State<_FormularioDireccion> {
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _barrioController;
  late final TextEditingController _ciudadController;

  late bool _principal;
  bool _guardando = false;
  bool _obteniendoUbicacion = false;

  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();

    final datos = widget.documento?.data();

    _nombreController = TextEditingController(
      text: (datos?['nombre'] as String?) ?? '',
    );

    _direccionController = TextEditingController(
      text: (datos?['direccion'] as String?) ?? '',
    );

    _barrioController = TextEditingController(
      text: (datos?['barrio'] as String?) ?? '',
    );

    _ciudadController = TextEditingController(
      text: (datos?['ciudad'] as String?) ?? '',
    );

    _principal = (datos?['principal'] as bool?) ?? false;

    _latitud = (datos?['latitud'] as num?)?.toDouble();
    _longitud = (datos?['longitud'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _barrioController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  Future<void> _usarUbicacionActual() async {
    if (_obteniendoUbicacion || _guardando) return;

    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      final servicioActivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('GPS desactivado'),
              content: const Text(
                'Activa la ubicación de tu teléfono para '
                'poder obtener tu posición actual.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Geolocator.openLocationSettings();
                  },
                  child: const Text('Abrir ajustes'),
                ),
              ],
            ),
          );
        }
        return;
      }

      var permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied) {
        throw Exception(
          'El permiso de ubicación fue rechazado.',
        );
      }

      if (permiso == LocationPermission.deniedForever) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permiso de ubicación bloqueado'),
              content: const Text(
                'El permiso de ubicación está bloqueado. '
                'Debes habilitarlo desde los ajustes de la aplicación.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Geolocator.openAppSettings();
                  },
                  child: const Text('Abrir ajustes'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicación GPS obtenida correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible obtener la ubicación: $e',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
        });
      }
    }
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty ||
        _ciudadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa nombre, dirección y ciudad.',
          ),
        ),
      );
      return;
    }

    final coleccion = widget.coleccion;

    if (coleccion == null) return;

    setState(() {
      _guardando = true;
    });

    try {
      if (_principal) {
        final existentes = await coleccion.get();

        for (final item in existentes.docs) {
          if (widget.documento == null ||
              item.id != widget.documento!.id) {
            await item.reference.update({
              'principal': false,
            });
          }
        }
      }

      final datosDireccion = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'barrio': _barrioController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'principal': _principal,
        'ultimaActualizacion':
            FieldValue.serverTimestamp(),
      };

      if (_latitud != null && _longitud != null) {
        datosDireccion['latitud'] = _latitud;
        datosDireccion['longitud'] = _longitud;
      }

      if (widget.documento == null) {
        datosDireccion['creadaEn'] =
            FieldValue.serverTimestamp();

        await coleccion.add(datosDireccion);
      } else {
        await widget.documento!.reference.update(
          datosDireccion,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No fue posible guardar la dirección.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.documento == null
            ? 'Nueva dirección'
            : 'Editar dirección',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la dirección',
                hintText: 'Casa, trabajo...',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _direccionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                hintText: 'Carrera, calle, número...',
                prefixIcon:
                    Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barrioController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Barrio',
                prefixIcon:
                    Icon(Icons.home_work_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ciudadController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                prefixIcon:
                    Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _obteniendoUbicacion || _guardando
                    ? null
                    : _usarUbicacionActual,
                icon: _obteniendoUbicacion
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.gps_fixed),
                label: Text(
                  _obteniendoUbicacion
                      ? 'Obteniendo ubicación...'
                      : 'Usar mi ubicación actual',
                ),
              ),
            ),

            if (_latitud != null && _longitud != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF006B4F),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xFF008F68),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ubicación GPS lista para guardar.',
                          style: TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _principal,
              onChanged: _guardando
                  ? null
                  : (value) {
                      setState(() {
                        _principal = value ?? false;
                      });
                    },
              title: const Text(
                'Usar como dirección principal',
              ),
              controlAffinity:
                  ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
