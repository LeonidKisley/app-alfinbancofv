import 'package:flutter/material.dart';
import 'package:alfinbancoventaapp/features/auth/loginscreen.dart'; // Ajusta la ruta a tu login

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    
    // Esperamos 2 segundos y navegamos al Login
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Transición sutil de desvanecimiento (Fade)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 2000),
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
    return Scaffold(
      // Usamos el color naranja principal de Alfin
      backgroundColor: Theme.of(context).primaryColor, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu logo
            Image.asset(
              'assets/alfinbancologo.png',
              width: MediaQuery.of(context).size.width * 0.7,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // El eslogan que mencionaste
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
            // Un indicador de carga discreto blanco
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

