#!/bin/bash

# Script to replace hardcoded colors with theme references
# This updates all .dart files in the lib directory

echo "Replacing hardcoded colors with theme references..."

# Find all .dart files in lib directory
find lib -name "*.dart" -type f | while read -r file; do
  # Skip the colors.dart file itself
  if [[ "$file" == *"design_tokens/colors.dart"* ]]; then
    continue
  fi

  # Replace old primary color (dark blue)
  sed -i '' 's/Color(0xFF253551)/AppTheme.of(context).primary/g' "$file"

  # Replace old secondary/loading color (green)
  sed -i '' 's/Color(0xFF25504F)/AppTheme.of(context).secondary/g' "$file"

  # Replace grey tertiary color
  sed -i '' 's/Color(0xFFA9A9A9)/AppTheme.of(context).tertiary/g' "$file"

  # Replace alternate grey
  sed -i '' 's/Color(0xFFE0E0DB)/AppTheme.of(context).alternate/g' "$file"
done

echo "Color replacement complete!"
echo "Please review the changes and test the app."
