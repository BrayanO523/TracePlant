import 'package:firebase_core/firebase_core.dart';
import 'package:productoraempacadora/firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Segunda instancia para crear empleados sin cerrar la sesión del dueño
    try {
      Firebase.app('employeeCreator');
    } catch (_) {
      await Firebase.initializeApp(
        name: 'employeeCreator',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}
