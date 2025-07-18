class ApiConfig {
    // HTTP API Base URL
    //static const String baseUrl = 'http://192.168.100.77:8000';  // For Physical Device
  // static const String baseUrl = 'http://10.0.2.2:8000';  // For Android emulator
     static const String baseUrl = 'http://127.0.0.1:8000';  // For iOS simulator or web
    
    // WebSocket Base URL
   //static const String wsBaseUrl = 'ws://192.168.100.77:8000';  // For Physical Device
  //static const String wsBaseUrl = 'ws://10.0.2.2:8000';  // For Android emulator 
  static const String wsBaseUrl = 'ws://127.0.0.1:8000';  // For iOS simulator or web
} 