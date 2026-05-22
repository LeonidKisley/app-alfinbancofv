import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alfinbancoventaapp/features/cartera/presentacion/screens/fichaevaluacionscreen.dart';

class ListaCarteraScreen extends StatefulWidget {
  const ListaCarteraScreen({Key? key}) : super(key: key);

  @override
  State<ListaCarteraScreen> createState() => _ListaCarteraScreenState();
}

class _ListaCarteraScreenState extends State<ListaCarteraScreen> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _clientesPreaprobados = [];
  List<Map<String, dynamic>> _clientesFiltrados = [];

  String _filtroSegmento = 'TODOS';
  String _filtroEstado = 'TODOS';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarListaPreaprobados();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarListaPreaprobados() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _supabase
          .from('creditos_preaprobados')
          .select('''
            id,
            monto_aprobado,
            estado_pago,
            segmento,
            score_transaccional,
            perfiles_clientes (
              dni,
              nombres,
              apellidos,
              distrito,
              provincia,
              departamento,
              nombre_negocio,
              direccion_negocio,
              telefono
            )
          ''');

      final data = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
            // !!! AGREGA ESTA LÍNEA AQUÍ !!!
          print("🚨 RESPUESTA DE BASE DE DATOS EN ESTE SEGUNDO: $data");

          
      if (mounted) {
        setState(() {
          _clientesPreaprobados = data;
          
          _clientesPreaprobados.sort((a, b) {
            final scoreA = a['score_transaccional'] ?? 0;
            final scoreB = b['score_transaccional'] ?? 0;
            return scoreB.compareTo(scoreA);
          });
          
          _aplicarFiltros();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR REAL DE SUPABASE: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _clientesFiltrados = _clientesPreaprobados.where((item) {
        final cliente = item['perfiles_clientes'] ?? {};
        
        final String nombresReal = (cliente['nombres'] ?? '').toString().toLowerCase();
        final String apellidosReal = (cliente['apellidos'] ?? '').toString().toLowerCase();
        final String dniReal = (cliente['dni'] ?? '').toString().toLowerCase(); 
        final String query = _searchQuery.toLowerCase().trim();
        
        final bool matchSearch = query.isEmpty || 
            nombresReal.contains(query) || 
            apellidosReal.contains(query) ||
            dniReal.contains(query);

        final String segmentoReal = (item['segmento'] ?? 'BASICO').toString().toUpperCase().trim();
        final String filtroSegTarget = _filtroSegmento.toUpperCase().trim();
        final bool matchSegmento = filtroSegTarget == 'TODOS' || segmentoReal == filtroSegTarget;
            
        bool matchEstado = false;
        if (_filtroEstado == 'TODOS') {
          matchEstado = true;
        } else {
          final String estadoReal = (item['estado_pago'] ?? '').toString().toLowerCase().trim();
          if (_filtroEstado == 'PENDIENTE') {
            matchEstado = estadoReal.contains('dia') || estadoReal.contains('al_dia') || estadoReal.isEmpty; 
          } else if (_filtroEstado == 'EVALUADO') {
            matchEstado = estadoReal.contains('atraso');
          }
        }

        return matchSearch && matchSegmento && matchEstado;
      }).toList();
    });
  }

  Color _obtenerColorSegmento(String? segmento) {
    switch (segmento?.toUpperCase().trim()) {
      case 'PREMIER': return const Color(0xFF1B5E20); 
      case 'ESTANDAR': return const Color(0xFF0D47A1); 
      case 'BASICO': return const Color(0xFFE65100); 
      default: return const Color(0xFF455A64);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color purpuraAlfin = Color(0xFF8B2BB3);
    const Color naranjaAlfin = Color(0xFFF15A24);
    const Color purpuraOscuroAlfin = Color(0xFF250A3A); 

    return Scaffold(
      backgroundColor: purpuraOscuroAlfin,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o DNI...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _aplicarFiltros();
                },
              )
            : const Text(
                'Mi Cartera Diaria',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
        backgroundColor: purpuraAlfin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                  _aplicarFiltros();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarListaPreaprobados,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPanelFiltrosInteractivos(purpuraAlfin, purpuraOscuroAlfin),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                    ? _buildErrorView(purpuraAlfin)
                    : _clientesFiltrados.isEmpty
                        ? _buildEmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _clientesFiltrados.length,
                            itemBuilder: (context, index) {
                              final item = _clientesFiltrados[index];
                              
                              // Retornamos la tarjeta DIRECTAMENTE sin envolverla en el Shimmer Premier
                              // para obligar a Flutter a pintar los datos reales de Henry y Sonia
                              return _buildClienteCardPremium(context, item, purpuraAlfin, naranjaAlfin);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelFiltrosInteractivos(Color primaryColor, Color fondoOscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 16),
      decoration: BoxDecoration(
        color: fondoOscuro,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Segmento Comercial", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['TODOS', 'PREMIER', 'ESTANDAR', 'BASICO'].map((seg) {
                final isSelected = _filtroSegmento == seg;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(seg == 'TODOS' ? 'Todos' : seg),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : primaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _filtroSegmento = seg;
                        _aplicarFiltros();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Text("Estado de la Gestión", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: ['TODOS', 'PENDIENTE', 'EVALUADO'].map((est) {
              final isSelected = _filtroEstado == est;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(est == 'TODOS' ? 'Todos' : est == 'PENDIENTE' ? 'Vigentes' : 'Con Atraso'),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _filtroEstado = est;
                      _aplicarFiltros();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCardPremium(BuildContext context, Map<String, dynamic> item, Color primary, Color secondary) {
    final cliente = item['perfiles_clientes'] ?? {};
    final String nombres = cliente['nombres'] ?? 'Cliente sin Nombre';
    final String apellidos = cliente['apellidos'] ?? '';
    final String negocio = cliente['nombre_negocio'] ?? 'Giro Comercial';
    
    final String direccionNegocio = (cliente['direccion_negocio'] ?? '').toString().trim();
    
    // =======================================================================
    // EXTRACCIÓN DIRECTA DESDE LA TABLA 'perfiles_clientes' SIN FILTROS EXTRA
    // =======================================================================
    final String distritoDeBaseDatos = (cliente['distrito'] ?? '').toString().trim();
    
    final String textoDistritoReal = distritoDeBaseDatos.isNotEmpty ? distritoDeBaseDatos : 'S/D';
    
    // CORRECCIÓN AQUÍ: Se eliminó la variable inexistente 'direccionLinter' para usar el String correcto
    final String textoDireccionAmarillo = direccionNegocio.isNotEmpty ? direccionNegocio : 'Sin dirección';

    final double monto = (item['monto_aprobado'] ?? 0.0).toDouble();
    final int score = item['score_transaccional'] ?? 0;
    final String segmento = (item['segmento'] ?? 'BASICO').toString().toUpperCase().trim();
    
    final String estadoPago = (item['estado_pago'] ?? 'al_dia').toString().toLowerCase().trim();
    final bool isAlDia = estadoPago.contains('dia') || estadoPago.contains('al_dia');

    final colorSegmento = _obtenerColorSegmento(segmento);

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final refrescar = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FichaEvaluacionScreen(creditoPreaprobado: item),
            ),
          );
          if (refrescar == true) {
            _cargarListaPreaprobados();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Superior: Segmento y Estado de Pago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorSegmento.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: colorSegmento.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      segmento,
                      style: TextStyle(color: colorSegmento, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAlDia ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAlDia ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                          size: 14,
                          color: isAlDia ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAlDia ? 'Al Día' : 'Con Atraso',
                          style: TextStyle(
                            color: isAlDia ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // Nombre del Cliente
              Text(
                "$nombres $apellidos",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF212121), letterSpacing: -0.2),
              ),
              const SizedBox(height: 10),
              
              // Fila de Giro Comercial (Negocio)
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 15, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      negocio, 
                      style: const TextStyle(color: Colors.black54, fontSize: 13), 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fila de Ubicación: Dirección + Caja de Distrito Único
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Colors.black45),
                  const SizedBox(width: 6),
                  
                  // Dirección exacta
                  Expanded(
                    flex: 2,
                    child: Text(
                      textoDireccionAmarillo, 
                      style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // CONTENEDOR DE DISTRITO EXTRAÍDO DIRECTAMENTE DE LA COLUMNA DE LA BASE DE DATOS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primary.withOpacity(0.25), width: 1),
                    ),
                    child: Text(
                      textoDistritoReal.toUpperCase(),
                      style: TextStyle(
                        color: primary, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF1F3F5)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Monto Preaprobado", style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(
                        "S/ ${monto.toStringAsFixed(2)}",
                        style: TextStyle(color: secondary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Score de Riesgo", style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.insights_rounded, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 5),
                          Text(
                            "$score pts",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Error al sincronizar cartera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar Sincronización', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _cargarListaPreaprobados,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_rounded, size: 56, color: Colors.white38),
          const SizedBox(height: 12),
          const Text('Cartera vacía para este filtro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class EfectoShimmerPremier extends StatefulWidget {
  final Widget child;
  const EfectoShimmerPremier({Key? key, required this.child}) : super(key: key);

  @override
  State<EfectoShimmerPremier> createState() => _EfectoShimmerPremierState();
}

class _EfectoShimmerPremierState extends State<EfectoShimmerPremier> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, 
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18), 
                  child: FractionalTranslation(
                    translation: Offset(_controller.value * 3 - 1.5, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.35), 
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.35, 0.5, 0.65],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}