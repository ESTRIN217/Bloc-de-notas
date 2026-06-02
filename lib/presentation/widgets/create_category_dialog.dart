import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloc_de_notas/providers/notes_provider.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart'; 

class CreateCategoryDialog extends StatefulWidget {
  const CreateCategoryDialog({super.key});

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      icon: const Icon(Icons.label_outlined), // Icono Outlined
      title: Text(localizations.newCategoryTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: localizations.categoryNameLabel,
            border: const OutlineInputBorder(), // Estilo M3 Outlined
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.categoryRequiredError;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        FilledButton( // Botón con estilo M3
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<NotesProvider>().addCategory(_controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text(localizations.create),
        ),
      ],
    );
  }
}