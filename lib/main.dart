import 'package:flutter/material.dart';

void main() {
  runApp(const AurixApp());
}

class AurixApp extends StatelessWidget {
  const AurixApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF090A0C);
    return MaterialApp(
      title: 'AURIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8E8E8),
          secondary: Color(0xFF9CA3AF),
          surface: Color(0xFF15171B),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AurixHomePage(),
    );
  }
}

class AurixHomePage extends StatelessWidget {
  const AurixHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AURIX',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'PERSONAL AI',
                        style: TextStyle(
                          color: Color(0xFF858991),
                          fontSize: 9,
                          letterSpacing: 2.4,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171A1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF292D33)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFFB7C5B8)),
                        SizedBox(width: 7),
                        Text(
                          'OFFLINE',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.3,
                            color: Color(0xFFD4D8D4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Center(child: _AurixOrb()),
              const SizedBox(height: 38),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Hello, Rizwan.',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Your personal assistant is getting ready.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF92969E),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141619),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF292D32)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.memory_rounded,
                            size: 18, color: Color(0xFFD6D8DC)),
                        SizedBox(width: 9),
                        Text(
                          'LOCAL AI ENGINE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'SETUP PENDING',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.1,
                            color: Color(0xFFB9A987),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 13),
                    Text(
                      'A lightweight on-device model will run directly on this phone. No API key required.',
                      style: TextStyle(
                        height: 1.5,
                        fontSize: 13,
                        color: Color(0xFF9A9EA6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF17191D),
                      title: const Text('AURIX is being prepared'),
                      content: const Text(
                        'The next development step is to add and test a small local AI model for your Redmi 12 5G (4 GB RAM). Chat will be enabled after the model engine is connected.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(
                    'LOCAL AI SETUP',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE3E5E8),
                    side: const BorderSide(color: Color(0xFF454A52)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'PRIVATE BY DESIGN  •  RUNS ON YOUR DEVICE',
                  style: TextStyle(
                    color: Color(0xFF686D75),
                    fontSize: 9,
                    letterSpacing: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E9EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.bubble_chart_rounded,
        color: Color(0xFF101216),
        size: 26,
      ),
    );
  }
}

class _AurixOrb extends StatelessWidget {
  const _AurixOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 214,
      height: 214,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF656B74),
            Color(0xFF343941),
            Color(0xFF171A1F),
            Color(0xFF0B0C0E),
          ],
          stops: [0, 0.38, 0.72, 1],
        ),
        border: Border.all(color: const Color(0xFF444A53), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332B3038),
            blurRadius: 48,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFF1F2F4), Color(0xFF9DA3AC), Color(0xFF515862)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB9C0CA).withValues(alpha: 0.22),
                blurRadius: 34,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFF171A1F),
            size: 42,
          ),
        ),
      ),
    );
  }
}
