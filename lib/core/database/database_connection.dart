export 'database_connection_unsupported.dart'
    if (dart.library.js_interop) 'database_connection_web.dart'
    if (dart.library.html) 'database_connection_web.dart'
    if (dart.library.io) 'database_connection_native.dart';
