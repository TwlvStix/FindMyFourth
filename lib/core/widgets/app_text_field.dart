import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/app_phosphor_icons.dart';
import 'app_icon.dart';

enum AppTextFieldVariant {
  /// Outlined border style (default)
  outlined,

  /// Filled background style (light theme)
  filled,

  /// Filled background style (dark theme)
  filledDark,

  /// Underlined style (minimal)
  underlined,

  /// Search field with search icon
  search,
}

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? initialValue;
  final TextEditingController? controller;
  final AppTextFieldVariant variant;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final PhosphorIconData? prefixPhosphorIcon;
  final IconData? suffixIcon;
  final PhosphorIconData? suffixPhosphorIcon;
  final VoidCallback? onSuffixIconTap;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.controller,
    this.variant = AppTextFieldVariant.outlined,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.prefixPhosphorIcon,
    this.suffixIcon,
    this.suffixPhosphorIcon,
    this.onSuffixIconTap,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          cursorColor: widget.variant == AppTextFieldVariant.filledDark
              ? AppColors.textPrimary
              : null,
          style: widget.variant == AppTextFieldVariant.filledDark
              ? AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)
              : AppTypography.bodyMedium,
          decoration: _buildDecoration(hasError),
        ),
        if (widget.helperText != null && !hasError) ...[
          SizedBox(height: AppSpacing.xxs),
          Text(
            widget.helperText!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.stone,
            ),
          ),
        ],
        if (hasError) ...[
          SizedBox(height: AppSpacing.xxs),
          Text(
            widget.errorText!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  /// Build prefix icon widget with priority: Phosphor > Material
  Widget? _buildPrefixIcon() {
    if (widget.prefixPhosphorIcon != null) {
      return Padding(
        padding: AppSpacing.allSm,
        child: AppIcon(icon: widget.prefixPhosphorIcon!, color: AppColors.slate, size: AppIconSize.button),
      );
    }
    if (widget.prefixIcon != null) {
      return Icon(widget.prefixIcon, color: AppColors.slate);
    }
    return null;
  }

  /// Build suffix icon widget with priority: Phosphor > Material
  Widget? _buildSuffixIcon() {
    if (widget.suffixPhosphorIcon != null) {
      return IconButton(
        icon: AppIcon(icon: widget.suffixPhosphorIcon!, color: AppColors.slate, size: AppIconSize.button),
        onPressed: widget.onSuffixIconTap,
      );
    }
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: AppColors.slate),
        onPressed: widget.onSuffixIconTap,
      );
    }
    return null;
  }

  /// Build prefix icon widget for dark variant
  Widget? _buildPrefixIconDark() {
    if (widget.prefixPhosphorIcon != null) {
      return Padding(
        padding: AppSpacing.allSm,
        child: AppIcon(icon: widget.prefixPhosphorIcon!, color: AppColors.textMuted, size: AppIconSize.button),
      );
    }
    if (widget.prefixIcon != null) {
      return Icon(widget.prefixIcon, color: AppColors.textMuted);
    }
    return null;
  }

  /// Build suffix icon widget for dark variant
  Widget? _buildSuffixIconDark() {
    if (widget.suffixPhosphorIcon != null) {
      return IconButton(
        icon: AppIcon(icon: widget.suffixPhosphorIcon!, color: AppColors.textMuted, size: AppIconSize.button),
        onPressed: widget.onSuffixIconTap,
      );
    }
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: AppColors.textMuted),
        onPressed: widget.onSuffixIconTap,
      );
    }
    return null;
  }

  InputDecoration _buildDecoration(bool hasError) {
    final borderColor = hasError
        ? AppColors.error
        : _isFocused
            ? AppColors.navy
            : AppColors.cloud;

    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.stone,
          ),
          prefixIcon: _buildPrefixIcon(),
          suffixIcon: _buildSuffixIcon(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            borderSide: BorderSide(color: AppColors.cloud),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            borderSide: BorderSide(color: AppColors.error),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        );

      case AppTextFieldVariant.filled:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.stone,
          ),
          prefixIcon: _buildPrefixIcon(),
          suffixIcon: _buildSuffixIcon(),
          filled: true,
          fillColor: AppColors.sand,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        );

      case AppTextFieldVariant.filledDark:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: _buildPrefixIconDark(),
          suffixIcon: _buildSuffixIconDark(),
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide(color: AppColors.inputBorderIdle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide(color: AppColors.inputBorderIdle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide(color: AppColors.inputBorderFocused, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide(color: AppColors.error),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        );

      case AppTextFieldVariant.underlined:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.stone,
          ),
          prefixIcon: _buildPrefixIcon(),
          suffixIcon: _buildSuffixIcon(),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.cloud),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
        );

      case AppTextFieldVariant.search:
        return InputDecoration(
          hintText: widget.hint ?? 'Search...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.stone,
          ),
          prefixIcon: Padding(
            padding: AppSpacing.allSm,
            child: AppIcon(icon: AppPhosphorIcons.search, color: AppColors.slate, size: AppIconSize.button),
          ),
          suffixIcon: _buildSuffixIcon(),
          filled: true,
          fillColor: AppColors.sand,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        );
    }
  }
}
