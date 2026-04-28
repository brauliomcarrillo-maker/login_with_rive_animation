import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // control para ocultar/mostrar contraseña
  bool _obscureText = true;

  // cerebro de la lógica de la animación
  StateMachineController? _controller;

  // state machine input
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  //2.1 variable para el recorrido de la mirada
  SMINumber? _numLook;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //1.1 crear variables para focusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  //3.2 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 4.1 Controllers para manipular texto
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // 4.2 errores para UI
  String? emailError;
  String? passwordError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 Acción al boton
  void _onLogin() {
    //de lo que escribio el usuario, quita espacos
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    //recalcular posibles errores
    final emailUIError = isValidEmail(email) ? null : 'Email inválido';
    final passwordUIError = isValidPassword(password)
        ? null
        : 'Contraseña inválida';

    //4.5 notifiquen cambios en la UI
    setState(() {
      emailError = emailUIError;
      passwordError = passwordUIError;
    });

    //4.6 CERRAR EL TECLADO Y BAJAR MANOS
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.7 disparar animación de éxito o error (activar trigers)
    if (emailUIError == null && passwordUIError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        //verificar que no sea nulo
        if (_isHandsUp != null) {
          //Manos abajo en el email
          _isHandsUp?.change(false);
          //2.2 Mirada neutral
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocusNode.addListener(() {
      //Manos arriba en el password
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    // tamaño de la pantalla
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Evita notch o cámaras frontales
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100.0),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: size.height * 0.4,
                child: RiveAnimation.asset(
                  'animated_login_character.riv',
                  stateMachines: const ['Login Machine'],
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    if (_controller == null) return;

                    artboard.addController(_controller!);

                    _isChecking =
                        _controller!.findSMI('isChecking') as SMIBool?;
                    _isHandsUp = _controller!.findSMI('isHandsUp') as SMIBool?;
                    _numLook = _controller!.findSMI('numLook') as SMINumber?;
                    _trigSuccess =
                        _controller!.findSMI('trigSuccess') as SMITrigger?;
                    _trigFail = _controller!.findSMI('trigFail') as SMITrigger?;
                  },
                ),
              ),
              const SizedBox(height: 10),
              //email
              TextField(
                //4.8 Enlazar controller
                controller: emailCtrl,
                //1.3 Vincular el docus al campo de texto
                focusNode: _emailFocusNode,
                onChanged: (value) {
                  if (_isHandsUp != null) {
                    _isHandsUp!.change(false);
                  }
                  if (_isChecking == null) return;
                  _isChecking!.change(true);
                  //2.4 Implementar Lógica
                  //Ajustes son del 0 al 100. 80 medida de calibración
                  //CLamp es un rango y se traduce como abrazadera
                  final double look = (value.length / 80.0 * 100.0).clamp(
                    0,
                    100,
                  );
                  _numLook?.value = look;

                  //3.3 Implementar debounce (temporizador)
                  //cancelar cualquier posible timer existente
                  _typingDebounce?.cancel();
                  //Crear un nuevo timer
                  _typingDebounce = Timer(const Duration(seconds: 3), () {
                    //Si se cierra a pantalla, quita el contador
                    if (!mounted) return;
                    //Mirada neutra
                    _isChecking?.change(false);
                  });
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: emailError,
                ),
              ),
              //contraseña
              const SizedBox(height: 10),
              TextField(
                controller: passwordCtrl,
                onChanged: (value) {
                  if (_isChecking != null) {
                    _isChecking!.change(false);
                  }
                  if (_isHandsUp == null) return;
                  _isHandsUp!.change(true);
                },
                obscureText: _obscureText,
                decoration: InputDecoration(
                  errorText: passwordError,
                  hintText: 'Contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              //Texto de olvide contraseña
              SizedBox(
                width: size.width,
                child: const Text(
                  'Olvidé mi contraseña',
                  textAlign: TextAlign.end,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: 10),
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                onPressed: _onLogin,
                child: Text(
                  "Login",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),

              SizedBox(
                width: size.width,
                child: Row(
                  children: [
                    const Text("¿No tienes una cuenta?"),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Regístrate",
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
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

  //1.4 Liberar memoria al salir de la pantalla
  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
    // super.dispose();
  }
}
