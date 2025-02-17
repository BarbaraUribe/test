import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_app_state.dart';

class MiCuentaPage extends StatelessWidget {
  const MiCuentaPage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Header con degradado modificado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 32.0, horizontal: 24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, // Cambiado a topCenter
                    end: Alignment.bottomCenter, // Cambiado a bottomCenter
                    colors: [
                      const Color(0xFF244ba6),
                      const Color(0xFF244ba6).withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.rut ?? 'No disponible',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Operador',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Resto del contenido...
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoCard(context, appState),
                    const SizedBox(height: 16),
                    _buildOptionsCard(context, appState),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, MyAppState appState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Reducido de 20 a 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF244ba6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF244ba6),
                    size: 20, // Reducido el tamaño del ícono
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Información del Usuario',
                  style: TextStyle(
                    fontSize: 18, // Reducido de 20 a 18
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Reducido de 20 a 16
            _buildInfoTile(
              icon: Icons.business,
              title: 'ID Empresa',
              value: appState.idEmpresa?.toString() ?? 'No disponible',
            ),
            _buildInfoTile(
              icon: Icons.location_on,
              title: 'Zona Asignada',
              value: appState.idZona?.toString() ?? 'No disponible',
            ),
            _buildInfoTile(
              icon: Icons.place,
              title: 'Ubicación',
              value: appState.idUbicacion?.toString() ?? 'No disponible',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Reducido de 8 a 6
      child: Container(
        padding: const EdgeInsets.all(12), // Reducido de 16 a 12
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reducido de 8 a 6
              decoration: BoxDecoration(
                color: const Color(0xFF244ba6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // Reducido de 8 a 6
              ),
              child: Icon(icon,
                  color: const Color(0xFF244ba6),
                  size: 18), // Reducido de 20 a 18
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13, // Reducido de 14 a 13
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2), // Reducido de 4 a 2
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15, // Reducido de 16 a 15
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard(BuildContext context, MyAppState appState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.password,
            title: 'Cambiar Contraseña',
            onTap: () => _showChangePasswordDialog(context),
            color: const Color(0xFF244ba6),
          ),
          _buildOptionTile(
            icon: Icons.security,
            title: 'Configuración de Seguridad',
            onTap: () => _showNotImplementedSnackbar(
                context, 'Configuración de Seguridad'),
            color: const Color(0xFF244ba6),
          ),
          _buildOptionTile(
            icon: Icons.help_outline,
            title: 'Ayuda y Soporte',
            onTap: () =>
                _showNotImplementedSnackbar(context, 'Ayuda y Soporte'),
            color: const Color(0xFF244ba6),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cambiar Contraseña',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF244ba6),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(
              controller: currentPasswordController,
              label: 'Contraseña Actual',
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: newPasswordController,
              label: 'Nueva Contraseña',
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: confirmPasswordController,
              label: 'Confirmar Nueva Contraseña',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showNotImplementedSnackbar(context, 'Cambio de Contraseña');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF244ba6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
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
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, MyAppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF244ba6),
          ),
        ),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              appState.setLoggedIn(false);
              appState.updateIndex(0);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showNotImplementedSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature será implementado próximamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF244ba6),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }
}
