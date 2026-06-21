class AppConstants {
  // Base URL for the Django/DRF backend.
  static const String baseUrl = 'https://api.bmsapp.com.pk/api';
  //static const String baseUrl = 'http://192.168.50.15:8000/api';

  static const String warehousesEndpoint = '/warehouses';
  static const String addEmployeeEndpoint = '/employees';
  static const String precheckAttendanceEndpoint = '/attendance/precheck';
  static const String markAttendanceEndpoint = '/attendance/mark';
  static const String recordsEndpoint = '/attendance/records';
  static const String dashboardStatsEndpoint = '/hr/stats';
  static const String loginEndpoint = '/auth/login/';

  static const double geofenceRadius = 35.0;
}
