import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// Windows 11 风格桌面设计系统（扁平卡片 · 浅灰底 · 系统蓝）
/// 类名沿用旧版（Ios*/Glass*），所有页面无需改调用即可换肤。
/// ============================================================
class Ios {
  // ---- 品牌色（Windows 11 系统强调色）----
  static const blue = Color(0xFF0067C0);
  static const blueDark = Color(0xFF005A9E);
  static const blueLight = Color(0xFF3B8FD9);
  static const blueBg = Color(0xFFE8F1FB);
  static const purple = Color(0xFF6B5BD2);
  static const green = Color(0xFF0F7B0F);
  static const greenBg = Color(0xFFE6F4E6);
  static const orange = Color(0xFFF6821F); // Cloudflare 橙
  static const red = Color(0xFFC42B1C);
  static const teal = Color(0xFF038387);

  static const text = Color(0xFF1A1A1A);
  static const gray = Color(0xFF6B6B6B);
  static const grayDark = Color(0xFF9A9A9A);
  static const mute = Color(0xFF9A9A9A);

  // ---- 背景 ----
  static const bgStart = Color(0xFFF3F3F3);
  static const bgEnd = Color(0xFFF3F3F3);
  static const bgMid = Color(0xFFF3F3F3);

  // ---- 卡片 ----
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE5E5E5);
  static const cardShadow = Color(0x08000000);
  static const glassGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  );

  // ---- 侧栏 ----
  static const sidebar = Color(0xFFF7F7F7);
  static const sidebarBorder = Color(0xFFE5E5E5);
  static const sidebarText = Color(0xFF1A1A1A);
  static const sidebarTextDim = Color(0xFF5F5F5F);

  // ---- 暗色模式 ----
  static const bgDark = Color(0xFF202020);
  static const cardDark = Color(0xFF2B2B2B);
  static const cardBorderDark = Color(0x1AFFFFFF);
  static const cardShadowDark = Color(0x33000000);

  // ---- 分隔线 / 填充 ----
  static const sep = Color(0xFFEFEFEF);
  static const sepDark = Color(0x1AFFFFFF);
  static const fill = Color(0xFFF5F5F5);
  static const fillDark = Color(0x14FFFFFF);

  static const radius = 8.0;
  static const inputRadius = 5.0;
  static const cardPadding = 14.0;

  // ---- 字体 ----
  static const fontFamily = 'Inter';
  static const fontFallback = <String>[
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Segoe UI',
    'PingFang SC',
  ];
  static const monoFamily = 'JetBrains Mono';

  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
  );

  static const primaryGradient = LinearGradient(colors: [blue, blue]);
  static const glowGradient = LinearGradient(colors: [blue, blue]);

  static bool isLight(BuildContext c) =>
      Theme.of(c).brightness == Brightness.light;
  static Color cardOf(BuildContext c) => isLight(c) ? card : cardDark;
  static Color borderOf(BuildContext c) =>
      isLight(c) ? cardBorder : cardBorderDark;
  static Color sepOf(BuildContext c) => isLight(c) ? sep : sepDark;
}

/// 全局背景：纯色浅灰
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Ios.isLight(context) ? Ios.bgStart : Ios.bgDark,
      child: child,
    );
  }
}

/// 卡片容器（白底 + 1px 描边 + 8px 圆角）
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
    this.blur = 0,
    this.margin,
    this.color,
    this.gradient,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Ios.cardOf(context)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Ios.borderOf(context)),
        boxShadow: boxShadow ?? const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

