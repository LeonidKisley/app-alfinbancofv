import 'package:flutter/material.dart';
import 'package:alfinbancoventaapp/features/auth/loginscreen.dart'; 

// Importante mantener la consistencia con los colores del login
class AlfinColors {
  static const Color purpura = Color(0xFF8B2BB3);
  static const Color naranjaFuerte = Color.fromARGB(255, 245, 75, 2);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Retardo para mostrar el branding antes de cargar la pantalla de login
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Animación fade personalizada para suavizar la entrada al login
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tamanoPantalla = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AlfinColors.naranjaFuerte, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Carga del logo oficial con fallback por si hay problemas de rutas
            Image.asset(
              'assets/images/alfinbancologo.png',
              width: tamanoPantalla.width * 0.7,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "nuestro banco",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 18, 
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            
            // Loader básico para indicar que el sistema está respondiendo
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}