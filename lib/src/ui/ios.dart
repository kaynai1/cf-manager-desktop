import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// 现代玻璃拟态设计系统（Glassmorphism / 2026 Desktop）
/// 蓝白柔和渐变 + 磨砂半透明卡片 + 深色磨砂侧栏
/// ============================================================
class Ios {
  // ---- 品牌色 ----
  static const blue = Color(0xFF3B6EF5); // 主蓝
  static const blueDark = Color(0xFF2B56D4);
  static const blueLight = Color(0xFF5B8DEF);
  static const purple = Color(0xFF7C5CFF); // 蓝紫（选中发光）
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF6821F); // Cloudflare 橙
  static const red = Color(0xFFEF4444);
  static const teal = Color(0xFF14B8A6);

  static const gray = Color(0xFF7A8699);
  static const grayDark = Color(0xFF9AA6B8);

  // ---- 背景（#F4F7FF → #DFE7FF 对角渐变）----
  static const bgStart = Color(0xFFF4F7FF);
  static const bgEnd = Color(0xFFDFE7FF);
  static const bgMid = Color(0xFFEDF2FF);

  // ---- 玻璃卡片 ----
  static const card = Color(0xB3FFFFFF); // 70% 白
  static const cardBorder = Color(0x8CFFFFFF); // 白描边
  static const cardShadow = Color(0x1A3B5BDB); // 轻盈蓝影
  static const glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCCFFFFFF), Color(0x99FFFFFF)],
  );

  // ---- 深色磨砂侧栏 rgba(15,23,42,0.75) ----
  static const sidebar = Color(0xBF0F172A);
  static const sidebarBorder = Color(0x1FFFFFFF);
  static const sidebarText = Color(0xFFE2E8F0);
  static const sidebarTextDim = Color(0xFF94A3B8);

  // ---- 暗色模式 ----
  static const bgDark = Color(0xFF0B1220);
  static const cardDark = Color(0xCC16202F);
  static const cardBorderDark = Color(0x1FFFFFFF);
  static const cardShadowDark = Color(0x40000000);

  // ---- 分隔线 / 填充 ----
  static const sep = Color(0x140F172A);
  static const sepDark = Color(0x1FFFFFFF);
  static const fill = Color(0x66FFFFFF);
  static const fillDark = Color(0x14FFFFFF);

  static const radius = 16.0; // 卡片圆角 16
  static const inputRadius = 8.0; // 输入框圆角 8
  static const cardPadding = 16.0;

  // ---- 字体 ----
  static const fontFamily = 'Inter';
  static const fontFallback = <String>[
    'PingFang SC',
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Segoe UI',
  ];
  static const monoFamily = 'JetBrains Mono';

  /// 等宽数字/ID 样式（IP、AS 号、ID、含 / 或数字序列的字段）
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
  );

  /// 主按钮渐变蓝
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B8DEF), Color(0xFF3B6EF5)],
  );

  /// 蓝紫发光渐变（选中态）
  static const glowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, purple],
  );
}

/// 全局背景：对角渐变 + 虚化圆形光斑
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Stack(
      children: [
        // 底层对角渐变
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [Ios.bgStart, Ios.bgMid, Ios.bgEnd]
                    : [const Color(0xFF0B1220), const Color(0xFF101A30)],
              ),
            ),
          ),
        ),
        // 装饰光斑（虚化圆形）
        if (isLight) ...[
          Positioned(
            top: -120,
            left: -80,
            child: _Blob(size: 380, color: Ios.blue.withValues(alpha: 0.16)),
          ),
          Positioned(
            bottom: -160,
            right: -100,
            child: _Blob(size: 440, color: Ios.purple.withValues(alpha: 0.13)),
          ),
          Positioned(
            top: 220,
            right: 120,
            child: _Blob(size: 220, color: Ios.teal.withValues(alpha: 0.10)),
          ),
        ],
        child,
      ],
    );
  }
}

/// 虚化圆形光斑
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// 玻璃面板基础容器（磨砂 + 描边 + 轻投影）
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = Ios.radius,
    this.blur = 20,
    this.margin,
    this.color,
    this.gradient,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? (isLight ? Ios.card : Ios.cardDark))
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ??
              (isLight ? Ios.cardBorder : Ios.cardBorderDark),
          width: 1,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isLight ? Ios.cardShadow : Ios.cardShadowDark,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        ),
      ),
    );
  }
}

/// 微动效：悬停抬升 + 轻微缩放
class CfHoverLift extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const CfHoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.015,
  });

  @override
  State<CfHoverLift> createState() => _CfHoverLiftState();
}

