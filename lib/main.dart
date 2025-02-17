import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/my_app_state.dart';
import 'screens/login_page.dart';
import 'screens/ingresar_auto.dart';
import 'screens/inspecciones_login.dart';
import 'screens/mi_cuenta.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// Constantes de la aplicación
class AppConstants {
  static const String appName = 'RedParking';
  static const Color primaryColor = Color(0xFF244ba6);
  static const String appLogo =
      'assets/Logotipo-Red-Parking-Blanco-Puro-PNG-RGB.png';
}

// Agregar esta clase para manejar la información del cierre
class DailySummary {
  final String operator;
  final String location;
  final double cash;
  final double card;
  final double collectedDebt;
  final double goal;

  DailySummary({
    required this.operator,
    required this.location,
    required this.cash,
    required this.card,
    required this.collectedDebt,
    required this.goal,
  });

  double get totalSales => cash + card + collectedDebt;
  double get difference => totalSales - goal;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MyHomePage(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

void _verifyCloseDayCode(BuildContext context, MyAppState appState) {
  final codeController = TextEditingController();
  bool isError = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Verificación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingrese el código de autorización para cerrar el día',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onSubmitted: (value) {
                    if (value == '1234') {
                      Navigator.pop(context);
                      _showFinalCloseDayDialog(context, appState);
                    } else {
                      setState(() {
                        isError = true;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Código',
                    errorText: isError ? 'Código incorrecto' : null,
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (codeController.text == '1234') {
                    Navigator.pop(context);
                    _showFinalCloseDayDialog(context, appState);
                  } else {
                    setState(() {
                      isError = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Verificar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showFinalCloseDayDialog(BuildContext context, MyAppState appState) {
  final summary = DailySummary(
    operator: "Juan Pérez",
    location: "Calle Valparaíso",
    cash: 250000.0,
    card: 180000.0,
    collectedDebt: 50000.0,
    goal: 480000.0,
  );

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.point_of_sale,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Resumen de Cierre',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información General
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Fecha',
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.badge,
                      'Operador asignado',
                      summary.operator,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.location_on,
                      'Ubicación',
                      summary.location,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Información Financiera
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountRow(
                      context,
                      Icons.money,
                      'Efectivo',
                      summary.cash,
                      Colors.black,
                    ),
                    SizedBox(height: 12),
                    _buildAmountRow(
                      context,
                      Icons.credit_card,
                      'Tarjeta',
                      summary.card,
                      Colors.black,
                    ),
                    SizedBox(height: 12),
                    _buildAmountRow(
                      context,
                      Icons.account_balance_wallet,
                      'Deuda recaudada',
                      summary.collectedDebt,
                      Colors.black,
                    ),
                    Divider(height: 24),
                    _buildTotalSalesRow(context, summary),
                    SizedBox(height: 12),
                    _buildAmountRow(
                      context,
                      Icons.flag,
                      'Meta',
                      summary.goal,
                      Colors.grey.shade700,
                    ),
                    SizedBox(height: 12),
                    _buildDifferenceRow(context, summary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            icon: Icon(Icons.check_circle, size: 20, color: Colors.white),
            label: Text(
              'Siguiente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              appState.setLoggedIn(false); // Cierra la sesión
              appState.updateIndex(0); // Actualiza el índice
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatCurrency(double amount) {
  return NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  ).format(amount);
}

Widget _buildInfoRow(
    BuildContext context, IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, color: Theme.of(context).primaryColor, size: 18),
      SizedBox(width: 8),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildAmountRow(BuildContext context, IconData icon, String label,
    double amount, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      Text(
        _formatCurrency(amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

Widget _buildTotalSalesRow(BuildContext context, DailySummary summary) {
  Color totalColor = summary.totalSales > summary.goal
      ? Colors.green
      : summary.totalSales < summary.goal
          ? Colors.red
          : Colors.orange;

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: totalColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_cart, color: totalColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Total Ventas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: totalColor,
              ),
            ),
          ],
        ),
        Text(
          _formatCurrency(summary.totalSales),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: totalColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDifferenceRow(BuildContext context, DailySummary summary) {
  Color differenceColor = summary.difference >= 0 ? Colors.green : Colors.red;
  String prefix = summary.difference >= 0 ? '+' : '';

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: differenceColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              summary.difference >= 0 ? Icons.trending_up : Icons.trending_down,
              color: differenceColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Diferencia',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: differenceColor,
              ),
            ),
          ],
        ),
        Text(
          prefix + _formatCurrency(summary.difference.abs()),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: differenceColor,
          ),
        ),
      ],
    ),
  );
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, appState, child) {
        return ScaffoldWrapper(
          appState: appState,
          child: _buildContent(appState),
        );
      },
    );
  }

  Widget _buildContent(MyAppState appState) {
    if (!appState.isLoggedIn) {
      return const LoginPage();
    }

    switch (appState.selectedIndex) {
      case 0:
        return IngresoAutoPage();
      case 1:
        return InspeccionesLoginPage();
      case 2:
        return MiCuentaPage();
      default:
        return const Center(child: Text('Sección no encontrada'));
    }
  }
}

class ScaffoldWrapper extends StatelessWidget {
  final MyAppState appState;
  final Widget child;

  const ScaffoldWrapper({
    super.key,
    required this.appState,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: child,
      bottomNavigationBar:
          appState.isLoggedIn ? _buildBottomNav(context) : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Image.asset(
        'assets/Logotipo-Red-Parking-Blanco-PNG-RGB.png',
        height: 40, // Ajusta esta altura según necesites
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: appState.isLoggedIn ? [_buildPopupMenu(context)] : null,
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.account_circle,
        color: Colors.white,
        size: 28, // Icono un poco más grande
      ),
      elevation: 8, // Mayor elevación para mejor profundidad
      position: PopupMenuPosition.under,
      offset: const Offset(0, 12), // Espacio entre el ícono y el menú
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200), // Borde sutil
      ),
      color: Colors.white,
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        // Encabezado del menú (opcional)
        PopupMenuItem<String>(
          enabled: false,
          height: 40,
          child: Text(
            'Menu',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Separador
        PopupMenuItem<String>(
          enabled: false,
          height: 1,
          child: Divider(color: Colors.grey.shade200),
        ),
        // Mi Cuenta
        PopupMenuItem<String>(
          value: 'miCuenta',
          child: _buildMenuItem(
            icon: Icons.person_outline,
            label: 'Mi Cuenta',
            iconColor: Colors.blue.shade700,
            backgroundColor: Colors.blue.shade50,
          ),
        ),
        // Cerrar Sesión
        PopupMenuItem<String>(
          value: 'cerrarSesion',
          child: _buildMenuItem(
            icon: Icons.logout_rounded,
            label: 'Cerrar día',
            iconColor: Colors.red.shade700,
            backgroundColor: Colors.red.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'miCuenta':
        appState.updateIndex(2);
        break;
      case 'cerrarSesion':
        _verifyCloseDayCode(context, appState);
        break;
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: appState.selectedIndex,
      onTap: appState.updateIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Ingresar Auto',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Inspecciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Mi Cuenta',
        ),
      ],
    );
  }
}
