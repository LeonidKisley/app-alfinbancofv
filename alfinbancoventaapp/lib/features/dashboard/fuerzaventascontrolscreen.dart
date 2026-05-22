import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FuerzaVentasControlScreen extends StatefulWidget {
  const FuerzaVentasControlScreen({super.key});

  @override
  State<FuerzaVentasControlScreen> createState() => _FuerzaVentasControlScreenState();
}

class _FuerzaVentasControlScreenState extends State<FuerzaVentasControlScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _asesoresDB = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchAsesores();
  }

  // Método central para consultar los asesores reales del SEED SQL
  Future<void> _fetchAsesores() async {
    setState(() => _isLoading = true);
    try {
      // Consultamos la tabla cargada vinculándola con su respectiva agencia
      var query = _supabase
          .from('asesores_negocio')
          .select('*, agencias(nombre)');

      // Si hay texto en el buscador, filtramos por nombres o apellidos
      if (_searchQuery.trim().isNotEmpty) {
        query = query.ilike('nombres', '%$_searchQuery%');
      }

      final List<dynamic> response = await query.order('nombres', ascending: true);

      setState(() {
        _asesoresDB = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con Supabase: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color purpuraAlfin = Color(0xFF8B2BB3);
    const Color naranjaAlfin = Color(0xFFF15A24);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Monitoreo de Fuerza de Ventas",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: purpuraAlfin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAsesores,
            tooltip: "Recargar datos",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador Real conectado a la Base de Datos
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Ejecuta la búsqueda en la DB por cada letra escrita
                _fetchAsesores();
              },
              decoration: InputDecoration(
                hintText: "Buscar asesor por nombre...",
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
            const SizedBox(height: 20),

            Text(
              _searchQuery.isEmpty 
                  ? "Equipo Comercial Activo (${_asesoresDB.length} asesores)"
                  : "Resultados de la búsqueda (${_asesoresDB.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Manejo de estados de carga de Supabase
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: purpuraAlfin))
                  : _asesoresDB.isEmpty
                      ? const Center(
                          child: Text(
                            "No se encontraron asesores con ese nombre.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _asesoresDB.length,
                          itemBuilder: (context, index) {
                            final asesor = _asesoresDB[index];

                            // Procesamiento de variables del Seed SQL
                            final String nombreCompleto = "${asesor['nombres']} ${asesor['apellidos']}";
                            final String agenciaNombre = asesor['agencias'] != null ? asesor['agencias']['nombre'] : 'Agencia';
                            final String zona = "${asesor['zona_asignada']} - $agenciaNombre";
                            
                            // Datos numéricos reales del script corporativo
                            final double metaMonto = (asesor['meta_monto_mes'] as num).toDouble();
                            // Simulamos un avance proporcional para fines demostrativos en el dashboard
                            final double avanceMonto = metaMonto * (asesor['nivel'].toString().contains('Senior') ? 0.82 : 0.45);
                            final double porcentaje = avanceMonto / metaMonto;

                            // Definición visual dinámica de estados basados en el nivel
                            String estado = "En Oficina";
                            Color colorEstado = Colors.blue;
                            if (asesor['nivel'] == 'Senior II' || asesor['nivel'] == 'Junior II') {
                              estado = "En Campo";
                              colorEstado = Colors.green;
                            }

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nombreCompleto,
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "$zona (${asesor['nivel']})",
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorEstado.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            estado.toUpperCase(),
                                            style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24, thickness: 0.8),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildAsesorStat(
                                          icon: Icons.assignment_ind_rounded, 
                                          label: "Código / DNI", 
                                          valor: "${asesor['codigo']} / ${asesor['dni']}",
                                          color: purpuraAlfin
                                        ),
                                        _buildAsesorStat(
                                          icon: Icons.trending_up_rounded, 
                                          label: "Meta Mes", 
                                          valor: "S/ ${(metaMonto).toStringAsFixed(0)}",
                                          color: naranjaAlfin
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Barra de progreso vinculada a las metas reales de la base de datos
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value: porcentaje,
                                              backgroundColor: Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                porcentaje >= 1.0 ? Colors.green : purpuraAlfin
                                              ),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "${(porcentaje * 100).toStringAsFixed(0)}%",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsesorStat({required IconData icon, required String label, required String valor, required Color color}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        )
      ],
    );
  }
}