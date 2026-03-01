---
paths: pubspec.yaml
---
# Dependency Rules

## Version Pinning
- NEVER use `any` for a dependency version
- Pin with caret syntax: `package_name: ^X.Y.Z`
- Document the reason for any `dependency_overrides` with a comment directly above

## Adding Dependencies
- Do NOT add new packages without checking if an existing package already covers the need
- Prefer small, focused packages over large multi-purpose ones
- Check pub.dev scores — avoid packages with low popularity or no recent updates
- If a package is only used in 1-3 places, consider whether it's worth the dependency

## Assets
- Do NOT include deprecated or unused asset directories
- Images should be WebP format where possible (not PNG/JPG)
- App icons should be under 100 KB
- Always provide resolution variants (1x, 2x, 3x) for raster images
- Audit `assets:` section — only include directories that contain actively used files

## Icons
- `phosphor_flutter` is the primary icon package
- Do NOT add `font_awesome_flutter` or other icon packages
- The legacy SVG system (`assets/icon/golf-app-icons/`) is being removed
