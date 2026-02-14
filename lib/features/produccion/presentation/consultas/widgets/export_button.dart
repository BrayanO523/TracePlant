import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const ExportButton({super.key, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded),
      tooltip: 'Exportar Reporte',
    );
  }
}
