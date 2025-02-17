import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Constantes para configuración
class ApiConfig {
  static const String baseUrl =
      'qs2lazfd23.execute-api.sa-east-1.amazonaws.com';
  static const String endpoint = '/Test2/empresa/Operadores';
  static const String empresaId = '1';
}

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

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('Raw response body: ${response.body}'); // Log de depuración

      // Parsear directamente el cuerpo de la respuesta
      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedBody = jsonDecode(response.body);

        return LoginResponse.fromJson(parsedBody);
      } else {
        throw Exception('Error en la autenticación');
      }
    } catch (e) {
      print('Error en login: $e'); // Log de depuración
      throw Exception('Error de conexión: $e');
    }
  }
}

class LoginResponse {
  final String rut;
  final String tipo;
  final int empresa;
  final int zonaAsignada;
  final int ubicacionAsignada;
  final String nombreUbicacion;
  final dynamic tarifaInfo;

  LoginResponse({
    required this.rut,
    required this.tipo,
    required this.empresa,
    required this.zonaAsignada,
    required this.ubicacionAsignada,
    required this.nombreUbicacion,
    required this.tarifaInfo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      rut: json['Rut']?.toString() ?? '',
      tipo: json['Tipo']?.toString() ?? '',
      empresa: json['Empresa'] as int? ?? 0,
      zonaAsignada: json['Zona Asignada'] as int? ?? 0,
      ubicacionAsignada: json['Ubicación Asignada'] as int? ?? 0,
      nombreUbicacion: json['Nombre Ubicación']?.toString() ?? '',
      tarifaInfo: json,
    );
  }
}

class InspeccionesLoginPage extends StatefulWidget {
  const InspeccionesLoginPage({super.key});

  @override
  _InpeccionesLoginPageState createState() => _InpeccionesLoginPageState();
}

class _InpeccionesLoginPageState extends State<InspeccionesLoginPage> {
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
      final loginResponse = await AuthService.login(
        _rutController.text,
        _passwordController.text,
      );

      // Verificar si el tipo de operador es 2
      if (loginResponse.tipo != '2') {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Acceso Denegado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No tiene permisos para acceder a esta sección.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return;
      }

      // Si el tipo es correcto, proceder con la consulta de vehículos
      DateTime now = DateTime.now();
      String year = now.year.toString();
      String month = now.month.toString().padLeft(2, '0');
      String day = now.day.toString().padLeft(2, '0');

      final url = Uri.https(
          'qs2lazfd23.execute-api.sa-east-1.amazonaws.com',
          '/Test2/empresa/${ApiConfig.empresaId}/inspecciones/2',
          {'year': year, 'month': month, 'day': day});

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF244ba6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Autos Estacionados',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Counter
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Total Estacionados: ${data['ocupados']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF244ba6),
                          ),
                        ),
                      ),
                      // Table Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Patente',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Hora Ingreso',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Table Content
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount:
                              (data['movimientos'] as List?)?.length ?? 0,
                          itemBuilder: (context, index) {
                            final movimiento = data['movimientos'][index];
                            DateTime? ingresoDate = DateTime.tryParse(
                                movimiento['Ingreso']?.toString() ?? '');
                            String horaFormateada = ingresoDate != null
                                ? '${ingresoDate.hour.toString().padLeft(2, '0')}:${ingresoDate.minute.toString().padLeft(2, '0')}'
                                : 'N/A';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      movimiento['Patente']?.toString() ??
                                          'N/A',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      horaFormateada,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        throw Exception('Error en la respuesta: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('No se pudo completar la operación: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      }
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
                    const SizedBox(height: 32),
                    Text(
                      'Ingreso a\nInspecciones',
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
                                'Ingresar a inspecciones',
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