class _CfHoverLiftState extends State<CfHoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
          child: GestureDetector(
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class IosTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final onSurface = isLight ? const Color(0xFF0F172A) : Colors.white;

    final scheme = ColorScheme(
      brightness: b,
      primary: Ios.blue,
      onPrimary: Colors.white,
      secondary: Ios.purple,
      onSecondary: Colors.white,
      error: Ios.red,
      onError: Colors.white,
      surface: isLight ? const Color(0xFFF8FAFF) : Ios.cardDark,
      onSurface: onSurface,
      surfaceContainerHighest: isLight ? Ios.fill : Ios.fillDark,
    );

    // 统一字体：Inter + 中文 PingFang SC / 微软雅黑 回退
    const base = TextStyle(
      fontFamily: Ios.fontFamily,
      fontFamilyFallback: Ios.fontFallback,
      color: Color(0xFF0F172A),
      height: 1.45,
      letterSpacing: 0,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: Ios.fontFamily,
      fontFamilyFallback: Ios.fontFallback,
      splashFactory: NoSplash.splashFactory,
      shadowColor: Ios.cardShadow,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      // 文本层级：正文 14/400，标题 16/600，侧栏 15/500，按钮 14/600
      textTheme: TextTheme(
        displaySmall: base.copyWith(
            fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: base.copyWith(
            fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: base.copyWith(
            fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: base.copyWith(
            fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
        titleSmall: base.copyWith(
            fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
        bodyLarge: base.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: base.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: isLight ? Ios.gray : Ios.grayDark),
        labelLarge: base.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3),
        labelMedium: base.copyWith(
            fontSize: 12.5, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? Ios.sep : Ios.sepDark,
        thickness: 1,
        space: 1,
      ),
      // 输入框：圆角 8，聚焦蓝光描边
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isLight ? const Color(0x99FFFFFF) : const Color(0x14FFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: base.copyWith(fontSize: 14, color: Ios.gray),
        labelStyle: base.copyWith(fontSize: 14, color: Ios.gray),
        floatingLabelStyle:
            base.copyWith(fontSize: 13, color: Ios.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Ios.inputRadius),
          borderSide: BorderSide(
              color: isLight ? const Color(0x1F0F172A) : Ios.cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Ios.inputRadius),
          borderSide: BorderSide(
              color: isLight ? const Color(0x1F0F172A) : Ios.cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Ios.inputRadius),
          borderSide: const BorderSide(color: Ios.blue, width: 1.6),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStateProperty.all(
            isLight ? const Color(0x330F172A) : const Color(0x33FFFFFF)),
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
          padding: EdgeInsetsDirectional.only(start: padding.horizontal),
          child: Container(height: 1, color: sepColor),
        ));
      }
      rows.add(Padding(padding: padding, child: children[i]));
    }
    if (rows.isEmpty) rows.add(Padding(padding: padding));
    return GlassPanel(
      margin: margin,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class IosSectionHeader extends StatelessWidget {
  final String text;
  const IosSectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 22, 24, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              gradient: Ios.glowGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Ios.gray,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      fontSize: 14,
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
                        fontSize: 12.5,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Ios.blue,
                ),
              ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            if (chevron)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child: Icon(Icons.chevron_right, size: 18, color: Ios.gray),
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
    this.size = 34,
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
          colors: [color, Color.lerp(color, Colors.white, 0.22) ?? color],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

/// 页面顶栏主操作按钮（桌面软件形态，替代手机风格悬浮球）
class IosPageAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const IosPageAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: CfHoverLift(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: Ios.primaryGradient,
            borderRadius: BorderRadius.circular(Ios.inputRadius),
            boxShadow: [
              BoxShadow(
                color: Ios.blue.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Ios.inputRadius),
              onTap: onPressed,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: Ios.fontFamily,
                        fontFamilyFallback: Ios.fontFallback,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    if (secondary) {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                isLight ? const Color(0x99FFFFFF) : Ios.fillDark,
            foregroundColor: Ios.blue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Ios.inputRadius),
            ),
          ),
          onPressed: busy ? null : onPressed,
          child: child,
        ),
      );
    }

    // 主按钮：渐变蓝 + 悬停上浮
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: CfHoverLift(
        onTap: busy ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: Ios.primaryGradient,
            borderRadius: BorderRadius.circular(Ios.inputRadius),
            boxShadow: [
              BoxShadow(
                color: Ios.blue.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Ios.inputRadius),
              ),
            ),
            onPressed: busy ? null : onPressed,
            child: child,
          ),
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
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
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

/// ============================================================
/// 数据工作台组件
/// ============================================================

/// 状态药丸 / 标签胶囊（淡蓝底圆角胶囊）
class CfPill extends StatelessWidget {
  final String text;
  final Color color;
  const CfPill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

/// 页面骨架：标题 + 副说明 + 右侧操作
class CfPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const CfPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Ios.gray,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// 玻璃数据表格（磨砂 + 表头 + 悬停行）
class CfTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final Widget? emptyState;
  const CfTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final headColor =
        isLight ? const Color(0xFF5B6779) : const Color(0xFF94A3B8);
    final lineColor = isLight ? const Color(0x120F172A) : Ios.sepDark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xA6FFFFFF) : Ios.cardDark,
        borderRadius: BorderRadius.circular(Ios.radius),
        border: Border.all(
          color: isLight ? Ios.cardBorder : Ios.cardBorderDark,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? Ios.cardShadow : Ios.cardShadowDark,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Ios.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // 表头
              Container(
                color: isLight
                    ? const Color(0x66F4F7FF)
                    : const Color(0x14FFFFFF),
                child: Row(
                  children: [
                    for (final c in columns)
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: headColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (rows.isEmpty && emptyState != null) emptyState!,
              for (var r = 0; r < rows.length; r++)
                _HoverRow(
                  zebra: r % 2 == 1,
                  lineColor: lineColor,
                  child: Row(
                    children: [
                      for (final c in rows[r]) Expanded(flex: 1, child: c),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget cellOf(Widget child, {EdgeInsetsGeometry? padding}) => Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      );
}

/// 悬停高亮数据行
class _HoverRow extends StatefulWidget {
  final bool zebra;
  final Color lineColor;
  final Widget child;
  const _HoverRow({
    required this.zebra,
    required this.lineColor,
    required this.child,
  });

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        decoration: BoxDecoration(
          color: _hover
              ? (isLight
                  ? const Color(0x99EAF0FF)
                  : const Color(0x1F5B8DEF))
              : widget.zebra
                  ? (isLight
                      ? const Color(0x33F4F7FF)
                      : const Color(0x0AFFFFFF))
                  : Colors.transparent,
          border: Border(top: BorderSide(color: widget.lineColor)),
        ),
        child: widget.child,
      ),
    );
  }
}

/// 空状态
class CfEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  const CfEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Ios.blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: Ios.blue.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Ios.gray, height: 1.5),
          ),
        ],
      ),
    );
  }
}
