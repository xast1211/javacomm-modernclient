class ApiConstants {
  static const String scheme = 'https'; 
  static const String domain = 'chat4j.de'; 
  
  // Base Contexts
  static const String jaxrsContextPath = 'restful/jaxrs';
  static const String serverContextPath = 'javacommserver';
  
  static String get restBaseUrl => '$scheme://$domain/$serverContextPath';
  
  // WebSocket
  static const String wsContextPath = 'javacommserver/portal';
  
  // Endpoints using serverContextPath (javacommserver)
  static const String readToken = '/user/read/token';
  static const String readRsa = '/rsa/public/key'; 
  static const String writeLanguage = '/user/write/language';
  static const String writeKeepAlive = '/user/write/keepalive';
  static const String writeTheme = '/user/write/eis';
  static const String readUserData = '/user/read/data'; 
  
  // Endpoints using jaxrsContextPath (restful/jaxrs) if any needed later
  // static const String domains = '/domains';

  // Timeouts
  static const Duration loginTimeout = Duration(seconds: 10);
  static const Duration updateProfileTimeout = Duration(seconds: 5);
}
