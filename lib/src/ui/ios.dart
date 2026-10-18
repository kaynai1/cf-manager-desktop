import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// 现代玻璃拟态（Glassmorphism）设计系统
/// soft blue & white 渐变 + 毛玻璃半透明面板 + 圆角卡片 + 柔和阴影
/// ============================================================
class Ios {
  // 主色（深蓝主色 + Cloudflare 橙强调）
  static const blue = Color(0xFF1E6FFF);
  static const blueDark = Color(0xFF0B4FD6);
  static const green = Color(0xFF16C784);
  static const orange = Color(0xFFF6821F); // Cloudflare 橙
  static const red = Color(0xFFE5484D);
  static const purple = Color(0xFF7C5CFF);
  static const teal = Color(0xFF2CB1BC);

  static const gray = Color(0xFF7C87A0);
  static const grayDark = Color(0xFFAAB4C6);

  // 玻璃拟态用色
  static const bgStart = Color(0xFFEAF2FF); // 背景渐变起点（柔蓝）
  static const bgMid = Color(0xFFF6F9FF); // 背景渐变中间
  static const bgEnd = Color(0xFFFDFEFF); // 背景渐变终点（白）
  static const card = Color(0xE6FFFFFF); // 半透明白卡片（froasted）
  static const cardBorder = Color(0x55FFFFFF); // 卡片描边（半透明白）
  static const cardShadow = Color(0x1A6C87B8); // 柔和阴影

  static const bgDark = Color(0xFF0B1220);
  static const cardDark = Color(0xE61A2437);
  static const cardBorderDark = Color(0x33FFFFFF);
  static const cardShadowDark = Color(0x40000000);

  static const sep = Color(0x1AF0F4FF);
  static const sepDark = Color(0x33FFFFFF);
  static const fill = Color(0x26FFFFFF);
  static const fillDark = Color(0x22FFFFFF);

  static const radius = 18.0; // 大圆角
  static const cardPadding = 18.0;

  // 玻璃渐变色
  static const glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE8FFFFFF), Color(0xC0FFFFFF), Color(0x99F0F6FF)],
  );
}

/// 全局渐变背景（放在 MaterialApp.builder，所有页面自动获得）
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [Ios.bgStart, Ios.bgMid, Ios.bgEnd]
              : [Ios.bgDark, const Color(0xFF111B30), const Color(0xFF0B1220)],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}

class IosTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final scheme = ColorScheme(
      brightness: b,
      primary: Ios.blue,
      onPrimary: Colors.white,
      secondary: Ios.blue,
      onSecondary: Colors.white,
      error: Ios.red,
      onError: Colors.white,
      surface: isLight
          ? Ios.card
          : Ios.cardDark,
      onSurface: isLight ? const Color(0xFF12213B) : Colors.white,
      surfaceContainerHighest: isLight ? Ios.fill : Ios.fillDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      shadowColor: Ios.cardShadow,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? Ios.sep : Ios.sepDark,
        thickness: 0.5,
        space: 0.5,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: scheme.onSurface),
        bodySmall: TextStyle(
          fontSize: 13,
          color: isLight ? Ios.gray : Ios.grayDark,
        ),
      ),
    );
  }
}

/// 毛玻璃圆角卡片
class IosCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  const IosCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sepColor = isLight ? Ios.sep : Ios.sepDark;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: const EdgeInsetsDirectional.only(start: padding.horizontal),
          child: Container(height: 0.5, color: sepColor),
        ));
      }
      rows.add(Padding(
        padding: padding,
        child: children[i],
      ));
    }
    if (rows.isEmpty) rows.add(Padding(padding: padding));
    return _GlassCard(
      margin: margin,
      isLight: isLight,
      borderRadius: Ios.radius,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// 玻璃卡片底层容器（渐变 + 描边 + 模糊 + 阴影）
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final bool isLight;
  final double borderRadius;
  const _GlassCard({
    required this.child,
    required this.margin,
    required this.isLight,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: isLight ? Ios.glassGradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isLight ? Ios.cardBorder : Ios.cardBorderDark,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Ios.cardShadow
                : Ios.cardShadowDark,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: isLight ? Ios.card : Ios.cardDark,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class IosSectionHeader extends StatelessWidget {
  final String text;
  const IosSectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 22, 24, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Ios.blue, Ios.purple],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isLight ? Ios.gray : Ios.grayDark,
            ),
          ),
        ],
      ),
    );
  }
}

class IosRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool chevron;
  const IosRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.chevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isLight ? Ios.gray : Ios.grayDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isLight ? Ios.blue : Ios.blue,
                ),
              ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            if (chevron)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child: Icon(Icons.chevron_right, size: 20, color: Ios.gray),
              ),
          ],
        ),
      ),
    );
  }
}

class IosIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IosIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.white, 0.25) ?? color,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.56),
    );
  }
}

class IosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool busy;
  final IconData? icon;
  const IosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.busy = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final child = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          );

    if (secondary) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isLight ? Ios.fill : Ios.fillDark,
            foregroundColor: Ios.blue,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Ios.radius)),
          ),
          onPressed: busy ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Ios.orange, Color(0xFFFFA63D)],
          ),
          borderRadius: BorderRadius.circular(Ios.radius),
          boxShadow: [
            BoxShadow(
              color: Ios.orange.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Ios.radius)),
          ),
          onPressed: busy ? null : onPressed,
          child: child,
        ),
      ),
    );
  }
}

class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  const AsyncView({super.key, required this.value, required this.builder});

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Ios.red, size: 32),
            const SizedBox(height: 8),
            Text('$e', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}