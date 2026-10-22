import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'ui.dart';

/// Full-screen celebration: Lottie check mark + streamers falling from the top.
class PaymentSuccess extends StatefulWidget {
  final int amount;
  final String method; // 'qr' | 'cash'
  final VoidCallback onDone;
  const PaymentSuccess({super.key, required this.amount, required this.method, required this.onDone});

  @override
  State<PaymentSuccess> createState() => _PaymentSuccessState();
}

class _PaymentSuccessState extends State<PaymentSuccess> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Long thin strips = streamers ("băng rôn") rather than square confetti.
  Widget _emitter(Alignment at, double direction) => Align(
        alignment: at,
        child: ConfettiWidget(
          confettiController: _confetti,
          blastDirection: direction,
          blastDirectionality: BlastDirectionality.directional,
          emissionFrequency: 0.06,
          numberOfParticles: 12,
          maxBlastForce: 18,
          minBlastForce: 6,
          gravity: 0.25,
          particleDrag: 0.04,
          minimumSize: const Size(5, 18),
          maximumSize: const Size(9, 34),
          colors: const [Colors.red, Colors.orange, Colors.amber, Colors.green, Colors.blue, Colors.purple, Colors.pink],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Lottie.asset('assets/lottie/success_check.json', width: 200, height: 200, repeat: false),
                const SizedBox(height: 8),
                Text('Thanh toán thành công', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  '${fmtMoney(widget.amount)} · ${widget.method == 'qr' ? 'Chuyển khoản QR' : 'Tiền mặt'}',
                  style: t.titleMedium?.copyWith(color: Colors.green.shade700),
                ),
                const SizedBox(height: 28),
                FilledButton(onPressed: widget.onDone, child: const Text('Hoàn tất')),
              ]),
            ),
          ),
          _emitter(Alignment.topCenter, pi / 2),
          _emitter(Alignment.topLeft, pi / 3),
          _emitter(Alignment.topRight, 2 * pi / 3),
        ],
      ),
    );
  }
}
