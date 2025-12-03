import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:torch_light/torch_light.dart';

class CompassScreen extends StatefulWidget {
  final double targetAzimuth;
  final double targetElevation;
  final String userLatitude;
  final String userLongitude;

  const CompassScreen({
    super.key,
    required this.targetAzimuth,
    required this.targetElevation,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  bool _isAligned = false;
  bool _torchOn = false;
  bool _canBeep = true;
  bool _isLocked = false;

  // STRONG BEEP + VIBRATION
  void _playBeepAndVibrate() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  // TORCH CONTROL
  Future<void> _toggleTorch() async {
    try {
      if (_torchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Torch not available on this device")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // BLUE NAVBAR + BACK BUTTON
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 47, 132),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compass Alignment',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_off : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),

      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final heading = snapshot.data!.heading ?? 0;
          final accuracy = snapshot.data!.accuracy ?? 100;

          double diff =
              ((widget.targetAzimuth - heading + 360) % 360).abs();
          if (diff > 180) diff = 360 - diff;

          // PERFECT ALIGNMENT → BEEP + LOCK
          if (diff <= 1 && _canBeep && !_isLocked) {
            _isAligned = true;
            _isLocked = true;
            _canBeep = false;
            _playBeepAndVibrate();
          } else if (diff > 6 && !_isLocked) {
            _isAligned = false;
            _canBeep = true;
          }

          // GREEN DOT (FIXED ON NSWE HEIGHT)
          final double angleRad = -widget.targetAzimuth * pi / 180;
          const double radius = 107;
          final double dotX = radius * sin(angleRad);
          final double dotY = radius * cos(angleRad);

          return Column(
            children: [
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _infoChip(
                    'Target Angle',
                    '${widget.targetAzimuth.toStringAsFixed(0)}°',
                  ),
                  _infoChip(
                    'Elevation',
                    '${widget.targetElevation.toStringAsFixed(0)}°',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Location: ${widget.userLatitude}, ${widget.userLongitude}',
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 12),

              // CALIBRATION WARNING
              if (accuracy > 20)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "⚠️ Move your phone in figure-8 to calibrate",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // COMPASS BASE
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF1D4ED8),
                            width: 4,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: const [
                            Positioned(top: 8, child: Text("N", style: _dirText)),
                            Positioned(bottom: 8, child: Text("S", style: _dirText)),
                            Positioned(left: 8, child: Text("W", style: _dirText)),
                            Positioned(right: 8, child: Text("E", style: _dirText)),
                          ],
                        ),
                      ),

                      // USER NEEDLE (LOCKED AFTER ALIGN)
                      Transform.rotate(
                        angle: -(_isLocked
                                ? widget.targetAzimuth
                                : heading) *
                            pi /
                            180,
                        child: const Icon(
                          Icons.navigation,
                          size: 90,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),

                      // GREEN TARGET DOT
                      Positioned(
                        left: 130 + dotX - 6,
                        top: 130 - dotY - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // USER ANGLE
              Text(
                'User Angle: ${heading.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              // DIFFERENCE
              Text(
                'Difference: ${diff.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // LOCK STATUS
              if (_isLocked)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "Compass Locked!",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE0ECFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ),
      ],
    );
  }
}

const TextStyle _dirText =
    TextStyle(fontSize: 20, fontWeight: FontWeight.bold);