import 'package:app_provedor/diagnostico_test_status.dart';
import 'package:flutter/material.dart';

Color getStatusColor(TestStatus status) {
  switch (status) {
    case TestStatus.pending:
      return Colors.grey[400]!;
    case TestStatus.running:
      return Colors.amber;
    case TestStatus.success:
      return Colors.green;
    case TestStatus.error:
      return Colors.redAccent;
  }
}

TestStatus getStatus(Map<String, dynamic>? data) {
  if (data == null) return TestStatus.pending;
  return data['status'] ?? TestStatus.pending;
}

String getResult(Map<String, dynamic>? data) {
  if (data == null) return "---";
  return data['result']?.toString() ?? "---";
}

Widget buildCardHeader({
  required String label,
  required TestStatus status,
  required Color primaryColor,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      if (status == TestStatus.running)
        const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      else
        Icon(
          status == TestStatus.success
              ? Icons.check_circle
              : status == TestStatus.error
                  ? Icons.error
                  : Icons.circle_outlined,
          color: getStatusColor(status),
          size: 20,
        ),
    ],
  );
}

Widget buildCardStatusText({
  required TestStatus status,
  String? result,
  required Color primaryColor,
  String? customRunningText,
}) {
  if (status == TestStatus.running) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        customRunningText ?? "Executando teste...",
        style: const TextStyle(
            fontStyle: FontStyle.italic, color: Colors.amberAccent, fontSize: 13),
      ),
    );
  } else if (status == TestStatus.error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        result ?? "Erro desconhecido.",
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }
  return const SizedBox.shrink();
}

String parseResultLine(String? text, String key) {
  if (text == null) return "---";
  try {
    return text
        .split('\n')
        .firstWhere((l) => l.startsWith(key), orElse: () => "$key ---")
        .split(':')
        .sublist(1)
        .join(':')
        .trim();
  } catch (e) {
    return "---";
  }
}

String parseResultBlock(String? text, String key) {
  if (text == null) return "---";
  try {
    final parts = text.split(key);
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return "---";
  } catch (e) {
    return "---";
  }
}
