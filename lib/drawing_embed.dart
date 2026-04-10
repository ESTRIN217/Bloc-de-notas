import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

// 1. Definimos el Embed Personalizado
class DrawingBlockEmbed extends quill.CustomBlockEmbed {
  const DrawingBlockEmbed(String data) : super('drawing', data);
}

// 2. Modelo de datos serializable para cada trazo
class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;
  final bool isEraser;

  DrawnLine({
    required this.path,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  // Convierte el trazo a JSON
  Map<String, dynamic> toJson() => {
        'path': path.map((o) => {'x': o.dx, 'y': o.dy}).toList(),
        'color': color.value,
        'width': width,
        'isEraser': isEraser,
      };

  // Reconstruye el trazo desde JSON
  factory DrawnLine.fromJson(Map<String, dynamic> json) {
    return DrawnLine(
      path: (json['path'] as List)
          .map((o) => Offset((o['x'] as num).toDouble(), (o['y'] as num).toDouble()))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }
}

// 3. El Constructor del Embed (Lo que Quill usa para renderizar)
class DrawingEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'drawing';

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    quill.QuillController controller,
    quill.Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    return _DrawingWidget(
      controller: controller,
      node: node,
      readOnly: readOnly,
    );
  }
}

// 4. El Widget Interactivo
class _DrawingWidget extends StatefulWidget {
  final quill.QuillController controller;
  final quill.Embed node;
  final bool readOnly;

  const _DrawingWidget({
    super.key,
    required this.controller,
    required this.node,
    required this.readOnly,
  });

  @override
  State<_DrawingWidget> createState() => _DrawingWidgetState();
}

class _DrawingWidgetState extends State<_DrawingWidget> {
  List<DrawnLine> lines = [];
  DrawnLine? currentLine;

  double _height = 300.0;
  Color _currentColor = Colors.black;
  double _currentWidth = 3.0;
  bool _isEraser = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga los datos guardados en el JSON del documento
  void _loadData() {
    final dataStr = widget.node.value.data as String;
    if (dataStr == 'nuevo_dibujo' || dataStr.isEmpty) {
      lines = [];
      _height = 300.0;
    } else {
      try {
        final map = jsonDecode(dataStr);
        _height = (map['height'] as num).toDouble();
        lines = (map['lines'] as List).map((e) => DrawnLine.fromJson(e)).toList();
      } catch (e) {
        debugPrint("Error parsing drawing: $e");
      }
    }
  }

  // Guarda los trazos actuales en el controlador de Quill
  void _saveToDocument() {
    if (widget.readOnly) return;

    final map = {
      'height': _height,
      'lines': lines.map((e) => e.toJson()).toList(),
    };
    final newJsonStr = jsonEncode(map);

    final offset = widget.node.documentOffset;
    
    // Actualizamos el documento con el nuevo JSON sin mover el cursor del usuario
    widget.controller.replaceText(
      offset,
      1,
      quill.BlockEmbed.custom(DrawingBlockEmbed(newJsonStr)),
      widget.controller.selection,
    );
  }

  void _deleteEmbed() {
    final offset = widget.node.documentOffset;
    widget.controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Container(
        height: _height,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(100),
        child: CustomPaint(
          painter: _DrawingPainter(lines: lines),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de Herramientas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: (!_isEraser && _currentWidth == 3.0) ? Colors.blue : null,
                  onPressed: () => setState(() {
                    _isEraser = false;
                    _currentWidth = 3.0;
                  }),
                  tooltip: 'Lápiz',
                ),
                IconButton(
                  icon: const Icon(Icons.brush),
                  color: (!_isEraser && _currentWidth == 15.0) ? Colors.yellow.shade700 : null,
                  onPressed: () => setState(() {
                    _isEraser = false;
                    _currentWidth = 15.0;
                    _currentColor = Colors.yellow.withAlpha(150);
                  }),
                  tooltip: 'Resaltador',
                ),
                IconButton(
                  icon: const Icon(Icons.cleaning_services),
                  color: _isEraser ? Colors.red : null,
                  onPressed: () => setState(() {
                    _isEraser = true;
                    _currentWidth = 20.0;
                  }),
                  tooltip: 'Borrador',
                ),
                const SizedBox(width: 8),
                ..._colors.map((color) => GestureDetector(
                      onTap: () => setState(() {
                        _isEraser = false;
                        _currentWidth = 3.0;
                        _currentColor = color;
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentColor == color.value && !_isEraser
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteEmbed,
                  tooltip: 'Eliminar dibujo',
                ),
              ],
            ),
          ),

          // Lienzo y control de redimensión
          Stack(
            children: [
              GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    currentLine = DrawnLine(
                      path: [details.localPosition],
                      color: _currentColor,
                      width: _currentWidth,
                      isEraser: _isEraser,
                    );
                    lines.add(currentLine!);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    currentLine?.path.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  currentLine = null;
                  // Guardamos en el JSON del documento al soltar el dedo
                  _saveToDocument();
                },
                child: SizedBox(
                  height: _height,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _DrawingPainter(lines: lines),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _height = (_height + details.delta.dy).clamp(100.0, 800.0);
                    });
                  },
                  onPanEnd: (details) {
                    // Guardamos la nueva altura en el JSON al terminar de redimensionar
                    _saveToDocument();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                    ),
                    child: const Icon(Icons.drag_indicator, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 5. El Motor de Dibujo
class _DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;

  _DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.path.isEmpty) continue;

      final paint = Paint()
        ..color = line.isEraser ? Colors.transparent : line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (line.isEraser) {
        paint.blendMode = BlendMode.clear;
      }

      final path = Path();
      path.moveTo(line.path.first.dx, line.path.first.dy);
      for (int j = 1; j < line.path.length; j++) {
        path.lineTo(line.path[j].dx, line.path[j].dy);
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}