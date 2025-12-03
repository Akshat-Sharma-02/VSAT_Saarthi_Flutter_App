import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'compass_screen.dart';

class LookUpAngleScreen extends StatefulWidget {
  const LookUpAngleScreen({super.key});

  @override
  State<LookUpAngleScreen> createState() => _LookUpAngleScreenState();
}

class _LookUpAngleScreenState extends State<LookUpAngleScreen> {
  static const String satListUrl =
      'https://satellite-detail.onrender.com/satellite/getsatellite';
  static const String lookupApiUrl =
      'https://satellite-detail.onrender.com/angle/calculatelookupangle';

  final _userLat = TextEditingController();
  final _userLon = TextEditingController();
  final _satLat = TextEditingController();
  final _satLon = TextEditingController();
  final _satAlt = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<String> _satellites = ['Satellite'];
  String _selectedSatellite = 'Satellite';

  final List<String> _providers = [
    'Provider',
    'Dish TV',
    'DD Free Dish',
    'TATA Play',
  ];
  String _selectedProvider = 'Provider';

  String? _azimuth;
  String? _elevation;

  bool _gpsLoading = false;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _fetchSatellites();
  }

  @override
  void dispose() {
    _userLat.dispose();
    _userLon.dispose();
    _satLat.dispose();
    _satLon.dispose();
    _satAlt.dispose();
    super.dispose();
  }

  Future<void> _fetchSatellites() async {
    try {
      final res = await http.get(Uri.parse(satListUrl));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as List;

      if (!mounted) return;
      setState(() {
        _satellites =
            ['Satellite', ...data.map((e) => e['satname'].toString())];
      });
    } catch (_) {}
  }

  String _providerToSatellite(String p) {
    if (p == 'Dish TV' || p == 'DD Free Dish') return 'GSAT-15';
    if (p == 'TATA Play') return 'GSAT-24';
    return 'Satellite';
  }

  Future<void> _loadSatelliteDetails(String name) async {
    try {
      final res = await http.get(Uri.parse(satListUrl));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as List;

      for (final item in data) {
        if (item['satname'] == name) {
          if (!mounted) return;
          setState(() {
            _satLat.text = item['satlatitude'].toString();
            _satLon.text = item['satlongitude'].toString();
            _satAlt.text = item['sataltitude'].toString();
          });
          break;
        }
      }
    } catch (_) {}
  }

  // GPS
  Future<void> _useGPS() async {
    setState(() => _gpsLoading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw 'GPS OFF';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'PERMISSION DENIED';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _userLat.text = position.latitude.toStringAsFixed(6);
        _userLon.text = position.longitude.toStringAsFixed(6);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS fetch failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _calculateAngle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _calculating = true;
      _azimuth = null;
      _elevation = null;
    });

    try {
      final body = {
        'longitude': _userLon.text,
        'latitude': _userLat.text,
        'satlatitude': _satLat.text,
        'satlongitude': _satLon.text,
        'sataltitude': _satAlt.text,
      };

      final res = await http.post(
        Uri.parse(lookupApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) throw 'API ERROR';

      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() {
        _azimuth =
            double.parse(data['azimuth'].toString()).toStringAsFixed(5);
        _elevation =
            double.parse(data['elevation'].toString()).toStringAsFixed(5);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calculation failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Widget _input(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _blueButton(String text, VoidCallback onTap, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(text,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ),
    );
  }

  Widget _glassCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withAlpha(13),
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _glassCard(Column(children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProvider,
                    decoration: const InputDecoration(labelText: 'Provider'),
                    items: _providers
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedProvider = v);
                      final sat = _providerToSatellite(v);
                      _selectedSatellite = sat;
                      _loadSatelliteDetails(sat);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSatellite,
                    decoration: const InputDecoration(labelText: 'Satellite'),
                    items: _satellites
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedSatellite = v);
                      _loadSatelliteDetails(v);
                    },
                  ),
                ])),

                const SizedBox(height: 16),

                _glassCard(Column(children: [
                  _input('Latitude', _userLat),
                  const SizedBox(height: 12),
                  _input('Longitude', _userLon),
                  const SizedBox(height: 12),
                  _blueButton('Use GPS', _useGPS, loading: _gpsLoading),
                ])),

                const SizedBox(height: 16),

                _glassCard(Column(children: [
                  _input('Satellite Latitude', _satLat),
                  const SizedBox(height: 12),
                  _input('Satellite Longitude', _satLon),
                  const SizedBox(height: 12),
                  _input('Satellite Altitude', _satAlt),
                ])),

                const SizedBox(height: 20),

                _blueButton('Calculate Look-Up Angle', _calculateAngle,
                    loading: _calculating),

                if (_azimuth != null && _elevation != null) ...[
                  const SizedBox(height: 24),
                  _glassCard(Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("Azimuth: $_azimuth°",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Elevation: $_elevation°",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                    const SizedBox(height: 16),
                    _blueButton("Open Compass", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompassScreen(
                            targetAzimuth: double.parse(_azimuth!),
                            targetElevation: double.parse(_elevation!),
                            userLatitude: _userLat.text,
                            userLongitude: _userLon.text,
                          ),
                        ),
                      );
                    })
                  ]))
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
