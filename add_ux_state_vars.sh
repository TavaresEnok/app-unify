#!/bin/bash
# Complete UX Integration Script
# Adds state variables, UI widgets, and save logic to all diagnostic pages

set -e

PAGES=("03" "05"  "06" "07")

echo "🚀 Starting UX Integration for ${#PAGES[@]} pages..."

for PAGE in "${PAGES[@]}"; do
  FILE="lib/core/pages/diagnostics/diagnostic_${PAGE}_page.dart"
  echo "Processing diagnostic_${PAGE}_page.dart..."
  
  # Add state variables after WifiManagementController
  # Using direct file edit with sed for CRLF safety
  
  # Create backup
  cp "$FILE" "${FILE}.backup"
  
  # Find line with WifiManagementController and add UX vars after it
  awk '
    /WifiManagementController\? _wifiController;/ {
      print
      print ""
      print "  // UX Enhancements State"
      print "  TestMode _selectedTestMode = TestMode.complete;"
      print "  final _integrationHelper = DiagnosticIntegrationHelper();"
      print "  final _achievementService = AchievementService();"
      print "  bool _testSavedToHistory = false;"
      print "  NetworkHealthScore? _healthScore;"
      print "  Map<String, dynamic>? _comparison;"
      next
    }
    {print}
  ' "${FILE}.backup" > "$FILE"
  
  echo "✅ Added state variables to diagnostic_${PAGE}_page.dart"
done

echo "✅ State variables added to all pages!"
echo "Next: Add UI widgets and save logic (manual step)"
