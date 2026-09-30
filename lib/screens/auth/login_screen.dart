import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../main.dart';
import '../store/panel_tienda_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _registro = false;
  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _recordarCuenta = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late AnimationController _animationController;
  late Animation<double> _fade;
  late final Future<void> _googleInitialization;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _cargarCuentaGuardada();

    _googleInitialization = GoogleSignIn.instance.initialize(
      serverClientId:
          '881064006117-662aon295fh0umqrb6vgfdbibc0rdkgo.apps.googleusercontent.com',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _cargarCuentaGuardada() async {
    final recordar = await _storage.read(key: 'recordar_cuenta') == 'true';

    if (!recordar) return;

    final email = await _storage.read(key: 'correo_guardado');
    final password = await _storage.read(key: 'password_guardada');

    if (!mounted) return;

    setState(() {
      _recordarCuenta = true;
      _emailController.text = email ?? '';
      _passwordController.text = password ?? '';
    });
  }

  Future<void> _guardarDatosCuenta({
    required String email,
    String? password,
  }) async {
    if (_recordarCuenta) {
      await _storage.write(
        key: 'recordar_cuenta',
        value: 'true',
      );

      await _storage.write(
        key: 'correo_guardado',
        value: email,
      );

      if (password != null) {
        await _storage.write(
          key: 'password_guardada',
          value: password,
        );
      }
    } else {
      await _storage.delete(key: 'recordar_cuenta');
      await _storage.delete(key: 'correo_guardado');
      await _storage.delete(key: 'password_guardada');
    }
  }
  Future<void> _guardarPerfil(
    User user, {
    required String proveedor,
    String? nombre,
    String? telefono,
  }) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': user.email,
      'nombre': nombre ?? user.displayName,
      'telefono': telefono ?? '',
      'fotoUrl': user.photoURL,
      'proveedor': proveedor,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _continuarGoogle() async {
    setState(() => _cargando = true);

    try {
      await _googleInitialization;

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      await _storage.delete(key: 'recordar_cuenta');
      await _storage.delete(key: 'correo_guardado');
      await _storage.delete(key: 'password_guardada');


      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _guardarPerfil(
          user,
          proveedor: 'google',
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (_, animation, _) =>
                FirebaseAuth.instance.currentUser?.uid ==
                        'rIaFe7m83VOllbxzMJNftWE93aj2'
                    ? const PanelTiendaScreen()
                    : const InicioPage(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      _mostrarError(
        'No fue posible iniciar con Google.',
      );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _continuarCorreo() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _mostrarError(
        'Ingresa tu correo y contraseña.',
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      if (_registro) {
        final credencial =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credencial.user;

        if (user != null) {
          await user.sendEmailVerification();
          await _guardarPerfil(
            user,
            proveedor: 'correo',
            nombre: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
          );

          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          _mostrarError(
            'Cuenta creada. Te enviamos un correo para verificar tu dirección. Verifica tu correo antes de iniciar sesión.',
          );
          return;
        }
      } else {
        final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credencial.user?.reload();
        final usuario = FirebaseAuth.instance.currentUser;

        if (usuario != null && !usuario.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _mostrarError(
            'Debes verificar tu correo electrónico antes de ingresar. Revisa tu bandeja de entrada.',
          );
          return;
        }
      }


        await _guardarDatosCuenta(
          email: email,
          password: password,
        );
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (_, animation, _) =>
                FirebaseAuth.instance.currentUser?.uid ==
                        'rIaFe7m83VOllbxzMJNftWE93aj2'
                    ? const PanelTiendaScreen()
                    : const InicioPage(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No fue posible completar la operación.';

      if (e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'email-already-in-use') {
        mensaje = 'Este correo ya está registrado.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña debe ser más segura.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo electrónico no es válido.';
      }

      _mostrarError(mensaje);
    } catch (_) {
      _mostrarError(
        'Ocurrió un error. Inténtalo nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF242424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF006B4F).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF008F68).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                34,
                24,
                30,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      const _AuthLogo(),
                      const SizedBox(height: 20),
                      Text(
                        _registro
                            ? 'Crea tu cuenta'
                            : '¡Bienvenido!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _registro
                            ? 'Regístrate y compra fácil desde tu celular.'
                            : 'Compra todo lo que necesitas desde tu tienda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_registro) ...[
                        _Campo(
                          controller: _nombreController,
                          label: 'Nombre completo',
                          icono: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        _Campo(
                          controller: _telefonoController,
                          label: 'Tel?fono',
                          icono: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _Campo(
                        controller: _emailController,
                        label: 'Correo electrónico',
                        icono: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _Campo(
                        controller: _passwordController,
                        label: 'Contraseña',
                        icono: Icons.lock_outline_rounded,
                        obscureText: _ocultarPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _ocultarPassword = !_ocultarPassword;
                            });
                          },
                          icon: Icon(
                            _ocultarPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Checkbox(
                            value: _recordarCuenta,
                            onChanged: _cargando
                                ? null
                                : (valor) {
                                    setState(() {
                                      _recordarCuenta = valor ?? false;
                                    });
                                  },
                            activeColor: const Color(0xFF006B4F),
                            checkColor: Colors.white,
                          ),
                          const Text(
                            'Recordar cuenta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed:
                              _cargando ? null : _continuarCorreo,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF008F68),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: _cargando
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _registro
                                      ? 'Crear cuenta'
                                      : 'Iniciar sesión',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Color(0xFF333333),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            child: Text(
                              'o continúa con',
                              style: TextStyle(
                                color: Color(0xFF71717A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed:
                              _cargando ? null : _continuarGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 30,
                          ),
                          label: const Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF151515),
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFF333333),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _cargando
                            ? null
                            : () {
                                setState(() {
                                  _registro = !_registro;
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: _registro
                                    ? '¿Ya tienes una cuenta? '
                                    : '¿No tienes una cuenta? ',
                              ),
                              TextSpan(
                                text: _registro
                                    ? 'Iniciar sesión'
                                    : 'Crear cuenta',
                                style: const TextStyle(
                                  color: Color(0xFF006B4F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tienda Doña Luz',
                        style: TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: const Color(0xFF006B4F).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: Color(0xFF006B4F),
            size: 52,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: Color(0xFF008F68),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _Campo({
    required this.controller,
    required this.label,
    required this.icono,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFFA1A1AA),
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF006B4F),
        ),
        prefixIcon: Icon(
          icono,
          color: const Color(0xFF006B4F),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF151515),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF262626),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF008F68),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}





















