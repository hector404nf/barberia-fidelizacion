import 'package:flutter/material.dart';

/// Muestra una alerta modal estilizada al estilo de la app.
/// Usar para errores de validación, confirmaciones y mensajes importantes.
Future<void> showAppAlert({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  bool isError = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade50 : Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 32,
                color: isError ? Colors.red.shade400 : Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (cancelText != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(cancelText, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (cancelText != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError ? Colors.red.shade400 : Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      confirmText ?? 'Entendido',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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

/// Helper rápido para errores de validación de formularios.
void showValidationError(BuildContext context, String message) {
  showAppAlert(
    context: context,
    title: 'Ups, algo faltó',
    message: message,
    confirmText: 'Ok',
    isError: true,
  );
}

/// Helper rápido para mensajes de éxito.
void showSuccessAlert(BuildContext context, String message, {VoidCallback? onConfirm}) {
  showAppAlert(
    context: context,
    title: '¡Listo!',
    message: message,
    confirmText: 'Ok',
    isError: false,
    onConfirm: onConfirm,
  );
}
