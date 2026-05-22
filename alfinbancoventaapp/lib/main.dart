import 'package:flutter/material.dart';
import 'package:alfinbancoventaapp/features/auth/loginscreen.dart';
import 'package:alfinbancoventaapp/features/auth/splashscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alfinbancoventaapp/features/dashboard/fuerzaventascontrolscreen.dart'; 
import 'package:alfinbancoventaapp/features/dashboard/admindashboardscreen.dart';

// Definición global de colores para no duplicar código en las pantallas
class AlfinColors {
  static const Color purpura = Color(0xFF8B2BB3);
  static const Color naranja = Color(0xFFF15A24);
  static const Color fondo = Color(0xFFF8F9FA);
}

void main() async {
  // Asegura que Flutter cargue los componentes nativos antes de levantar Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Conexión inicial con la base de datos de Supabase
  await Supabase.initialize(
    url: 'https://ktzqtgtbpzimlmosksws.supabase.co', 
    anonKey: 'sb_publishable_fP6lXh2URP_aLq5j03PL2Q_SKEr03Hl', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfin Banco Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AlfinColors.purpura,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AlfinColors.purpura,
          primary: AlfinColors.purpura,
          secondary: AlfinColors.naranja,
        ),
        scaffoldBackgroundColor: AlfinColors.fondo,
        fontFamily: 'Roboto',
      ),
      // El flujo inicia directo en el Splash para validar sesión
      home: const SplashScreen(),
    );
  }
}

// Menú temporal para alternar vistas mientras se terminan de enlazar los roles de usuario
class AccesoEcosistemaScreen extends StatelessWidget {
  const AccesoEcosistemaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AlfinColors.purpura, Color(0xFF5A1878)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Contenedor del logo con respaldo por si no carga el asset local
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/alfinbancologo2.jpg',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 75,
                          color: AlfinColors.purpura,
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  "ALFIN BANCO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "Sistema de Control y Fuerza de Ventas",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Text(
                  "SELECCIONAR PERFIL OPERATIVO",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),

                // Botón para ingresar como Administrador / Jefe de Agencia
                _buildRolButton(
                  context: context,
                  label: "Panel de Administración",
                  icon: Icons.shield_outlined,
                  color: AlfinColors.naranja,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(
                        adminNombre: "Roberto Vega",
                        rol: "Jefe de Agencia Principal",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón para ir al mapa de monitoreo de los asesores
                _buildRolButton(
                  context: context,
                  label: "Fuerza de Ventas (Monitoreo)",
                  icon: Icons.badge_outlined,
                  color: Colors.white,
                  textColor: AlfinColors.purpura,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FuerzaVentasControlScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cómponente modular para reutilizar el diseño de los botones de acceso
  Widget _buildRolButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    Color textColor = Colors.white,
    bool isBordered = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isBordered ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(16),
          border: isBordered ? Border.all(color: Colors.white30, width: 1.5) : null,
          boxShadow: !isBordered && color != Colors.white
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}