/// 悬停效果（桌面软件只做轻微变化，不再缩放）
class CfHoverLift extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const CfHoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.0,
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _hover && widget.onTap != null ? 0.92 : 1,
          child: widget.child,
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
    final onSurface = isLight ? Ios.text : Colors.white;

    final scheme = ColorScheme(
      brightness: b,
      primary: Ios.blue,
      onPrimary: Colors.white,
      secondary: Ios.blue,
      onSecondary: Colors.white,
      error: Ios.red,
      onError: Colors.white,
      surface: isLight ? Colors.white : Ios.cardDark,
      onSurface: onSurface,
      surfaceContainerHighest: isLight ? Ios.fill : Ios.fillDark,
    );

    final base = TextStyle(
      fontFamily: Ios.fontFamily,
      fontFamilyFallback: Ios.fontFallback,
      color: onSurface,
      height: 1.4,
      letterSpacing: 0,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Ios.inputRadius),
      borderSide:
          BorderSide(color: isLight ? const Color(0xFFD6D6D6) : Ios.cardBorderDark),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: Ios.fontFamily,
      fontFamilyFallback: Ios.fontFallback,
      splashFactory: NoSplash.splashFactory,
      hoverColor: isLight ? const Color(0x0A000000) : const Color(0x0FFFFFFF),
      highlightColor: Colors.transparent,
      shadowColor: Ios.cardShadow,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      visualDensity: VisualDensity.compact,
      textTheme: TextTheme(
        displaySmall: base.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium:
            base.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: base.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
        bodyMedium: base.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: base.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isLight ? Ios.gray : Ios.grayDark),
        labelLarge: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 48,
        titleTextStyle: base.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? Ios.sep : Ios.sepDark,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0x14FFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        hintStyle: base.copyWith(fontSize: 13, color: Ios.mute),
        labelStyle: base.copyWith(fontSize: 13, color: Ios.gray),
        floatingLabelStyle: base.copyWith(fontSize: 12.5, color: Ios.blue),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Ios.inputRadius),
          borderSide: const BorderSide(color: Ios.blue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Ios.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 34),
          textStyle: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Ios.inputRadius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          backgroundColor: isLight ? const Color(0xFFFBFBFB) : Ios.fillDark,
          minimumSize: const Size(64, 34),
          side: BorderSide(
              color: isLight ? const Color(0xFFDDDDDD) : Ios.cardBorderDark),
          textStyle: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Ios.inputRadius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Ios.blue,
          textStyle: base.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Ios.inputRadius)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : Ios.gray),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Ios.blue : Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: base.copyWith(fontSize: 12, color: Colors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B2B2B),
        contentTextStyle: base.copyWith(fontSize: 13, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        width: 420,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : Ios.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? Colors.white : Ios.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
              color: isLight ? Ios.cardBorder : Ios.cardBorderDark),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStateProperty.all(
            isLight ? const Color(0x33000000) : const Color(0x33FFFFFF)),
      ),
    );
  }
}

/// 分组卡片（行之间 1px 分隔线）
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
    final sepColor = Ios.sepOf(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Container(height: 1, color: sepColor));
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
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Ios.gray,
        ),
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
    final isLight = Ios.isLight(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isLight ? Ios.mute : Ios.grayDark,
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
                  fontWeight: FontWeight.w600,
                  color: Ios.green,
                ),
              ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            if (chevron)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child: Icon(Icons.chevron_right, size: 18, color: Ios.mute),
              ),
          ],
        ),
      ),
    );
  }
}

/// 淡色底图标块
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// 页面顶栏主操作按钮
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: CfButton(label: label, icon: icon, onPressed: onPressed, primary: true),
    );
  }
}

/// 紧凑按钮（Windows 11 风格）
class CfButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  const CfButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 15), const SizedBox(width: 6)],
        Text(label),
      ],
    );
    if (primary || danger) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: danger ? Ios.red : Ios.blue,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: onPressed,
        child: child,
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      onPressed: onPressed,
      child: child,
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
    final child = busy
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: secondary ? Ios.blue : Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 38,
      child: secondary
          ? OutlinedButton(onPressed: busy ? null : onPressed, child: child)
          : FilledButton(onPressed: busy ? null : onPressed, child: child),
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
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Ios.red, size: 28),
            const SizedBox(height: 8),
            Text('$e',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Ios.gray)),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// 数据工作台组件
