import 'package:flutter/material.dart';

class ClientesControlScreen extends StatefulWidget {
  const ClientesControlScreen({super.key});

  @override
  State<ClientesControlScreen> createState() => _ClientesControlScreenState();
}

class _ClientesControlScreenState extends State<ClientesControlScreen> {
  // Lista simulada de clientes globales administrados por la agencia
  final List<Map<String, dynamic>> _clientes = [
    {
      'nombre': 'María Choquehuanca',
      'dni': '45678912',
      'negocio': 'Bodega "Mi Paquita"',
      'estadoCredito': 'En Evaluación',
      'montoSolicitado': 5000.00,
      // APARTADO DE SCORING
      'scoreFico': 710, 
      'scoreColor': Colors.green,
      'riesgo': 'Bajo',
      'comportamiento': 'Excelente (100% puntual)',
      'capacidadPago': 'S/ 1,800 disp.',
    },
    {
      'nombre': 'Juan Pérez Ramos',
      'dni': '09876543',
      'negocio': 'Calzados El Sol',
      'estadoCredito': 'Pre-aprobado',
      'montoSolicitado': 8000.00,
      // APARTADO DE SCORING
      'scoreFico': 640,
      'scoreColor': Colors.orange,
      'riesgo': 'Medio',
      'comportamiento': 'Regular (Atrasos leves en SBS)',
      'capacidadPago': 'S/ 2,200 disp.',
    },
    {
      'nombre': 'Ricardo Gareca Ludeña',
      'dni': '12345678',
      'negocio': 'Restobar El Gol',
      'estadoCredito': 'Rechazado',
      'montoSolicitado': 15000.00,
      // APARTADO DE SCORING
      'scoreFico': 420,
      'scoreColor': Colors.redAccent,
      'riesgo': 'Alto',
      'comportamiento': 'Crítico (Deuda Coactiva Sunat)',
      'capacidadPago': 'S/ 0 (Sobreendeudado)',
    },
  ];

  Map<String, dynamic>? _clienteSeleccionado;

  @override
  Widget build(BuildContext context) {
    const Color purpuraAlfin = Color(0xFF8B2BB3);
    const Color naranjaAlfin = Color(0xFFF15A24);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Control Global de Clientes",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: purpuraAlfin,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador por DNI o Nombre
            TextField(
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: "Buscar por DNI o Nombre del cliente...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contenido Principal condicional
            Expanded(
              child: _clienteSeleccionado == null 
                  ? _buildListaClientes(purpuraAlfin)
                  : _buildDetalleYScoringCliente(purpuraAlfin, naranjaAlfin),
            ),
          ],
        ),
      ),
    );
  }

  // Vista 1: Listado de Clientes de la Agencia
  Widget _buildListaClientes(Color purpuraAlfin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Clientes Registrados en la Agencia",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _clientes.length,
            itemBuilder: (context, index) {
              final client = _clientes[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF5EEF9),
                    child: Icon(Icons.person_outline, color: Color(0xFF8B2BB3)),
                  ),
                  title: Text(client['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("DNI: ${client['dni']} • ${client['negocio']}"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      _clienteSeleccionado = client;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Vista 2: Ficha del cliente enfocado con el APARTADO DE SCORING CENTRAL
  Widget _buildDetalleYScoringCliente(Color purpura, Color naranja) {
    final client = _clienteSeleccionado!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón para regresar a la lista de clientes
          TextButton.icon(
            onPressed: () => setState(() => _clienteSeleccionado = null),
            icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
            label: const Text("Volver al listado", style: TextStyle(color: Colors.grey)),
          ),
          
          // Cabecera del Cliente (Corregido el error de border y padding interno)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: purpura.withOpacity(0.1),
                    child: Icon(Icons.storefront_outlined, color: purpura, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client['nombre'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("DNI: ${client['dni']} | Solicitud: S/ ${client['montoSolicitado'].toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text("Estado: ${client['estadoCredito']}", style: TextStyle(color: naranja, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ================= SECCIÓN CRÍTICA: APARTADO DE SCORING =================
          const Text(
            "Análisis de Scoring Integrado",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila Score Principal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Puntaje FICO Interno:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: client['scoreColor'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.analytics_rounded, color: client['scoreColor'], size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "${client['scoreFico']} Pts",
                              style: TextStyle(color: client['scoreColor'], fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),

                  // Variable 1: Nivel de Riesgo
                  _buildScoringRow(
                    label: "Nivel de Riesgo Calificado",
                    value: client['riesgo'].toUpperCase(),
                    valueColor: client['scoreColor'],
                    icon: Icons.shield_outlined
                  ),
                  const SizedBox(height: 12),

                  // Variable 2: Comportamiento de Pago
                  _buildScoringRow(
                    label: "Historial Crediticio",
                    value: client['comportamiento'],
                    valueColor: Colors.black87,
                    icon: Icons.history_toggle_off_rounded
                  ),
                  const SizedBox(height: 12),

                  // Variable 3: Capacidad de Pago
                  _buildScoringRow(
                    label: "Capacidad de Pago Calculada",
                    value: client['capacidadPago'],
                    valueColor: purpura,
                    icon: Icons.monetization_on_outlined
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botón de Acción Administrativa rápida
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Flujo para forzar re-evaluación o recalcular Scoring
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: purpura,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0
              ),
              child: const Text("FORZAR RE-CALCULO DE SCORING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // Componente de fila estilizada para las variables del scoring
  Widget _buildScoringRow({required String label, required String value, required Color valueColor, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
            ],
          ),
        ),
      ],
    );
  }
}