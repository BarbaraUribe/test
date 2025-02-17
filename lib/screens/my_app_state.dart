import 'package:flutter/material.dart';

class MyAppState with ChangeNotifier {
  bool _isLoggedIn = false;
  int _selectedIndex = 0;
  String? _rut;
  int? _idEmpresa;
  int? _idZona;
  int? _idUbicacion;

  bool get isLoggedIn => _isLoggedIn;
  int get selectedIndex => _selectedIndex;
  String? get rut => _rut; // Getter para obtener el rut
  int? get idEmpresa => _idEmpresa; // Getter para obtener el id_empresa
  int? get idZona => _idZona; // Getter para obtener el id_empresa
  int? get idUbicacion => _idUbicacion; // Getter para obtener el id_empresa

  String? _authToken;
  String? get authToken => _authToken;

  // Setters and getters for the authToken
  void setAuthToken(String token) {
    _authToken = token;
    notifyListeners(); // Notify listeners of changes to the token
  }

  void clearAuthToken() {
    _authToken = null;
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  void updateIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setRut(String? id) {
    _rut = id;
    notifyListeners();
  }

  void setEmpresaId(int? id) {
    _idEmpresa = id;
    notifyListeners();
  }

  void setZonaId(int? id) {
    _idZona = id;
    notifyListeners();
  }

  void setUbicacionId(int? id) {
    _idUbicacion = id;
    notifyListeners();
  }
}