/// ============================================================

/// 标签（方角小标签，类似「完成」「记录」）
class CfPill extends StatelessWidget {
  final String text;
  final Color color;
  const CfPill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 状态小圆点
class CfDot extends StatelessWidget {
  final Color color;
  final double size;
  const CfDot(this.color, {super.key, this.size = 6});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// 页面标题 + 副说明 + 右侧操作
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
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
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Ios.gray, height: 1.4),
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

/// 数据卡片：标题行（标题 + 副标题 + 右侧操作）+ 内容
class CfCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const CfCard({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 11.5, color: Ios.gray)),
                      ],
                    ],
                  ),
                ),
                for (final a in actions) ...[const SizedBox(width: 8), a],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// 顶部数据卡（库存估值 / 在线账号 那种）
class CfStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String sub;
  final Color? dot;
  final VoidCallback? onTap;
  const CfStatTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    required this.sub,
    this.dot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CfHoverLift(
      onTap: onTap,
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Ios.gray)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  if (suffix != null)
                    Text(' $suffix',
                        style:
                            const TextStyle(fontSize: 12.5, color: Ios.mute)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (dot != null) ...[CfDot(dot!), const SizedBox(width: 5)],
                  Expanded(
                    child: Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 11.5, color: Ios.mute)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 数据表格（白卡 + 浅灰表头 + 悬停行）
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
    final isLight = Ios.isLight(context);
    final lineColor = Ios.sepOf(context);

    return GlassPanel(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            color: isLight ? const Color(0xFFFAFAFA) : const Color(0x0AFFFFFF),
            child: Row(
              children: [
                for (final c in columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Ios.gray,
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
              lineColor: lineColor,
              child: Row(
                children: [for (final c in rows[r]) Expanded(child: c)],
              ),
            ),
        ],
      ),
    );
  }

  static Widget cellOf(Widget child, {EdgeInsetsGeometry? padding}) => Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
      );
}

class _HoverRow extends StatefulWidget {
  final Color lineColor;
  final Widget child;
  const _HoverRow({required this.lineColor, required this.child});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Ios.isLight(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hover
              ? (isLight ? const Color(0xFFF7F7F7) : const Color(0x0FFFFFFF))
              : Colors.transparent,
          border: Border(top: BorderSide(color: widget.lineColor)),
        ),
        child: widget.child,
      ),
    );
  }
}

/// 统一弹窗
class CfDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool confirmEnabled;
  final bool confirmDanger;
  final double maxWidth;
  const CfDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.confirmLabel = '确定',
    this.cancelLabel = '取消',
    this.onConfirm,
    this.confirmEnabled = true,
    this.confirmDanger = false,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Ios.isLight(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassPanel(
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 12)),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 12.5, color: Ios.gray, height: 1.45)),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  child: SingleChildScrollView(child: child),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF3F3F3) : const Color(0x0AFFFFFF),
                  border: Border(top: BorderSide(color: Ios.borderOf(context))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor:
                                  confirmDanger ? Ios.red : Ios.blue),
                          onPressed: (confirmEnabled && onConfirm != null)
                              ? onConfirm
                              : null,
                          child: Text(confirmLabel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(cancelLabel),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showCfDialog<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  bool confirmEnabled = true,
  bool confirmDanger = false,
  double maxWidth = 480,
  T? confirmValue,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x4D000000),
    builder: (ctx) => CfDialog(
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmEnabled: confirmEnabled,
      confirmDanger: confirmDanger,
      maxWidth: maxWidth,
      onConfirm: () => Navigator.pop(ctx, confirmValue),
      child: child,
    ),
  );
}

/// 空状态（「暂无成交记录」那种）
class CfEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final Widget? action;
  const CfEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Ios.mute),
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(hint,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, color: Ios.gray, height: 1.5)),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
