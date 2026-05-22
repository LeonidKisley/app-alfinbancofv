import 'package:flutter/material.dart';
import 'package:alfinbancoventaapp/features/auth/loginscreen.dart';
import 'package:alfinbancoventaapp/features/auth/splashscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alfinbancoventaapp/features/dashboard/fuerzaventascontrolscreen.dart'; 
import 'package:alfinbancoventaapp/features/dashboard/admindashboardscreen.dart';


void main() async {
  // Asegura que los bindings de Flutter estén listos antes de inicializar servicios nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase de forma global
  await Supabase.initialize(
    url: 'https://ktzqtgtbpzimlmosksws.supabase.co', // Reemplaza con tu URL real
    anonKey: 'sb_publishable_fP6lXh2URP_aLq5j03PL2Q_SKEr03Hl',       // Reemplaza con tu llave Anon real
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos la paleta de colores oficial de Alfin Banco
    const Color purpuraAlfin = Color(0xFF8B2BB3);
    const Color naranjaAlfin = Color(0xFFF15A24);

    return MaterialApp(
      title: 'Alfin Banco Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: purpuraAlfin,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purpuraAlfin,
          primary: purpuraAlfin,
          secondary: naranjaAlfin,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      // CAMBIADO: La aplicación arranca de forma segura con el Login de la carpeta auth
      home: const SplashScreen(),
    );
  }
}

/// Pantalla intermedia para seleccionar el perfil operativo dentro de la App de Gestión
/// (Nota: A esta pantalla podrás saltar tras implementar las lógicas o rutas de depuración)
class AccesoEcosistemaScreen extends StatelessWidget {
  const AccesoEcosistemaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color purpuraAlfin = Color(0xFF8B2BB3);
    const Color naranjaAlfin = Color(0xFFF15A24);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [purpuraAlfin, Color(0xFF5A1878)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // CAMBIADO: Se eliminó el Icon genérico y se configuró tu imagen real del logo con un clip circular
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
                        // En caso de que falle por caché, muestra un respaldo dinámico para evitar pantallazos rojos
                        return const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 75,
                          color: purpuraAlfin,
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

                // 1. Botón Modo Administrador Central / Jefe de Agencia
                _buildRolButton(
                  context: context,
                  label: "Panel de Administración",
                  icon: Icons.shield_outlined,
                  color: naranjaAlfin,
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

                // 2. Botón Modo Monitoreo Directo de Asesores
                _buildRolButton(
                  context: context,
                  label: "Fuerza de Ventas (Monitoreo)",
                  icon: Icons.badge_outlined,
                  color: Colors.white,
                  textColor: purpuraAlfin,
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