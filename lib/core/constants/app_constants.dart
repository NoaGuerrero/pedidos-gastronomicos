class AppConstants {
  // App Info
  static const String appName = 'Pedidos Gastronómicos';
  static const String appVersion = '1.0.0';

  // Roles de usuario
  static const String rolNegocio = 'negocio';
  static const String rolCliente = 'cliente';

  // Estados de pedidos
  static const String estadoPendiente = 'pendiente';
  static const String estadoEnPreparacion = 'en_preparacion';
  static const String estadoListo = 'listo';
  static const String estadoEntregado = 'entregado';
  static const String estadoCancelado = 'cancelado';

  // Validaciones
  static const int minPasswordLength = 6;
  static const int maxImageSizeMB = 5;

  // Formateo
  static const String currencySymbol = 'Bs';
  static const String dateFormat = 'dd/MM/yyyy HH:mm';
}