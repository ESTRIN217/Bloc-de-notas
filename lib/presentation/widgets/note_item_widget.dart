import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'list_item.dart';
import 'package:bloc_de_notas/embeds/audioembedbuilder.dart';
import 'package:bloc_de_notas/embeds/drawing_embed.dart';
import 'package:bloc_de_notas/embeds/timestampembed.dart';

class NoteItemWidget extends StatelessWidget {
  final ListItem item;
  final bool isListView;
  final bool isSelected;
  final bool isSelectionMode;
  final bool canReorder;
  final bool isTrashView;
  final int itemIndex;
  final String? moreButtonTooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMorePressed;

  const NoteItemWidget({
    super.key,
    required this.item,
    this.isListView = true,
    required this.isSelected,
    required this.isSelectionMode,
    required this.canReorder,
    required this.isTrashView,
    required this.itemIndex,
    required this.onTap,
    required this.onLongPress,
    required this.onMorePressed,
    this.moreButtonTooltip,
  });

  // Evaluamos si el fondo es oscuro usando el contexto para el fallback del tema
  bool _isColorDark(BuildContext context, int? colorValue) {
    if (colorValue == null) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return Color(colorValue).computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkBackground = _isColorDark(context, item.backgroundColor);
    final dynamicTextColor = isDarkBackground ? Colors.white : Colors.black87;
    final dynamicIconColor = isDarkBackground ? Colors.white : Colors.black87;

    // 1. Controlador temporal para renderizar el documento actual
    final previewController = quill.QuillController(
      document: item.document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    // 2. Configuración del editor en modo lectura con tus estilos exactos
    final richTextPreview = IgnorePointer(
      child: quill.QuillEditor.basic(
        controller: previewController,
        config: quill.QuillEditorConfig(
          showCursor: false,
          padding: EdgeInsets.zero,
          scrollable: false,
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              TextStyle(color: dynamicTextColor, fontSize: 16),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h1: quill.DefaultTextBlockStyle(
              TextStyle(
                color: dynamicTextColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(10, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h2: quill.DefaultTextBlockStyle(
              TextStyle(
                color: dynamicTextColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(8, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h3: quill.DefaultTextBlockStyle(
              TextStyle(
                color: dynamicTextColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(8, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            lists: quill.DefaultListBlockStyle(
              TextStyle(color: dynamicTextColor, fontSize: 16),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              null,
              null,
            ),
            small: TextStyle(color: dynamicTextColor, fontSize: 12),
            quote: quill.DefaultTextBlockStyle(
              TextStyle(
                color: dynamicTextColor,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              const quill.HorizontalSpacing(16, 0),
              const quill.VerticalSpacing(8, 8),
              const quill.VerticalSpacing(0, 0),
              BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: dynamicTextColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            link: TextStyle(
              color: isDarkBackground ? Colors.blue[300] : Colors.blue[700],
              decoration: TextDecoration.underline,
            ),
            indent: quill.DefaultTextBlockStyle(
              TextStyle(color: dynamicTextColor),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            leading: quill.DefaultTextBlockStyle(
              TextStyle(color: dynamicTextColor),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
          ),
          embedBuilders: [
            AudioEmbedBuilder(),
            DrawingEmbedBuilder(),
            TimeStampEmbedBuilder(),
            if (kIsWeb)
              ...FlutterQuillEmbeds.editorWebBuilders(
                imageEmbedConfig: QuillEditorImageEmbedConfig(
                  imageProviderBuilder: (context, imageUrl) {
                    if (imageUrl.startsWith('assets/')) {
                      return AssetImage(imageUrl);
                    }
                    return null;
                  },
                ),
                videoEmbedConfig: const QuillEditorWebVideoEmbedConfig(),
              )
            else
              ...FlutterQuillEmbeds.editorBuilders(
                imageEmbedConfig: QuillEditorImageEmbedConfig(
                  imageProviderBuilder: (context, imageUrl) {
                    if (imageUrl.startsWith('assets/')) {
                      return AssetImage(imageUrl);
                    }
                    return null;
                  },
                ),
                videoEmbedConfig: QuillEditorVideoEmbedConfig(
                  customVideoBuilder: (videoUrl, readOnly) {
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
    );

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.title.isNotEmpty)
          Text(
            item.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: dynamicTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (item.title.isNotEmpty && item.document.length > 1)
          const SizedBox(height: 8),
        if (item.document.length > 1)
          isListView
              ? ClipRect(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: richTextPreview,
                  ),
                )
              : Expanded(
                  child: ClipRect(child: richTextPreview),
                ),
        if (item.tags.isNotEmpty && !isTrashView) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: item.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dynamicTextColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 10, color: dynamicTextColor),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : (item.backgroundColor != null
              ? Color(item.backgroundColor!)
              : Theme.of(context).colorScheme.surfaceContainerLow),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          decoration: item.backgroundImagePath != null && !kIsWeb
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(item.backgroundImagePath!)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.1),
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: contentColumn,
      ),
    ),
    if (!isSelectionMode)
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isListView) ...[
            if (canReorder) ...[
              if (!item.isPinned)
              ReorderableDragStartListener(
                index: itemIndex,
                child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 0),
      child: Icon(Icons.drag_handle, color: dynamicIconColor),
    ),
              ),
              ],
          ] else ...[
            if (!isTrashView)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton(
                  icon: Icon(Icons.more_vert, color: dynamicIconColor),
                  onPressed: onMorePressed,
                  tooltip: moreButtonTooltip,
                ),
              ),
          ],
          if (item.isFavorite && !isTrashView)
            Padding(
              padding: const EdgeInsets.only(top: 8.0), 
              child: Icon(
                Icons.star_outline,
                color: dynamicIconColor,
              ),
            ),
          if (item.isPinned && !isTrashView)
            Padding(
              padding: const EdgeInsets.only(top: 8.0), 
              child: Icon(
                Icons.push_pin_outlined,
                color: dynamicIconColor,
              ),
            ),
        ],
      ),
  ],
),
        ),
      ),
    );
  }
}