import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bloc_de_notas/main.dart'; // Importante para poder navegar a MyHomePage
import 'package:bloc_de_notas/l10n/app_localizations.dart';

class EntryAnimation extends StatefulWidget {
  final Widget child;
  final int index; // Permite un efecto escalonado opcional

  const EntryAnimation({
    super.key, 
    required this.child, 
    this.index = 0,
  });

  @override
  State<EntryAnimation> createState() => _EntryAnimationState();
}

class _EntryAnimationState extends State<EntryAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      // Duración estándar "Medium 1" de Material 3 (250ms)
      duration: const Duration(milliseconds: 250), 
    );

    // Curva de desaceleración nativa de Material 3 (Emphasized Decelerate)
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.05, 0.7, 0.1, 1.0), 
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0, 
      end: 1.0,
    ).animate(curvedAnimation);

    // Desplazamiento sutil desde abajo (10% de su tamaño)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1), 
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Pequeño retraso según el índice para el efecto cascada (staggered effect)
    Future.delayed(Duration(milliseconds: (widget.index * 30).clamp(0, 300)), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador con una duración óptima para no retrasar de más al usuario
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animación de desvanecimiento (Fade)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Animación de escala suave basada en los principios de Material 3
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic, 
      ),
    );

    // Iniciar la animación al cargar la pantalla
    _controller.forward();

    // Temporizador para dar paso a la pantalla principal de manera automática
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MyHomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Transición de salida suave (Cross-fade) hacia el inicio
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Se adapta automáticamente al fondo claro o oscuro de la app
      backgroundColor: colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tu logotipo con abstracción geométrica y fondo transparente
                Image.asset(
                  'assets/icon/notas.png', // Asegúrate de tener la ruta correcta en tu pubspec.yaml
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) {
                    // Respaldo geométrico outlined elegante por si no encuentra el archivo
                    return Icon(
                      Icons.polyline_outlined,
                      size: 120,
                      color: colorScheme.primary,
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Título de la aplicación con tipografía limpia de Material 3
                Text(
                  AppLocalizations.of(context)!.flutterNotes,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}