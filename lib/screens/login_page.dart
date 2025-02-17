import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'my_app_state.dart';

// Constantes para configuración
class ApiConfig {
  // Asegúrate que esta URL sea exactamente igual
  static String get baseUrl => 'qs2lazfd23.execute-api.sa-east-1.amazonaws.com';
  static String get endpoint => '/Test2/empresa/Operadores';
  static String get empresaId => '1';
}

class LoginResponse {
  // Agregar los campos adicionales que vienen en la respuesta
  final String rut;
  final int empresa;
  final int zonaAsignada;
  final int ubicacionAsignada;
  final String tipo;
  final String nombreUbicacion;
  final int idTarifa;
  final String nombreTarifa;
  // ... puedes agregar los demás campos si los necesitas

  LoginResponse({
    required this.rut,
    required this.empresa,
    required this.zonaAsignada,
    required this.ubicacionAsignada,
    required this.tipo,
    required this.nombreUbicacion,
    required this.idTarifa,
    required this.nombreTarifa,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      rut: json['Rut'] as String,
      empresa: json['Empresa'] as int,
      zonaAsignada: json['Zona Asignada'] as int,
      ubicacionAsignada: json['Ubicación Asignada'] as int,
      tipo: json['Tipo'] as String,
      nombreUbicacion: json['Nombre Ubicación'] as String,
      idTarifa: json['ID_Tarifa'] as int,
      nombreTarifa: json['NombreTarifa'] as String,
    );
  }
}

// Servicio de autenticación
class AuthService {
  static Future<LoginResponse> login(String rut, String password) async {
    try {
      final queryParams = {
        'empresa': ApiConfig.empresaId,
        'rut': rut,
        'password': password,
      };

      final uri = Uri.https(
        ApiConfig.baseUrl,
        ApiConfig.endpoint,
        queryParams,
      );

      print('Intentando conexión a: $uri'); // Debug log

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        throw Exception('Error en la autenticación');
      }
    } catch (e) {
      print('Error detallado: $e'); // Debug log
      throw Exception('Error de conexión: $e');
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _rutController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRut(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su RUT';
    }
    // Aquí puedes agregar más validaciones específicas para el formato RUT
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su contraseña';
    }
    if (value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final rut = _rutController.text.trim();
      final password = _passwordController.text.trim();

      final loginResponse = await AuthService.login(rut, password);

      if (!mounted) return;

      if (loginResponse.rut == rut) {
        final appState = Provider.of<MyAppState>(context, listen: false);
        appState.setLoggedIn(true);
        appState.setRut(rut);
        appState.setEmpresaId(loginResponse.empresa);
        appState.setZonaId(loginResponse.zonaAsignada);
        appState.setUbicacionId(loginResponse.ubicacionAsignada);

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'RUT o contraseña incorrectos';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF244ba6),
              const Color(0xFF244ba6).withOpacity(0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Logo o ícono
                    Container(
                      height: 100,
                      width: 100,
                      padding: const EdgeInsets.all(
                          15), // Padding para que el isotipo no toque los bordes
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/Isotipo-Red-Parking-Color-PNG-RGB.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Bienvenido a\nRedParking',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Card contenedor del formulario
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _rutController,
                            validator: _validateRut,
                            decoration: InputDecoration(
                              labelText: 'RUT',
                              hintText: 'Ingrese su RUT',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF244ba6),
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF244ba6),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Ingrese su contraseña',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF244ba6),
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF244ba6),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF244ba6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: !_isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _attemptLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF244ba6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
