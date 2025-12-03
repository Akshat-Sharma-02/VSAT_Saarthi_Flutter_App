import 'dart:math' as math;
import 'package:flutter/material.dart';

class LossCalculatorScreen extends StatefulWidget {
  const LossCalculatorScreen({super.key});

  @override
  State<LossCalculatorScreen> createState() => _LossCalculatorScreenState();
}

class _LossCalculatorScreenState extends State<LossCalculatorScreen> {
  final _diameterCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _wavelengthCtrl = TextEditingController();
  final _gainCtrl = TextEditingController();

  final _dataRateCtrl = TextEditingController();
  final _modFactorCtrl = TextEditingController();
  final _fecCtrl = TextEditingController();
  final _symbolRateCtrl = TextEditingController();

  final _distanceCtrl = TextEditingController();
  final _flossFreqCtrl = TextEditingController();
  final _txGainCtrl = TextEditingController();
  final _rxGainCtrl = TextEditingController();
  final _fsplCtrl = TextEditingController();
  final _fsplResultCtrl = TextEditingController();

  final _eirpCtrl = TextEditingController();
  final _gtCtrl = TextEditingController();
  final _bandwidthCtrl = TextEditingController();
  final _cnRatioCtrl = TextEditingController();

  bool _showGain = false;
  bool _showSymbolRate = false;
  bool _showFspl = false;
  bool _showCn = false;

  @override
  void initState() {
    super.initState();
    _freqCtrl.addListener(_onFrequencyChanged);
  }

  void _onFrequencyChanged() {
    final fGHz = double.tryParse(_freqCtrl.text);
    if (fGHz == null || fGHz == 0) {
      _wavelengthCtrl.clear();
      return;
    }
    final wavelength = 3e8 / (fGHz * 1e9);
    _wavelengthCtrl.text = wavelength.toStringAsFixed(6);
  }

  bool _filled(List<TextEditingController> c) =>
      c.every((e) => e.text.trim().isNotEmpty);

  // GAIN
  void _calculateGain() {
    if (!_filled([_diameterCtrl, _freqCtrl])) return;

    final d = double.parse(_diameterCtrl.text);
    final f = double.parse(_freqCtrl.text) * 1e9;
    final lambda = 3e8 / f;
    const efficiency = 0.65;

    final gain =
        10 * math.log(efficiency * math.pow((math.pi * d / lambda), 2)) / math.ln10;

    _gainCtrl.text = gain.toStringAsFixed(2);
    setState(() => _showGain = true);
  }

  // SYMBOL RATE
  void _calculateSymbolRate() {
    if (!_filled([_dataRateCtrl, _modFactorCtrl, _fecCtrl])) return;

    final sr = double.parse(_dataRateCtrl.text) /
        (double.parse(_modFactorCtrl.text) *
            double.parse(_fecCtrl.text));

    _symbolRateCtrl.text = sr.toStringAsFixed(4);
    setState(() => _showSymbolRate = true);
  }

  // FSPL (FIXED: km → meters)
  void _calculateFspl() {
    if (!_filled(
        [_distanceCtrl, _flossFreqCtrl, _txGainCtrl, _rxGainCtrl])) {
      return;
    }

    final d = double.parse(_distanceCtrl.text);
    final f = double.parse(_flossFreqCtrl.text);
    final gt = double.parse(_txGainCtrl.text);
    final gr = double.parse(_rxGainCtrl.text);

    final fspl = 92.45 +
      20 * math.log(d) / math.ln10 +
      20 * math.log(f) / math.ln10 -
      gt -
      gr;

    _fsplCtrl.text = fspl.toStringAsFixed(2);
    _fsplResultCtrl.text = fspl.toStringAsFixed(2);
    setState(() => _showFspl = true);
  }

  // C/N
  void _calculateCnRatio() {
    if (!_filled(
        [_eirpCtrl, _fsplResultCtrl, _gtCtrl, _bandwidthCtrl])) {
      return;
    }

    const k = -228.6;

    final cn = double.parse(_eirpCtrl.text) -
        double.parse(_fsplResultCtrl.text) +
        double.parse(_gtCtrl.text) -
        k -
        double.parse(_bandwidthCtrl.text);

    _cnRatioCtrl.text = cn.toStringAsFixed(2);
    setState(() => _showCn = true);
  }

  Widget _field(String label, TextEditingController c, {bool ro = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        readOnly: ro,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _btn(String t, VoidCallback f) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: f,
        child: Text(
          t,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _glassCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(children: [
            _glassCard(Column(children: [
              _field("Dish Diameter (m)", _diameterCtrl),
              _field("Frequency (GHz)", _freqCtrl),
              _field("Wavelength", _wavelengthCtrl, ro: true),
              const SizedBox(height: 4),
              _btn("Calculate Gain", _calculateGain),
              if (_showGain) _field("Gain (dBi)", _gainCtrl, ro: true),
            ])),

            _glassCard(Column(children: [
              _field("Data Rate", _dataRateCtrl),
              _field("Modulation", _modFactorCtrl),
              _field("FEC", _fecCtrl),
              const SizedBox(height: 4),
              _btn("Calculate Symbol Rate", _calculateSymbolRate),
              if (_showSymbolRate)
                _field("Symbol Rate", _symbolRateCtrl, ro: true),
            ])),

            _glassCard(Column(children: [
              _field("Distance (km)", _distanceCtrl),
              _field("Frequency (GHz)", _flossFreqCtrl),
              _field("Tx Gain", _txGainCtrl),
              _field("Rx Gain", _rxGainCtrl),
              const SizedBox(height: 4),
              _btn("Calculate FSPL", _calculateFspl),
              if (_showFspl) _field("FSPL", _fsplCtrl, ro: true),
            ])),

            _glassCard(Column(children: [
              _field("EIRP", _eirpCtrl),
              _field("FSPL", _fsplResultCtrl, ro: true),
              _field("G/T", _gtCtrl),
              _field("Bandwidth", _bandwidthCtrl),
              const SizedBox(height: 4),
              _btn("Calculate C/N Ratio", _calculateCnRatio),
              if (_showCn)
                _field("C/N Ratio", _cnRatioCtrl, ro: true),
            ])),
          ]),
        ),
      ),
    );
  }
}