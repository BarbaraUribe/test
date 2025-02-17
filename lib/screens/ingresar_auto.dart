import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'my_app_state.dart';
import 'payment_service.dart';

const String apiBaseUrl =
    'https://qs2lazfd23.execute-api.sa-east-1.amazonaws.com/Test2';

enum PaymentType { marcarSalida, pagoAnticipado, beneficio, pagarDeuda }

class IngresoAutoPage extends StatefulWidget {
  @override
  IngresoAutoPageState createState() => IngresoAutoPageState();
}

class IngresoAutoPageState extends State<IngresoAutoPage> {
  final TextEditingController _patenteController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isButtonEnabled = false;
  Map<String, dynamic>? _responseData;
  String? _idMovimiento;

  bool _isIngresoSalidaEnabled = false;
  bool _isPagoAnticipadoEnabled = false;
  bool _isDeudaEnabled = false;
  bool _isBeneficioEnabled = false;

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _patenteController.addListener(() {
      setState(() {
        // Habilitar/deshabilitar el botón de consulta según la longitud
        _isButtonEnabled = _patenteController.text.length >= 5;

        // Deshabilitar todos los botones de acción cuando el texto cambia
        _isIngresoSalidaEnabled = false;
        _isPagoAnticipadoEnabled = false;
        _isDeudaEnabled = false;
        _isBeneficioEnabled = false;

        // Limpiar los datos de respuesta y mensaje de error
        _responseData = null;
        _errorMessage = '';
        _idMovimiento = null;
      });
    });
  }

  // También podemos crear una función auxiliar para resetear los estados
  void _resetStates() {
    setState(() {
      _isIngresoSalidaEnabled = false;
      _isPagoAnticipadoEnabled = false;
      _isDeudaEnabled = false;
      _isBeneficioEnabled = false;
      _responseData = null;
      _errorMessage = '';
      _idMovimiento = null;
    });
  }

  @override
  void dispose() {
    _patenteController.dispose();
    super.dispose();
  }

  void _setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  String _getPatenteMessage(Map<String, dynamic> responseBody) {
    switch (responseBody['message']) {
      case 'Patente sin ingreso':
        return 'Patente sin movimiento';
      case 'Patente con pago anticipado':
        return 'Patente con Pago anticipado';
      default:
        return 'Patente con movimiento';
    }
  }

  DateTime _obtenerHoraIngreso() {
    try {
      if (_responseData?['Hora Ingreso'] == null) {
        print('Error: No hay hora de ingreso registrada');
        return DateTime.now();
      }

      // Obtener la hora de ingreso (formato "HH:mm")
      String horaIngresoStr = _responseData!['Hora Ingreso'];

      // Separar la hora y minutos
      List<String> partes = horaIngresoStr.split(':');
      int horaIngreso = int.parse(partes[0]);
      int minutosIngreso = int.parse(partes[1]);

      // Crear DateTime con la fecha actual pero la hora de ingreso
      DateTime ahora = DateTime.now();
      DateTime horaIngresoDateTime = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        horaIngreso,
        minutosIngreso,
      );

      print('Hora ingreso parseada: $horaIngresoDateTime');
      return horaIngresoDateTime;
    } catch (e) {
      print('Error al obtener hora de ingreso: $e');
      return DateTime.now();
    }
  }

  String _obtenerMinutosTranscurridos() {
    try {
      DateTime horaIngreso = _obtenerHoraIngreso();
      DateTime ahora = DateTime.now();

      // Calcular diferencia
      int minutosTranscurridos = ahora.difference(horaIngreso).inMinutes;

      // Si el resultado es negativo (por ejemplo, de un día a otro), ajustar
      if (minutosTranscurridos < 0) {
        minutosTranscurridos = (24 * 60) + minutosTranscurridos;
      }

      print('Hora ingreso: ${horaIngreso.hour}:${horaIngreso.minute}');
      print('Hora actual: ${ahora.hour}:${ahora.minute}');
      print('Minutos transcurridos: $minutosTranscurridos');

      return minutosTranscurridos.toString();
    } catch (e) {
      print('Error al calcular minutos transcurridos: $e');
      return '0';
    }
  }

  String _calcularMontoSalida() {
    final montoTotal = int.parse(_obtenerMinutosTranscurridos());
    return (montoTotal * 30).toString();
  }

  String _obtenerMinutosTranscurridosPagoAnticipado() {
    try {
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
      final minutes = endOfDay.difference(now).inMinutes;
      print('Minutos hasta fin de día: $minutes');
      // Solo retornamos el número de minutos como string, sin la palabra "minutos"
      return minutes.toString();
    } catch (e) {
      print('Error al calcular minutos para pago anticipado: $e');
      return '0';
    }
  }

  String _calcularMontoPagoAnticipado() {
    try {
      final minutosRestantes =
          int.parse(_obtenerMinutosTranscurridosPagoAnticipado());
      int montoTotal = minutosRestantes * 30;

      // Aplicar descuento del 50% si los minutos son menores a 180
      if (minutosRestantes < 180) {
        montoTotal = (montoTotal * 0.5).round();
      }

      print('Monto calculado para pago anticipado: $montoTotal');
      return montoTotal.toString();
    } catch (e) {
      print('Error al calcular monto para pago anticipado: $e');
      return '0';
    }
  }

  Future<bool> _procesarPagoTarjeta({
    required int monto,
    required String patente,
    required String tiempo,
    required String descripcion,
    required BuildContext context,
  }) async {
    try {
      // Verificar si la app de pagos está instalada
      final isInstalled = await PaymentService.isPaymentAppInstalled();
      if (!isInstalled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La aplicación de pagos no está instalada'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      // Procesar el pago
      final response = await PaymentService.sendPayment(
        amount: monto,
        device: "TJ44246421774",
        description: descripcion,
        patente: patente,
        tiempo: tiempo,
      );

      if (response['status'] != 'success') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en el pago: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Error al procesar el pago: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

// Procesamiento de pago general
  Future<bool> _procesarPago({
    required String metodoPago,
    required int monto,
    required String patente,
    required String tiempo,
    required String descripcion,
    required BuildContext context,
  }) async {
    if (metodoPago.toLowerCase() == 'efectivo') {
      return true;
    }

    return _procesarPagoTarjeta(
      monto: monto,
      patente: patente,
      tiempo: tiempo,
      descripcion: descripcion,
      context: context,
    );
  }

// Manejo de errores en la respuesta del servidor
  void _manejarErrorServidor(dynamic error, BuildContext context) {
    print('Error en la operación: $error');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la operación: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRequest(
      String url,
      String method,
      Map<String, Object?> body,
      String successMessage,
      String failureMessage) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authToken =
          Provider.of<MyAppState>(context, listen: false).authToken;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      // Convertir Map<String, Object?> a Map<String, String>
      Map<String, String> bodyString = Map.fromIterable(
        body.keys,
        value: (key) => body[key]?.toString() ?? '',
      );

      final response = method == 'POST'
          ? await http.post(Uri.parse(url),
              headers: headers, body: json.encode(bodyString))
          : await http.put(Uri.parse(url),
              headers: headers, body: json.encode(bodyString));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _errorMessage = successMessage;
        });
      } else {
        _setErrorMessage('$failureMessage: ${response.body}');
      }
    } catch (e) {
      _setErrorMessage('Error de conexión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //Función para consultar los movimientos de la patente
  Future<void> consultarPatente() async {
    final patente = _patenteController.text;
    if (patente.isEmpty) {
      _setErrorMessage('Por favor, ingrese la patente.');
      setState(() {
        _isIngresoSalidaEnabled = false;
        _isPagoAnticipadoEnabled = false;
        _isDeudaEnabled = false;
        _isBeneficioEnabled = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isIngresoSalidaEnabled = false;
      _isPagoAnticipadoEnabled = false;
      _isDeudaEnabled = false;
      _isBeneficioEnabled = false;
    });

    try {
      final idEmpresa =
          Provider.of<MyAppState>(context, listen: false).idEmpresa;
      if (idEmpresa == null) {
        _setErrorMessage(
            'No se encontró el ID de empresa. Verifica tu sesión.');
        return;
      }

      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      final url = Uri.parse(
        '$apiBaseUrl/empresa/$idEmpresa/movimientos/$patente?fecha=$fecha',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);

        // Calcular minutos transcurridos
        if (responseBody['Hora Ingreso'] != null) {
          final horaIngreso = responseBody['Hora Ingreso'].toString();
          final horaIngresoDateTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(horaIngreso.split(':')[0]),
            int.parse(horaIngreso.split(':')[1]),
          );

          final ahora = DateTime.now();
          final diferencia = ahora.difference(horaIngresoDateTime);
          final minutosTranscurridos = diferencia.inMinutes;

          // Agregar los minutos transcurridos a la respuesta
          responseBody['minutosTranscurridos'] = minutosTranscurridos;
        }

        // Crear una copia del responseBody para _responseData
        Map<String, dynamic> cleanedResponse = {};
        responseBody.forEach((key, value) {
          cleanedResponse[key] = value ?? '';
        });

        setState(() {
          _responseData = cleanedResponse;
          _errorMessage = _getPatenteMessage(responseBody);
          _idMovimiento = responseBody.containsKey('ID Movimiento')
              ? responseBody['ID Movimiento'].toString()
              : null;

          switch (responseBody['message']) {
            case 'Patente sin ingreso':
              _isIngresoSalidaEnabled = true;
              _isPagoAnticipadoEnabled = true;
              _isDeudaEnabled = responseBody['deudas'] != 'Sin deudas';
              _isBeneficioEnabled = true;
              break;

            case 'Patente con pago anticipado':
              _isIngresoSalidaEnabled = false;
              _isPagoAnticipadoEnabled = false;
              _isDeudaEnabled = responseBody['deudas'] != 'Sin deudas';
              _isBeneficioEnabled = false;
              break;

            default:
              _isIngresoSalidaEnabled = true;
              _isPagoAnticipadoEnabled = false;
              _isDeudaEnabled = responseBody['deudas'] != 'Sin deudas';
              _isBeneficioEnabled = false;
              break;
          }
        });

        print('Patente: $patente');
        print('ID Movimiento almacenado: $_idMovimiento');
        print('Ubicación: ${_responseData?['Ubicación']}');
        print('Hora de Ingreso: ${_responseData?['Hora Ingreso']}');
        print(
            'Minutos transcurridos: ${_responseData?['minutosTranscurridos']}');
        print('Respuesta del servidor: ${response.body}');
        print('Estado de botones:');
        print('- Ingreso/Salida: $_isIngresoSalidaEnabled');
        print('- Pago Anticipado: $_isPagoAnticipadoEnabled');
        print('- Deuda: $_isDeudaEnabled');
        print('- Beneficio: $_isBeneficioEnabled');
        print(responseBody['message']);
      } else {
        _setErrorMessage(
            'Error en la solicitud: ${response.statusCode}, ${response.body}');
        setState(() {
          _isIngresoSalidaEnabled = false;
          _isPagoAnticipadoEnabled = false;
          _isDeudaEnabled = false;
          _isBeneficioEnabled = false;
        });
      }
    } catch (e) {
      _setErrorMessage('Error de conexión: $e');
      setState(() {
        _isIngresoSalidaEnabled = false;
        _isPagoAnticipadoEnabled = false;
        _isDeudaEnabled = false;
        _isBeneficioEnabled = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _showPaymentMethodModal(
      {required PaymentType paymentType}) async {
    final minutesElapsed = _responseData?['minutosTranscurridos'] ?? 0;
    final amountToPay = (minutesElapsed * 30).toString();

    String getTitle() {
      return 'Seleccione el\nmétodo de pago'; // Modificado para incluir el salto de línea
    }

    Widget buildPaymentMethodTile(String method) {
      final IconData icon;
      switch (method.toLowerCase()) {
        case 'efectivo':
          icon = Icons.payments_outlined;
          break;
        case 'débito':
          icon = Icons.credit_card_outlined;
          break;
        case 'crédito':
          icon = Icons.credit_score_outlined;
          break;
        default:
          icon = Icons.payment;
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700),
          ),
          title: Text(
            method,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.pop(context, method),
        ),
      );
    }

    Widget buildInfoCard({required String title, required String value}) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    Widget getContent() {
      switch (paymentType) {
        case PaymentType.marcarSalida:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildInfoCard(
                title: 'Tiempo transcurrido',
                value: '$minutesElapsed minutos',
              ),
              const SizedBox(height: 8),
              buildInfoCard(
                title: 'Monto a pagar',
                value: '\$$amountToPay',
              ),
            ],
          );

        case PaymentType.pagoAnticipado:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildInfoCard(
                title: 'Tiempo transcurrido',
                value: _obtenerMinutosTranscurridosPagoAnticipado(),
              ),
              const SizedBox(height: 8),
              buildInfoCard(
                title: 'Monto a pagar',
                value:
                    '\$${NumberFormat('#,##0').format(int.parse(_calcularMontoPagoAnticipado()))}',
              ),
            ],
          );

        case PaymentType.beneficio:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildInfoCard(
                title: 'Beneficio aplicable',
                value: _responseData?['tipoBeneficio'] ?? 'Estándar',
              ),
              const SizedBox(height: 8),
              buildInfoCard(
                title: 'Descuento',
                value: '${_responseData?['descuento'] ?? '0'}%',
              ),
              const SizedBox(height: 8),
              buildInfoCard(
                title: 'Monto original',
                value: '\$$amountToPay',
              ),
            ],
          );

        case PaymentType.pagarDeuda:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildInfoCard(
                title: 'Total a pagar',
                value:
                    '\$${NumberFormat('#,##0').format(_responseData?['deudaPendiente'] ?? 0)}',
              ),
              const SizedBox(height: 8),
              buildInfoCard(
                title: 'Deudas seleccionadas',
                value: '${_responseData?['cantidadDeudas'] ?? 0}',
              ),
            ],
          );
      }
    }

    return await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // Agregamos Expanded para permitir que el texto se ajuste
                      child: Text(
                        getTitle(), // Agregamos salto de línea
                        style: const TextStyle(
                          fontSize: 18, // Reducimos el tamaño de la fuente
                          fontWeight: FontWeight.bold,
                          height: 1.2, // Ajustamos el espaciado entre líneas
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                getContent(),
                const SizedBox(height: 24),
                const Text(
                  'Métodos de pago disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                buildPaymentMethodTile('Efectivo'),
                const SizedBox(height: 8),
                buildPaymentMethodTile('Débito'),
                const SizedBox(height: 8),
                buildPaymentMethodTile('Crédito'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPaymentMethodTile(String method) {
    return ListTile(
      title: Text(method),
      onTap: () => Navigator.pop(context, method),
    );
  }

  Future<Map<String, dynamic>?> _showVehicleTypeModal() async {
    String? selectedType;

    Future<Map<String, dynamic>?> showSpaceSelectionModal(
        BuildContext context, String vehicleType) async {
      final TextEditingController locationController = TextEditingController();
      final bool isMoto = vehicleType == 'moto';
      final selectedSizeNotifier = ValueNotifier<int>(0);

      Widget buildSizeButton(int size) {
        return ValueListenableBuilder<int>(
          valueListenable: selectedSizeNotifier,
          builder: (context, selectedSize, child) {
            return SizedBox(
              width: 40,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  selectedSizeNotifier.value = size;
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      selectedSize == size ? Colors.blue : Colors.grey.shade200,
                  foregroundColor:
                      selectedSize == size ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  size.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        );
      }

      return showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMoto
                            ? 'Ubicación de motocicleta'
                            : 'Detalles del espacio',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selección de tamaño para vehículos
                  if (!isMoto) ...[
                    const Text(
                      'Seleccione el tamaño del espacio:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(11, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < 10 ? 8.0 : 0,
                            ),
                            child: buildSizeButton(index),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Campo para el número de estacionamiento
                  TextField(
                    controller: locationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Número de estacionamiento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Ingrese el número de ubicación',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (locationController.text.isNotEmpty) {
                              Navigator.pop(context, {
                                'type': vehicleType,
                                'size': isMoto ? 0 : selectedSizeNotifier.value,
                                'location': int.parse(locationController.text),
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget buildVehicleTypeTile(String type, IconData icon, String label) {
      return SizedBox(
        // Agregamos SizedBox para ocupar todo el ancho
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            onTap: () async {
              selectedType = type;
              final result = await showSpaceSelectionModal(context, type);
              if (result != null) {
                Navigator.pop(context, result);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.blue.shade700, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tipo de vehículo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    buildVehicleTypeTile(
                        'vehiculo', Icons.directions_car, 'Vehículo'),
                    const SizedBox(height: 8),
                    buildVehicleTypeTile(
                        'moto', Icons.motorcycle, 'Motocicleta'),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

//Función para marcar el ingreso del vehículo
  Future<void> marcarIngreso() async {
    print('\n=== INICIANDO MARCAR INGRESO ===');

    final vehicleSelection = await _showVehicleTypeModal();
    if (vehicleSelection == null) return; // Usuario canceló la selección

    final idEmpresa = Provider.of<MyAppState>(context, listen: false).idEmpresa;
    final idZona = Provider.of<MyAppState>(context, listen: false).idZona;
    final idUbicacion =
        Provider.of<MyAppState>(context, listen: false).idUbicacion;
    final rut = Provider.of<MyAppState>(context, listen: false).rut;

    print('Datos obtenidos del Provider:');
    print('- ID Empresa: $idEmpresa');
    print('- ID Zona: $idZona');
    print('- ID Ubicación: $idUbicacion');
    print('- RUT Operador: $rut');
    print('- Tipo de vehículo: ${vehicleSelection['type']}');
    print('- Espacio seleccionado: ${vehicleSelection['space']}');

    if (idEmpresa == null) {
      print('ERROR: ID Empresa es null');
      _setErrorMessage('Faltan empresa');
      return;
    }

    final patente = _patenteController.text;
    print('\nPatente a registrar: $patente');

    final isIngreso = _responseData?['message'] == 'Patente sin ingreso';
    print('Es ingreso nuevo: $isIngreso');
    print('ID Movimiento actual: $_idMovimiento');

    if (_idMovimiento != null && !isIngreso) {
      print('ERROR: Intento de registro duplicado');
      _setErrorMessage('Ya se ha registrado una patente.');
      return;
    }

    final url = Uri.parse(
      '$apiBaseUrl/empresa/$idEmpresa/zonas/$idZona/ubicaciones/$idUbicacion/movimientos',
    );
    print('\nURL de la solicitud:');
    print(url.toString());

    final ingreso =
        DateTime.now().toIso8601String().substring(0, 19).replaceAll("T", " ");
    final ingresoFormateada =
        DateFormat('HH:mm').format(DateTime.parse(ingreso));
    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(ingreso));

    print('\nFecha y hora de ingreso: $ingreso');

    final body = {
      'Estado': 'Estacionado',
      'Operador': rut,
      'Operador Sal': '',
      'Patente': patente,
      'Espacio': vehicleSelection['space'],
      'Ingreso': ingreso,
      'Salida': '',
      'Monto': null,
      'Forma de pago': null,
    };

    print('\nCuerpo de la solicitud (body):');
    body.forEach((key, value) {
      print('- $key: $value');
    });

    print('\nEnviando solicitud POST...');
    await _handleRequest(url.toString(), 'POST', body,
        'Ingreso registrado con éxito.', 'Error al registrar ingreso');

    Widget buildInfoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar alerta de éxito
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ingreso Registrado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      buildInfoRow('Operador ejecutor', rut!),
                      buildInfoRow('Patente', patente),
                      buildInfoRow('Ubicación', idUbicacion.toString()),
                      buildInfoRow(
                          'Tipo vehículo',
                          vehicleSelection['type'] == 'vehiculo'
                              ? 'Vehículo'
                              : 'Motocicleta'),
                      if (vehicleSelection['type'] == 'vehiculo')
                        buildInfoRow('Tamaño del espacio',
                            vehicleSelection['size'].toString()),
                      buildInfoRow('Número de estacionamiento',
                          vehicleSelection['location'].toString()),
                      buildInfoRow('Fecha', fecha),
                      buildInfoRow('Ingreso', ingresoFormateada),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El vehículo ha sido registrado correctamente en el sistema',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _resetStates();
    print('Estado de los botones reestablecidos\n');
    print('=== FIN MARCAR INGRESO ===\n');
  }

  //Función para marcar la salida del vehículo
  Future<void> marcarSalida() async {
    print('\n=== INICIANDO MARCAR SALIDA ===');
    final idEmpresa = Provider.of<MyAppState>(context, listen: false).idEmpresa;
    final idZona = Provider.of<MyAppState>(context, listen: false).idZona;
    final idUbicacion =
        Provider.of<MyAppState>(context, listen: false).idUbicacion;
    final rut = Provider.of<MyAppState>(context, listen: false).rut;
    final monto = _calcularMontoSalida();
    final horaString = _obtenerHoraIngreso();
    final ingreso = DateFormat('HH:mm').format(horaString);

    if (idEmpresa == null) {
      _setErrorMessage('Faltan empresa');
      return;
    }

    final patente = _patenteController.text;

    if (_idMovimiento == null) {
      _setErrorMessage('No se ha registrado una patente.');
      return;
    }

    // Mostrar modal para seleccionar forma de pago
    final formaPago =
        await _showPaymentMethodModal(paymentType: PaymentType.marcarSalida);

    // Si no se seleccionó una forma de pago, cancelar la operación
    if (formaPago == null) {
      return;
    }

    // Si el pago es con tarjeta (débito o crédito), procesar con la app de pagos
    if (formaPago.toLowerCase() != 'efectivo') {
      final pagoExitoso = await _procesarPago(
        metodoPago: formaPago,
        monto: int.parse(monto),
        patente: patente,
        tiempo: _obtenerMinutosTranscurridos(),
        descripcion: "Pago estacionamiento - Patente: $patente",
        context: context,
      );

      if (!pagoExitoso) return;
    }

    final url = Uri.parse(
      '$apiBaseUrl/empresa/$idEmpresa/zonas/$idZona/ubicaciones/$idUbicacion/movimientos/$_idMovimiento',
    );

    final salida =
        DateTime.now().toIso8601String().substring(0, 19).replaceAll("T", " ");
    final salidaFormateada = DateFormat('HH:mm').format(DateTime.parse(salida));
    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(salida));

    final body = {
      'Estado': 'Finalizado',
      'Operador Sal': rut,
      'Patente': patente,
      'Espacio': 1,
      'Salida': salida,
      'Monto': monto,
      'Forma de pago': formaPago,
    };

    try {
      await _handleRequest(url.toString(), 'PUT', body,
          'Salida registrada con éxito.', 'Error al registrar salida');

      // Show success modal
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Salida Registrada',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          buildInfoRow('Operador ejecutor', rut!),
                          buildInfoRow('Patente', patente),
                          buildInfoRow(
                              'Ubicación', _responseData?['Ubicación'] ?? ''),
                          buildInfoRow('Fecha', fecha),
                          buildInfoRow('Ingreso', ingreso),
                          buildInfoRow('Salida', salidaFormateada),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forma de pago',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formaPago,
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Monto total',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$$monto',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Error en la operación de salida: $e');
      _setErrorMessage('Error al procesar la salida: $e');
    }

    _resetStates();
    print('Estado de los botones reestablecidos\n');
    print('=== FIN MARCAR SALIDA ===\n');
  }

  Future<void> marcarPagoAnticipado() async {
    print('\n=== INICIANDO MARCAR PAGO ANTICIPADO ===');

    // Obtener todas las variables necesarias antes de las operaciones asíncronas
    final idEmpresa = Provider.of<MyAppState>(context, listen: false).idEmpresa;
    final idZona = Provider.of<MyAppState>(context, listen: false).idZona;
    final idUbicacion =
        Provider.of<MyAppState>(context, listen: false).idUbicacion;
    final rut = Provider.of<MyAppState>(context, listen: false).rut;
    final patente = _patenteController.text;

    final isIngreso = _responseData?['message'] == 'Patente sin ingreso';

    if (idEmpresa == null) {
      _setErrorMessage('Faltan empresa');
      return;
    }

    if (_idMovimiento == null && !isIngreso) {
      _setErrorMessage('No se ha registrado una patente.');
      return;
    }

    // Mostrar modal para selección de tipo de vehículo
    final vehicleSelection = await _showVehicleTypeModal();
    if (vehicleSelection == null) return; // Usuario canceló la selección

    final monto = _calcularMontoPagoAnticipado();

    // Mostrar modal para seleccionar forma de pago
    final formaPago =
        await _showPaymentMethodModal(paymentType: PaymentType.pagoAnticipado);

    // Si no se seleccionó una forma de pago, cancelar la operación
    if (formaPago == null) {
      return;
    }

    final url = Uri.parse(
      '$apiBaseUrl/empresa/$idEmpresa/zonas/$idZona/ubicaciones/$idUbicacion/movimientos',
    );
    print('\nURL de la solicitud:');
    print(url.toString());

    final now = DateTime.now();

    // Ingreso con fecha y hora actuales
    final ingreso = now.toIso8601String().substring(0, 19).replaceAll("T", " ");

    // Salida con la misma fecha pero con la hora a las 23:59
    final salida = DateTime(now.year, now.month, now.day, 23, 59)
        .toIso8601String()
        .substring(0, 19)
        .replaceAll("T", " ");
    final salidaFormateada = DateFormat('HH:mm').format(DateTime.parse(salida));

    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(ingreso));

    final body = {
      'Estado': 'Pago anticipado',
      'Operador': rut,
      'Operador Sal': rut,
      'Patente': patente,
      'Tipo': vehicleSelection['type'],
      'Tamaño': vehicleSelection['size'],
      'Ubicacion': vehicleSelection['location'],
      'Ingreso': ingreso,
      'Salida': salida,
      'Monto': monto,
      'Forma de pago': formaPago,
    };

    print('\nCuerpo de la solicitud (body):');
    body.forEach((key, value) {
      print('- $key: $value');
    });

    print('\nEnviando solicitud POST...');
    await _handleRequest(url.toString(), 'POST', body,
        'Pago anticipado registrado con éxito.', 'Error al registrar');

    Widget buildInfoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar alerta de éxito
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pago anticipado Registrado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      buildInfoRow('Operador ejecutor', rut!),
                      buildInfoRow('Patente', patente),
                      buildInfoRow(
                          'Tipo vehículo',
                          vehicleSelection['type'] == 'vehiculo'
                              ? 'Vehículo'
                              : 'Motocicleta'),
                      if (vehicleSelection['type'] == 'vehiculo')
                        buildInfoRow('Tamaño del espacio',
                            vehicleSelection['size'].toString()),
                      buildInfoRow('Número de estacionamiento',
                          vehicleSelection['location'].toString()),
                      buildInfoRow('Fecha', fecha),
                      buildInfoRow('Ingreso',
                          DateFormat('HH:mm').format(DateTime.now())),
                      buildInfoRow('Salida', salidaFormateada),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forma de pago',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formaPago,
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Monto total',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$$monto',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _resetStates();
    print('Estado de los botones reestablecidos\n');
    print('=== FIN MARCAR PAGO ANTICIPADO ===\n');
  }

  Future<void> pagarDeudas() async {
    Map<int, bool> selectedDebts = {};
    if (_responseData?['deudas'] is List) {
      for (var deuda in _responseData!['deudas']) {
        selectedDebts[deuda['ID Deuda']] = false;
      }
    }

    double selectedAmount = 0.0;
    List<Map<String, dynamic>> selectedDebtDetails = [];

    Widget buildDebtCard(Map<String, dynamic> deuda, bool isSelected,
        Function(bool?) onChanged) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación: ${deuda['Nombre Ubicación']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${deuda['Fecha Ingreso']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,##0').format(deuda['Monto'])}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: onChanged,
                  activeColor: Colors.blue.shade700,
                ),
              ],
            ),
          ),
        ),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Seleccionar\nDeudas a Pagar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monto total a pagar',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '\$${NumberFormat('#,##0').format(selectedAmount)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_responseData?['deudas'] is List) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: const Text(
                            'Seleccionar todo',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Checkbox(
                            value: selectedDebts.values.every((value) => value),
                            onChanged: (bool? value) {
                              setState(() {
                                for (var deuda in _responseData!['deudas']) {
                                  selectedDebts[deuda['ID Deuda']] =
                                      value ?? false;
                                }
                                selectedAmount = 0.0;
                                selectedDebtDetails.clear();
                                if (value == true) {
                                  for (var deuda in _responseData!['deudas']) {
                                    selectedAmount += deuda['Monto'];
                                    selectedDebtDetails.add(deuda);
                                  }
                                }
                              });
                            },
                            activeColor: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children:
                                _responseData!['deudas'].map<Widget>((deuda) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: buildDebtCard(
                                  deuda,
                                  selectedDebts[deuda['ID Deuda']] ?? false,
                                  (bool? value) {
                                    setState(() {
                                      selectedDebts[deuda['ID Deuda']] =
                                          value ?? false;
                                      selectedAmount = 0.0;
                                      selectedDebtDetails.clear();
                                      for (var d in _responseData!['deudas']) {
                                        if (selectedDebts[d['ID Deuda']] ==
                                            true) {
                                          selectedAmount += d['Monto'];
                                          selectedDebtDetails.add(d);
                                        }
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedAmount > 0
                                ? () async {
                                    List<int> selectedDebtIds = selectedDebts
                                        .entries
                                        .where((entry) => entry.value)
                                        .map((entry) => entry.key)
                                        .toList();

                                    Navigator.pop(context);

                                    _responseData?.addAll({
                                      'deudaPendiente': selectedAmount,
                                      'fechaDeuda':
                                          selectedDebtDetails.isNotEmpty
                                              ? selectedDebtDetails
                                                  .first['Fecha Ingreso']
                                              : 'No disponible',
                                      'cantidadDeudas':
                                          selectedDebtDetails.length,
                                    });

                                    final paymentMethod =
                                        await _showPaymentMethodModal(
                                      paymentType: PaymentType.pagarDeuda,
                                    );

                                    if (paymentMethod != null) {
                                      try {
                                        final idEmpresa =
                                            Provider.of<MyAppState>(context,
                                                    listen: false)
                                                .idEmpresa;
                                        final operador =
                                            Provider.of<MyAppState>(context,
                                                    listen: false)
                                                .rut;

                                        final url = Uri.parse(
                                            'https://qs2lazfd23.execute-api.sa-east-1.amazonaws.com/Test2/empresa/$idEmpresa/deudas');

                                        final payload = {
                                          'deudas': selectedDebtIds,
                                          'formaPago':
                                              paymentMethod.toLowerCase(),
                                          'operador': operador,
                                        };

                                        if (paymentMethod.toLowerCase() !=
                                            'efectivo') {
                                          final response =
                                              await PaymentService.sendPayment(
                                            amount: selectedAmount.toInt(),
                                            device: "TJ44246421774",
                                            description: "Pago de deudas",
                                            patente: _patenteController.text,
                                            tiempo: "0",
                                          );

                                          if (response['status'] != 'success') {
                                            throw Exception(
                                                'Error en el pago con tarjeta');
                                          }
                                        }

                                        final response = await http.put(
                                          url,
                                          headers: {
                                            'Content-Type': 'application/json'
                                          },
                                          body: jsonEncode(payload),
                                        );

                                        if (response.statusCode == 200) {
                                          if (mounted) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .green.shade50,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .check_circle_outline,
                                                            color: Colors
                                                                .green.shade700,
                                                            size: 48,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        const Text(
                                                          'Pago Exitoso',
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .grey.shade50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              buildInfoRow(
                                                                  'Operador',
                                                                  operador ??
                                                                      ''),
                                                              buildInfoRow(
                                                                  'Patente',
                                                                  _patenteController
                                                                      .text),
                                                              buildInfoRow(
                                                                  'Deudas pagadas',
                                                                  '${selectedDebtIds.length}'),
                                                              buildInfoRow(
                                                                  'Forma de pago',
                                                                  paymentMethod),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .blue.shade50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                'Total pagado:',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .blue
                                                                      .shade900,
                                                                ),
                                                              ),
                                                              Text(
                                                                '\$${NumberFormat('#,##0').format(selectedAmount)}',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .blue
                                                                      .shade900,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 24),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            consultarPatente();
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.blue
                                                                    .shade700,
                                                            minimumSize:
                                                                const Size(
                                                                    double
                                                                        .infinity,
                                                                    45),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                              'Aceptar'),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        } else {
                                          throw Exception(
                                              'Error en el pago: ${response.body}');
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error al procesar el pago: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Pagar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> aplicarBeneficio() async {}

  Widget buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required List<String> descriptionLines,
    required double buttonHeight,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final backgroundColor =
        isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100;
    final iconColor = isEnabled ? color : Colors.grey;
    final textColor = isEnabled ? Colors.black87 : Colors.grey;

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.3) : Colors.grey.shade300,
          width: 2,
        ),
        color: backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? color.withOpacity(0.2)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 2), // Reducido de 8 a 4
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isEnabled)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: color,
                      ),
                  ],
                ),
                const SizedBox(
                    height: 4), // Reducido espacio antes de las descripciones
                if (descriptionLines.any((line) => line.isNotEmpty)) ...[
                  ...descriptionLines
                      .where((line) => line.isNotEmpty)
                      .map((line) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 2), // Reducido de 4 a 2
                            child: Row(
                              children: [
                                Container(
                                  width: 4, // Reducido de 6 a 4
                                  height: 4, // Reducido de 6 a 4
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? color.withOpacity(0.5)
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6), // Reducido de 8 a 6
                                Expanded(
                                  child: Text(
                                    line,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isEnabled
                                          ? Colors.black54
                                          : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

// Ejemplo de uso en el build:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Añadimos SafeArea para evitar conflictos con la barra de estado
        child: SingleChildScrollView(
          // Permite scroll
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize
                  .min, // Asegura que la columna tome el mínimo espacio necesario
              children: <Widget>[
                TextField(
                  controller: _patenteController,
                  decoration: InputDecoration(
                    labelText: 'Patente',
                    hintText: 'Ingrese la patente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF244ba6), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xFF244ba6)),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _resetStates();
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      _isButtonEnabled && !_isLoading ? consultarPatente : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF244ba6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Consultar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF244ba6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF244ba6).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF244ba6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: const Color(0xFF244ba6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildActionButton(
                        label: !_isIngresoSalidaEnabled
                            ? 'Marcar Ingreso'
                            : _responseData?['message'] == 'Patente sin ingreso'
                                ? 'Marcar Ingreso'
                                : 'Marcar Salida',
                        color: Colors.blue,
                        icon: Icons.car_crash,
                        descriptionLines: !_isIngresoSalidaEnabled
                            ? ['', '', '']
                            : _responseData?['message'] == 'Patente sin ingreso'
                                ? [
                                    'Ingreso: ${DateFormat('HH:mm').format(DateTime.now())}',
                                    '',
                                    ''
                                  ]
                                : [
                                    'Ubicación: ${_responseData?['Ubicación']}',
                                    'Ingreso: ${_responseData?['Hora Ingreso'] ?? DateFormat('HH:mm').format(DateTime.now())}',
                                    'Monto: \$${_calcularMontoSalida()}',
                                  ],
                        buttonHeight: 180,
                        isEnabled: _isIngresoSalidaEnabled,
                        onPressed: () async {
                          if (_responseData?['message'] ==
                              'Patente sin ingreso') {
                            await marcarIngreso();
                          } else {
                            await marcarSalida();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildActionButton(
                        label: 'Pago Anticipado',
                        color: Colors.green,
                        icon: Icons.payment,
                        descriptionLines: _isPagoAnticipadoEnabled
                            ? [
                                '',
                                'Monto: \$${_calcularMontoPagoAnticipado()}',
                                '',
                              ]
                            : ['', '', ''],
                        buttonHeight: 180,
                        isEnabled: _isPagoAnticipadoEnabled,
                        onPressed: () async {
                          await marcarPagoAnticipado();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildActionButton(
                        label: 'Pagar Deudas',
                        color: Colors.red,
                        icon: Icons.warning,
                        descriptionLines: _isDeudaEnabled
                            ? [
                                'Dudas: ${_responseData?['cantidad_deudas']}',
                                'Monto: \$${NumberFormat('#,##0').format(_responseData?['monto_total_deudas'] ?? 0)}',
                                '',
                              ]
                            : ['', '', ''],
                        buttonHeight: 180,
                        isEnabled: _isDeudaEnabled,
                        onPressed: () async {
                          await pagarDeudas();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildActionButton(
                        label: 'Beneficio',
                        color: Colors.orange,
                        icon: Icons.star,
                        descriptionLines: _isBeneficioEnabled
                            ? [
                                'Ingreso: ${DateFormat('HH:mm').format(DateTime.now())}',
                                '',
                                '',
                              ]
                            : ['', '', ''],
                        buttonHeight: 180,
                        isEnabled: _isBeneficioEnabled,
                        onPressed: () async {
                          await aplicarBeneficio();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
