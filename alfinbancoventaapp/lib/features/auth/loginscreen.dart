import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alfinbancoventaapp/features/dashboard/admindashboardscreen.dart'; 

// Usamos la paleta centralizada para no repetir variables de color
class AlfinColors {
  static const Color purpura = Color(0xFF8B2BB3);
  static const Color naranja = Color(0xFFFF4E00);
  static const Color naranjaFuerte = Color.fromARGB(255, 245, 75, 2);
  static const Color fondo = Color(0xFFF4F6F9);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _recordarUsuario = false;

  void _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Si ingresan DNI puro, autocompletamos el dominio institucional para Supabase Auth
      final identificador = _usuarioController.text.trim();
      final correoFinal = identificador.contains('@') 
          ? identificador 
          : "$identificador@alfinbanco.com";

      final response = await supabase.auth.signInWithPassword(
        email: correoFinal,
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        String nombreCompleto = "Administrador"; 
        String rolAsignado = "Asesor de Negocios Principal";

        try {
          // Cruce de ID para jalar datos extras del empleado
          final perfil = await supabase
              .from('perfiles_clientes') 
              .select('nombres, apellidos')
              .eq('user_id', response.user!.id)
              .maybeSingle(); 

          if (perfil != null) {
            nombreCompleto = "${perfil['nombres']} ${perfil['apellidos']}";
          }
        } catch (e) {
          debugPrint("El UID no registra metadatos en la tabla perfiles_clientes: $e");
        }

        if (!mounted) return;
        setState(() { _isLoading = false; });

        // Limpieza de stack al saltar al home principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(
              adminNombre: nombreCompleto,
              rol: rolAsignado,
            ),
          ),
        );
      }
    } on AuthException catch (error) {
      setState(() { _isLoading = false; });
      _mostrarAlerta(error.message);
    } catch (error) {
      setState(() { _isLoading = false; });
      _mostrarAlerta('Error interno: $error');
    }
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlfinColors.fondo,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Cierra teclado al tocar fuera
        child: SafeArea(
          top: false, 
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildLoginForm(),
                        const SizedBox(height: 40),
                        _buildOpcionesCorporativas(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Banner superior con la identidad del banco
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 80, bottom: 35),
      decoration: const BoxDecoration(
        color: AlfinColors.naranjaFuerte,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/alfinbancologo.png',
            height: 200, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                "alfin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 65,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            "nuestro banco",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Estructura interna de los campos de texto
  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "INGRESO ADMINISTRATIVO",
              style: TextStyle(color: AlfinColors.purpura, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
            ),
            const SizedBox(height: 15),
            const Text(
              "Registro / DNI",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            TextFormField(
              controller: _usuarioController,
              keyboardType: TextInputType.number, 
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
                LengthLimitingTextInputFormatter(8), 
              ],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: "Número de DNI",
                hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: Colors.black45),
                border: UnderlineInputBorder(),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AlfinColors.naranja, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Ingrese su DNI";
                if (value.trim().length != 8) return "El DNI debe tener exactamente 8 dígitos";
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Contraseña",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Tu clave de acceso",
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
                prefixIcon: const Icon(Icons.lock_open_outlined, color: Colors.black45),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const UnderlineInputBorder(),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AlfinColors.naranja, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Ingrese su contraseña";
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _recordarUsuario,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.orange,
                    inactiveTrackColor: Colors.grey[300],
                    onChanged: (value) => setState(() => _recordarUsuario = value),
                  ),
                ),
                Text(
                  "Recordar terminal", 
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlfinColors.purpura,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("INGRESAR AL SISTEMA", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Accesos rápidos de la parte baja
  Widget _buildOpcionesCorporativas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMenuInferior(Icons.support_agent_rounded, "Soporte TI", () {
          // Pendiente enlazar número o canal de soporte
        }),
        _buildMenuInferior(Icons.cloud_done_outlined, "Estado Red", () {
          // Monitor de latencia del servidor
        }),
        _buildMenuInferior(Icons.token_outlined, "Token Corp", () {
          // Generador OTP alternativo
        }),
      ],
    );
  }

  Widget _buildMenuInferior(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AlfinColors.purpura.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AlfinColors.purpura, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: AlfinColors.purpura, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}