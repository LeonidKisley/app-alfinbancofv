import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 

class FichaEvaluacionScreen extends StatefulWidget {
  final Map<String, dynamic> creditoPreaprobado;

  const FichaEvaluacionScreen({
    Key? key,
    required this.creditoPreaprobado,
  }) : super(key: key);

  @override
  State<FichaEvaluacionScreen> createState() => _FichaEvaluacionScreenState();
}

class _FichaEvaluacionScreenState extends State<FichaEvaluacionScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingMap = true; 

  // --- CONTROLES DE EVALUACIÓN EN CAMPO (F1 a F5) ---
  bool _f1NegocioExiste = true; 
  final _f2VentasDiariasController = TextEditingController(); 
  final _f3DeudasInformalesController = TextEditingController(text: '0'); 
  bool _f4TieneActivos = true; 
  String _f5ReputacionCaracter = 'BUENA'; 
  
  // --- VARIABLES FINANCIERAS ---
  double _montoSugeridoAsesor = 1000.0;
  int _plazoMeses = 6;
  double _cuotaCalculada = 0.0;
  double _montoHipotesisOriginal = 0.0;
  double _ingresoPromedioBase = 3000.0; 
  String _segmentoCliente = 'BASICO';

  // --- VARIABLES DE GEOLOCALIZACIÓN DEL CLIENTE ---
  LatLng _posicionNegocio = const LatLng(-12.046374, -75.047141); // Fallback Huancayo/Lima

  // --- CONTROLADOR DE PESTAÑAS ---
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });

    _montoHipotesisOriginal = (widget.creditoPreaprobado['monto_hipotesis'] ?? 1000.0).toDouble();
    _montoSugeridoAsesor = _montoHipotesisOriginal;
    _segmentoCliente = (widget.creditoPreaprobado['segmento'] ?? 'BASICO').toString().toUpperCase();
    
    if (_segmentoCliente == 'PREMIER') _plazoMeses = 12;
    if (_segmentoCliente == 'ESTANDAR') _plazoMeses = 6;
    if (_segmentoCliente == 'BASICO') _plazoMeses = 3;

    _calcularCuotaFinanciera();
    _cargarCoordenadasDesdeBaseDatos();
  }

  void _cargarCoordenadasDesdeBaseDatos() {
    try {
      final cliente = widget.creditoPreaprobado['perfiles_clientes'] ?? {};
      double? lat = double.tryParse(cliente['lat_negocio']?.toString() ?? '');
      double? lng = double.tryParse(cliente['lng_negocio']?.toString() ?? '');

      if (lat != null && lng != null) {
        _posicionNegocio = LatLng(lat, lng);
      }
    } catch (e) {
      debugPrint("Error leyendo coordenadas de perfiles_clientes: $e");
    } finally {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  @override
  void dispose() {
    _f2VentasDiariasController.dispose();
    _f3DeudasInformalesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _calcularCuotaFinanciera() {
    if (_montoSugeridoAsesor <= 0 || _plazoMeses <= 0) return;
    const double tea = 0.60; 
    double tem = pow(1.0 + tea, 1.0 / 12.0) - 1.0;
    double factor = pow(1.0 + tem, _plazoMeses).toDouble();
    double cuota = _montoSugeridoAsesor * (tem * factor) / (factor - 1.0);

    setState(() {
      _cuotaCalculada = cuota;
    });
  }

  Future<Position?> _obtenerUbicacionAsesor() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _validarYEnviarFicha() async {
    if (!_formKey.currentState!.validate()) {
      if (_tabController.index != 0) {
        _tabController.animateTo(0);
      }
      return;
    }

    if (!_f1NegocioExiste || _f5ReputacionCaracter == 'SOSPECHOSA') {
      _mostrarPantallaVeto();
      return;
    }

    double ventasDeclaradas = double.tryParse(_f2VentasDiariasController.text) ?? 0.0;
    double ingresoMensualCalculado = ventasDeclaradas * 26; 
    double diferenciaPorcentaje = ((ingresoMensualCalculado - _ingresoPromedioBase) / _ingresoPromedioBase).abs();

    if (diferenciaPorcentaje > 0.40) {
      _mostrarAlertaConsistencia(ingresoMensualCalculado);
    } else {
      _procesarGuardadoEnBD('APROBADO', 'Evaluación regular conforme en campo por el analista.');
    }
  }

  Future<void> _procesarGuardadoEnBD(String dictamen, String justify) async {
    setState(() => _isSaving = true);
    Position? posicionAsesor = await _obtenerUbicacionAsesor();

    try {
      await _supabase.from('fichas_campo').insert({
        'id_preaprobado': widget.creditoPreaprobado['id'],
        'monto_verificado': _montoSugeridoAsesor,
        'plazo_verificado': _plazoMeses,
        'cuota_estimada': _cuotaCalculada,
        'estado_evaluacion': dictamen,
        'observaciones': justify,
        'latitud_asesor': posicionAsesor?.latitude,
        'longitud_asesor': posicionAsesor?.longitude,
      });

      await _supabase
          .from('creditos_preaprobados')
          .update({'estado': 'VISITA_REALIZADA'})
          .eq('id', widget.creditoPreaprobado['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ficha guardada con geolocalización de auditoría 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _mostrarAlertaConsistencia(double ingresoCalculado) {
    final justificacionController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF15A24), size: 28),
            SizedBox(width: 8),
            Text('Alerta de Consistencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Los ingresos en campo (S/ ${ingresoCalculado.toStringAsFixed(2)}) varían más del 40% frente al histórico.', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: justificacionController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Sustento para el comité...'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Modificar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF15A24)),
            onPressed: () {
              if (justificacionController.text.trim().isEmpty) return;
              Navigator.pop(context);
              _procesarGuardadoEnBD('APROBADO_CON_OBSERVACION', justificacionController.text.trim());
            },
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _mostrarPantallaVeto() {
    final vetoController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('VETO EN CAMPO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 10),
            TextField(controller: vetoController, decoration: const InputDecoration(labelText: 'Motivo del veto', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (vetoController.text.trim().isEmpty) return;
                Navigator.pop(context);
                _procesarGuardadoEnBD('RECHAZADO_VETO', vetoController.text.trim());
              },
              child: const Text('Confirmar Veto', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.creditoPreaprobado['perfiles_clientes'] ?? {};
    final String nombreCompleto = '${cliente['nombres'] ?? 'Cliente'} ${cliente['apellidos'] ?? ''}';
    
    // CORRECCIÓN INTEGRADA: Lectura limpia y directa de 'dni' desde el mapa del perfil
    final String dniCliente = cliente['dni'] ?? 'DNI no especificado';
    
    // CORRECCIÓN INTEGRADA: Mapeo y formateo real dinámico de la dirección del negocio
    final String direccionNegocio = cliente['direccion_negocio'] ?? 'Dirección no especificada';
    final String distrito = cliente['distrito'] ?? '';
    final String provincia = cliente['provincia'] ?? '';
    final String direccionCompleta = distrito.isEmpty && provincia.isEmpty 
        ? direccionNegocio 
        : '$direccionNegocio, $distrito - $provincia';

    const Color purpuraOscuroFondo = Color(0xFF1F0B2E); 
    const Color purpuraAlfin = Color(0xFF8B2BB3);      
    const Color naranjaAlfin = Color(0xFFF15A24);      

    Widget contenidoCabeceraUnificado = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nombreCompleto, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF212121))
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.layers_outlined, size: 16, color: purpuraAlfin),
            const SizedBox(width: 6),
            Text('Segmentación asignada : ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(
              _segmentoCliente, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: purpuraAlfin, fontSize: 13)
            ),
          ],
        ),
        const Divider(height: 20, thickness: 1),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: naranjaAlfin),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                direccionCompleta, // Muestra dinámicamente el valor real de la base de datos
                style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: purpuraOscuroFondo, 
      appBar: AppBar(
        title: const Text('Ficha de Evaluación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: purpuraAlfin,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                
                // 1. CONTENEDOR BLANCO SUPERIOR CON EFECTO SHIMMER ACOTADO
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: EfectoShimmerContenedor(child: contenidoCabeceraUnificado),
                    ),
                  ),
                ),

                // 2. MAPA CARTOGRÁFICO
                Expanded(
                  flex: 3,
                  child: _isLoadingMap
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: _posicionNegocio,
                                  initialZoom: 15.0,
                                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.alfinbancoventaapp.app',
                                  ),
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: _posicionNegocio,
                                        radius: 120,
                                        useRadiusInMeter: true,
                                        color: purpuraAlfin.withOpacity(0.2),
                                        borderColor: purpuraAlfin,
                                        borderStrokeWidth: 2,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _posicionNegocio,
                                        width: 60,
                                        height: 60,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: purpuraAlfin, 
                                                shape: BoxShape.circle, 
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                                              ),
                                              child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 20),
                                            ),
                                            const Icon(Icons.arrow_drop_down, color: purpuraAlfin, size: 14),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6), 
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                                    SizedBox(width: 6),
                                    Text('Live Tracking', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                ),

                // 3. PANEL INFERIOR CON TABBAR
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(width: 36, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                        
                        TabBar(
                          controller: _tabController,
                          labelColor: purpuraAlfin,
                          unselectedLabelColor: Colors.grey[500],
                          indicatorColor: purpuraAlfin,
                          tabs: const [
                            Tab(text: 'Evaluación', icon: Icon(Icons.assignment_turned_in_outlined)),
                            Tab(text: 'Línea Crédito', icon: Icon(Icons.monetization_on_outlined)),
                            Tab(text: 'Detalles', icon: Icon(Icons.badge_outlined)),
                          ],
                        ),

                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              
                              // PESTAÑA EVALUACIÓN
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildCasillaCard(
                                        child: SwitchListTile(
                                          title: const Text('F1: ¿El negocio existe físicamente?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                          value: _f1NegocioExiste,
                                          activeColor: purpuraAlfin,
                                          onChanged: (val) => setState(() => _f1NegocioExiste = val),
                                        ),
                                      ),
                                      _buildCasillaCard(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: TextFormField(
                                            controller: _f2VentasDiariasController,
                                            decoration: const InputDecoration(
                                              labelText: 'F2: Ventas Declaradas por Día (S/)',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildBotonEnvioComite(),
                                    ],
                                  ),
                                ),
                              ),

                              // PESTAÑA LÍNEA CRÉDITO
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Monto Propuesto:'),
                                              Text('S/ ${_montoSugeridoAsesor.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: naranjaAlfin)),
                                            ],
                                          ),
                                          Slider(
                                            value: _montoSugeridoAsesor,
                                            min: 500,
                                            max: _montoHipotesisOriginal > 500 ? _montoHipotesisOriginal : 5000,
                                            divisions: 20,
                                            activeColor: purpuraAlfin,
                                            onChanged: (val) {
                                              setState(() {
                                                _montoSugeridoAsesor = val;
                                                _calcularCuotaFinanciera();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: purpuraAlfin, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Cuota Estimada:', style: TextStyle(color: Colors.white70)),
                                          Text('S/ ${_cuotaCalculada.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildBotonEnvioComite(),
                                  ],
                                ),
                              ),

                              // PESTAÑA DETALLES (CORREGIDA CON DNI DINÁMICO)
                              ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.credit_card, color: purpuraAlfin), 
                                    title: const Text('DNI del Cliente', style: TextStyle(fontWeight: FontWeight.bold)), 
                                    subtitle: Text(dniCliente), // Muestra el DNI real mapeado dinámicamente
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.bar_chart, color: purpuraAlfin), 
                                    title: const Text('Monto Hipótesis Base'), 
                                    subtitle: Text('S/ $_montoHipotesisOriginal'),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildBotonEnvioComite(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              ],
            ),
    );
  }

  Widget _buildBotonEnvioComite() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF15A24), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: _validarYEnviarFicha,
        child: const Text(
          'ENVIAR EVALUACIÓN AL COMITÉ', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
        ),
      ),
    );
  }

  Widget _buildCasillaCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: child,
    );
  }
}

class EfectoShimmerContenedor extends StatefulWidget {
  final Widget child;
  const EfectoShimmerContenedor({Key? key, required this.child}) : super(key: key);

  @override
  State<EfectoShimmerContenedor> createState() => _EfectoShimmerContenedorState();
}

class _EfectoShimmerContenedorState extends State<EfectoShimmerContenedor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
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
                return FractionalTranslation(
                  translation: Offset((_controller.value * 3.0) - 1.5, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.55), 
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.35, 0.5, 0.65],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }
}