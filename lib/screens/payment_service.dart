import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class PaymentService {
  static const MethodChannel _channel = MethodChannel('payment_channel');

  // Constantes
  static const String DEV_PACKAGE = 'com.haulmer.paymentapp.dev';
  static const String PROD_PACKAGE = 'com.haulmer.paymentapp';

  static Future<Map<String, dynamic>> sendPayment({
    required int amount,
    required String device,
    required String description,
    required String patente,
    required String tiempo,
  }) async {
    try {
      // Formatear el monto para mostrar
      final formattedAmount = NumberFormat.currency(
        locale: 'es_CL',
        symbol: '\$',
        decimalDigits: 0,
      ).format(amount);

      print('Iniciando transacción de pago:');
      print('- Monto: $formattedAmount');
      print('- Dispositivo: $device');
      print('- Descripción: $description');
      print('- Patente: $patente');
      print('- Tiempo: $tiempo minutos');

      final Map<String, dynamic> paymentData = {
        'amount': amount,
        'device': device,
        'description': description,
        'patente': patente,
        'tiempo': tiempo,
      };

      // Invocar el método nativo
      final String? result =
          await _channel.invokeMethod('processPayment', paymentData);

      if (result == null) {
        print('Error: No se recibió respuesta del pago');
        return {
          'status': 'error',
          'message': 'No se recibió respuesta del pago',
          'code': 'NO_RESPONSE'
        };
      }

      // Procesar la respuesta
      final Map<String, dynamic> response = json.decode(result);
      print('Respuesta del pago recibida: $response');

      if (response['errorCode'] != null) {
        print('Error en el pago: ${response['errorMessage']}');
        return {
          'status': 'error',
          'message': response['errorMessage'] ?? 'Error desconocido',
          'code': response['errorCode']
        };
      }

      print('Pago procesado exitosamente');
      return {'status': 'success', 'data': response};
    } on PlatformException catch (e) {
      print('Error de plataforma: ${e.message}');
      return {
        'status': 'error',
        'message': e.message ?? 'Error desconocido',
        'code': e.code
      };
    } catch (e) {
      print('Error inesperado: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'code': 'UNKNOWN_ERROR'
      };
    }
  }

  // Método para verificar el estado de un pago
  static Future<Map<String, dynamic>> checkPaymentStatus(
      String transactionId) async {
    try {
      final String? result = await _channel
          .invokeMethod('checkPaymentStatus', {'transactionId': transactionId});

      if (result == null) {
        return {
          'status': 'error',
          'message': 'No se pudo obtener el estado del pago',
          'code': 'NO_STATUS'
        };
      }

      return json.decode(result);
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'code': 'CHECK_STATUS_ERROR'
      };
    }
  }

  // Método para validar si la app de pagos está instalada
  static Future<bool> isPaymentAppInstalled() async {
    try {
      final bool? result = await _channel.invokeMethod('checkPaymentApp');
      return result ?? false;
    } catch (e) {
      print('Error al verificar la app de pagos: $e');
      return false;
    }
  }
}
