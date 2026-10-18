import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Ios {
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFF38020); // Cloudflare 橙
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFFAF52DE);
  static const teal = Color(0xFF30B0C7);

  static const gray = Color(0xFF8E8E93);
  static const grayDark = Color(0xFF98989E);

  static const bg = Color(0xFFF2F2F7);
  static const card = Color(0xFFFFFFFF);
  static const sep = Color(0xFFE5E5EA);
  static const fill = Color(0xFFE9E9EB);

  static const bgDark = Color(0xFF000000);
  static const cardDark = Color(0xFF1C1C1E);
  static const sepDark = Color(0xFF38383A);
  static const fillDark = Color(0xFF2C2C2E);

  static const radius = 12.0;
}

class IosTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final scheme = ColorScheme(
      brightness: b,
      primary: Ios.orange,
      onPrimary: Colors.white,
      secondary: Ios.blue,
      onSecondary: Colors.white,
      error: Ios.red,
      onError: Colors.white,
      surface: isLight ? Ios.card : Ios.cardDark,
      onSurface: isLight ? Colors.black : Colors.white,
      surfaceContainerHighest: isLight ? Ios.fill : Ios.fillDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? Ios.bg : Ios.bgDark,
      canvasColor: isLight ? Ios.bg : Ios.bgDark,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? Ios.bg : Ios.bgDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
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
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
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

class IosCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  const IosCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sepColor = isLight ? Ios.sep : Ios.sepDark;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Container(height: 0.5, color: sepColor),
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isLight ? Ios.card : Ios.cardDark,
        borderRadius: BorderRadius.circular(Ios.radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Ios.radius),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
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
      padding: const EdgeInsetsDirectional.fromSTEB(28, 20, 28, 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: isLight ? Ios.gray : Ios.grayDark),
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
                      fontSize: 15,
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
                  fontSize: 15,
                  color: isLight ? Ios.gray : Ios.grayDark,
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
    this.size = 29,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.58),
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
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          );

    if (secondary) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isLight ? Ios.fill : Ios.fillDark,
            foregroundColor: Ios.blue,
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
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Ios.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Ios.orange.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Ios.radius)),
        ),
        onPressed: busy ? null : onPressed,
        child: child,
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
