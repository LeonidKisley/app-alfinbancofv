import 'package:flutter/material.dart';
import 'package:alfinbancoventaapp/features/dashboard/fuerzaventascontrolscreen.dart';
import 'package:alfinbancoventaapp/features/cartera/presentacion/screens/listacarterascreen.dart';

// Paleta corporativa unificada para la consistencia visual de la plataforma
class AlfinColors {
  static const Color purpura = Color(0xFF8B2BB3);
  static const Color naranja = Color(0xFFFF4E00);
  static const Color naranjaFuerte = Color.fromARGB(255, 245, 75, 2);
  static const Color adminAcento = Colors.teal;
  static const Color fondo = Color(0xFFF4F6F9);
}

class AdminDashboardScreen extends StatefulWidget {
  final String adminNombre;
  final String rol; 

  const AdminDashboardScreen({
    super.key, 
    required this.adminNombre, 
    required this.rol,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _mostrarMetricas = true;

  // Cola de expedientes pendientes de aprobación asíncrona por el comité
  final List<Map<String, dynamic>> _colaComite = [
    {
      'analista': 'Carlos Mendoza (SJL)',
      'cliente': 'María Choquehuanca',
      'negocio': 'Bodega "Mi Paquita"',
      'montoPropuesto': 5000.00,
      'fechaFicha': 'Hoy, 04:30 PM',
      'scoreFinal': 680,
      'colorScore': Colors.orange,
      'estado': 'Espera Comité',
    },
    {
      'analista': 'Karen Vega (Ate)',
      'cliente': 'Juan Pérez Ramos',
      'negocio': 'Calzados El Sol',
      'montoPropuesto': 8000.00,
      'fechaFicha': 'Ayer',
      'scoreFinal': 790,
      'colorScore': Colors.green,
      'estado': 'Espera Comité',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlfinColors.fondo,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMacroBalanceCard(),
              const SizedBox(height: 20),
              _buildSeccionAccionesRapidas(),
              const SizedBox(height: 25),
              _buildMetaAgenciaCard(),
              const SizedBox(height: 25),
              const Text(
                "Resumen de Canales", 
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _buildCanalItem(
                icon: Icons.supervised_user_circle_outlined,
                title: "Asesores Activos hoy",
                subtitle: "8 en campo / 2 en oficina",
                count: "10",
                color: Colors.blue,
              ),
              _buildCanalItem(
                icon: Icons.assignment_turned_in_outlined,
                title: "Fichas de Campo ingresadas",
                subtitle: "Evaluaciones acumuladas esta semana",
                count: "34",
                color: AlfinColors.adminAcento,
              ),
              const SizedBox(height: 25),
              const Text(
                "Pendientes por Resolver (Comité)", 
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _buildListaComite(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Panel: ${widget.adminNombre}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            widget.rol,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: AlfinColors.purpura,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildMacroBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AlfinColors.purpura, AlfinColors.naranjaFuerte],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monto Total Evaluado (Mes)", style: TextStyle(color: Colors.white70, fontSize: 14)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(_mostrarMetricas ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white, size: 22),
                onPressed: () => setState(() => _mostrarMetricas = !_mostrarMetricas),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _mostrarMetricas ? "S/ 345,000.00" : "S/ ••••••", 
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionAccionesRapidas() {
    return Row(
      children: [
        Expanded(
          child: _buildAdminActionButton(
            label: "Control\nClientes",
            icon: Icons.people_alt_outlined,
            color: AlfinColors.naranjaFuerte,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Módulo de Control de Clientes próximamente")),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAdminActionButton(
            label: "Fuerza de\nVentas",
            icon: Icons.badge_outlined,
            color: AlfinColors.purpura,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FuerzaVentasControlScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAdminActionButton(
            label: "Cartera\nDiaria",
            icon: Icons.assignment_outlined,
            color: AlfinColors.adminAcento, 
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListaCarteraScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: color, size: 22), 
            const SizedBox(height: 6), 
            Text(
              label, 
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, height: 1.1),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetaAgenciaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AlfinColors.purpura.withOpacity(0.06), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: AlfinColors.purpura.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AlfinColors.naranjaFuerte, size: 24), 
              const SizedBox(width: 8), 
              Text("Cumplimiento de Meta de Agencia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AlfinColors.purpura)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("La agencia va al 78% del objetivo de colocación mensual.", style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, 
            height: 38, 
            child: ElevatedButton(
              onPressed: () {}, 
              style: ElevatedButton.styleFrom(
                backgroundColor: AlfinColors.naranjaFuerte, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ), 
              child: const Text("VER REPORTE DETALLADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanalItem({required IconData icon, required String title, required String subtitle, required String count, required Color color}) {
    return Card(
      elevation: 0, 
      margin: const EdgeInsets.only(bottom: 12), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
      ),
    );
  }

  Widget _buildListaComite() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _colaComite.length,
      itemBuilder: (context, index) {
        final item = _colaComite[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: item['colorScore'].withOpacity(0.1),
              child: Icon(Icons.gavel_rounded, color: item['colorScore']),
            ),
            title: Text(
              item['cliente'], 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text("${item['negocio']} • ${item['analista']}", style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text("Score Final: ${item['scoreFinal']} pts", style: TextStyle(fontSize: 11, color: item['colorScore'], fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _mostrarMetricas ? "S/ ${item['montoPropuesto'].toStringAsFixed(0)}" : "S/ ••••••",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  item['estado'], 
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            onTap: () {
              // Apertura de flujo para la dictaminación del crédito
            },
          ),
        );
      },
    );
  }
}