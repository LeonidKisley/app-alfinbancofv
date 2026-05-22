import 'package:flutter/material.dart';
// Asegúrate de importar la pantalla de control que creamos en el paso anterior
import 'package:alfinbancoventaapp/features/dashboard/fuerzaventascontrolscreen.dart';
// NUEVA IMPORTACIÓN DE LA CARTERA DIARIA
import 'package:alfinbancoventaapp/features/cartera/presentacion/screens/listacarterascreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminNombre;
  final String rol; // Ejemplo: "Jefe de Agencia" o "Administrador Central"

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

  // Lista simulada de alertas críticas o créditos en cola para Comité
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
    // Manteniendo la identidad visual exacta de Alfin Banco
    const Color purpuraAlfin = Color(0xFF8B2BB3);
    const Color naranjaAlfin = Color(0xFFF15A24);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
        backgroundColor: purpuraAlfin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta Superior con Indicadores Macro (mismo diseño que el balance del cliente)
              _buildMacroBalanceCard(purpuraAlfin, naranjaAlfin),
              const SizedBox(height: 20),

              // FILA DE ACCIONES RÁPIDAS PARA EL ADMINISTRADOR (MODIFICADA CON 3 BOTONES)
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: _buildAdminActionButton(
                      context: context,
                      label: "Control\nClientes",
                      icon: Icons.people_alt_outlined,
                      color: naranjaAlfin,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Módulo de Control de Clientes próximamente")),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: _buildAdminActionButton(
                      context: context,
                      label: "Fuerza de\nVentas",
                      icon: Icons.badge_outlined,
                      color: purpuraAlfin,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FuerzaVentasControlScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // NUEVO BOTÓN: MI CARTERA DIARIA DE PREAPROBADOS
                  Flexible(
                    flex: 1,
                    child: _buildAdminActionButton(
                      context: context,
                      label: "Cartera\nDiaria",
                      icon: Icons.assignment_outlined,
                      color: Colors.teal, // Color diferenciado para destacar el nuevo módulo
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ListaCarteraScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // Banner de Campaña Informativa / Metas de Agencia
              _buildMetaAgenciaCard(purpuraAlfin, naranjaAlfin),
              const SizedBox(height: 25),
              
              // Sección de Monitoreo Rápido de Estados
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
                color: Colors.teal,
              ),

              const SizedBox(height: 25),
              
              // Lista de Tareas Críticas del Administrador (Mismo diseño que Últimos Movimientos)
              const Text(
                "Pendientes por Resolver (Comité)", 
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              
              ListView.builder(
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
                        // Abrir detalle para evaluar en Comité de Crédito
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de métricas macro (Equivalente al Balance Card del Cliente)
  Widget _buildMacroBalanceCard(Color primary, Color secondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
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

  // Botón de acción rápida (Modificado para soportar textos largos con tamaño compacto y centrado de contenido)
  Widget _buildAdminActionButton({required BuildContext context, required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
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

  // Banner informativo del estado de la agencia (Equivalente al Campaign Card)
  Widget _buildMetaAgenciaCard(Color primary, Color secondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: secondary, size: 24), 
              const SizedBox(width: 8), 
              const Text("Cumplimiento de Meta de Agencia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF8B2BB3))),
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
                backgroundColor: secondary, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ), 
              child: const Text("VER REPORTE DETALLADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // Ítems de productos/canales (Mismo formato que Mis Productos)
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
}