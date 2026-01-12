#!/bin/bash
# Add UX imports to diagnostic pages 05, 06, 07
# diagnostic_02 and 03 already have imports

set -e

PAGES=("05" "06" "07")

echo "🚀 Adding UX imports to pages: ${PAGES[@]}"

for PAGE in "${PAGES[@]}"; do
  FILE="lib/core/pages/diagnostics/diagnostic_${PAGE}_page.dart"
  echo "Processing $FILE..."
  
  # Create backup
  cp "$FILE" "${FILE}.backup2"
  
  # Find the line with wifi_management_controller import and add UX imports after
  awk '
    /import.*wifi_management_controller\.dart/ {
      print
      print ""
      print "// UX Enhancements - Sprint 1-3"
      print "import '\''../../models/test_mode.dart'\'';"
      print "import '\''../../models/network_health_score.dart'\'';"
      print "import '\''../../widgets/health_score_widget.dart'\'';"
      print "import '\''../../widgets/test_mode_selector.dart'\'';"
      print "import '\''../../widgets/comparison_widget.dart'\'';"
      print "import '\''../../services/diagnostic_integration_helper.dart'\'';"
      print "import '\''../../services/achievement_service.dart'\'';"
      print "import '\''../../services/test_history_service.dart'\'';"
      next
    }
    {print}
  ' "${FILE}.backup2" > "$FILE"
  
  echo "✅ Added imports to diagnostic_${PAGE}_page.dart"
done

echo "✅ All imports added successfully!"
