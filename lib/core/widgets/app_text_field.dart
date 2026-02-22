import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/app_icons.dart';
import 'app_icon.dart';

enum AppTextFieldVariant {
  /// Outlined border style (default)
  outlined,

  /// Filled background style
  filled,

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
  final String? prefixSvgPath;
  final IconData? suffixIcon;
  final String? suffixSvgPath;
  final VoidCallback? onSuffixIconTap;

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
    this.prefixSvgPath,
    this.suffixIcon,
    this.suffixSvgPath,
    this.onSuffixIconTap,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
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
    _focusNode.dispose();
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
              color: Colors.white,
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
          style: AppTypography.bodyMedium,
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
          prefixIcon: widget.prefixSvgPath != null
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: AppIcon(assetPath: widget.prefixSvgPath!, color: AppColors.slate, size: 20),
                )
              : widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.slate)
                  : null,
          suffixIcon: widget.suffixSvgPath != null
              ? IconButton(
                  icon: AppIcon(assetPath: widget.suffixSvgPath!, color: AppColors.slate, size: 20),
                  onPressed: widget.onSuffixIconTap,
                )
              : widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(widget.suffixIcon, color: AppColors.slate),
                      onPressed: widget.onSuffixIconTap,
                    )
                  : null,
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
          prefixIcon: widget.prefixSvgPath != null
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: AppIcon(assetPath: widget.prefixSvgPath!, color: AppColors.slate, size: 20),
                )
              : widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.slate)
                  : null,
          suffixIcon: widget.suffixSvgPath != null
              ? IconButton(
                  icon: AppIcon(assetPath: widget.suffixSvgPath!, color: AppColors.slate, size: 20),
                  onPressed: widget.onSuffixIconTap,
                )
              : widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(widget.suffixIcon, color: AppColors.slate),
                      onPressed: widget.onSuffixIconTap,
                    )
                  : null,
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

      case AppTextFieldVariant.underlined:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.stone,
          ),
          prefixIcon: widget.prefixSvgPath != null
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: AppIcon(assetPath: widget.prefixSvgPath!, color: AppColors.slate, size: 20),
                )
              : widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.slate)
                  : null,
          suffixIcon: widget.suffixSvgPath != null
              ? IconButton(
                  icon: AppIcon(assetPath: widget.suffixSvgPath!, color: AppColors.slate, size: 20),
                  onPressed: widget.onSuffixIconTap,
                )
              : widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(widget.suffixIcon, color: AppColors.slate),
                      onPressed: widget.onSuffixIconTap,
                    )
                  : null,
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
          prefixIcon: Icon(Icons.search, color: AppColors.slate),
          suffixIcon: widget.suffixSvgPath != null
              ? IconButton(
                  icon: AppIcon(assetPath: widget.suffixSvgPath!, color: AppColors.slate, size: 20),
                  onPressed: widget.onSuffixIconTap,
                )
              : widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(widget.suffixIcon, color: AppColors.slate),
                      onPressed: widget.onSuffixIconTap,
                    )
                  : null,
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
