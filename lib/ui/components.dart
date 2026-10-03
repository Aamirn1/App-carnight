import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Image.asset(
    NightAssets.wordmark,
    width: large ? 248 : 142,
    height: large ? 99 : 57,
    fit: BoxFit.contain,
    cacheWidth: large ? 744 : 426,
    semanticLabel: 'Cars Night',
    errorBuilder: (_, error, stack) => Text(
      'Cars Night',
      style: TextStyle(
        fontSize: large ? 40 : 24,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: NightTheme.gradient,
      borderRadius: BorderRadius.circular(28),
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// Bounded decode size, explicit aspect ratio and no network dependency.
class AssetPhoto extends StatelessWidget {
  const AssetPhoto({
    super.key,
    required this.asset,
    this.ratio = 1.65,
    this.dataSaver = false,
    this.label = 'Illustrative car photograph',
  });
  final String asset;
  final double ratio;
  final bool dataSaver;
  final String label;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: ratio,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .round()
                .clamp(240, dataSaver ? 480 : 1000)
                .toInt();
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          cacheWidth: width,
          alignment: asset == NightAssets.hero
              ? const Alignment(0, 0.4)
              : Alignment.center,
          semanticLabel: label,
          errorBuilder: (_, error, stack) => const ColoredBox(
            color: NightTheme.surface,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                semanticLabel: 'Image unavailable',
                color: NightTheme.muted,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class NightCard extends StatelessWidget {
  const NightCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: NightTheme.surface,
      border: Border.all(color: NightTheme.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: NightTheme.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: NightTheme.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off,
    this.action,
  });
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: NightTheme.cyan, size: 48),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: NightTheme.muted),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: children,
          ),
        ),
      ),
    ),
  );
}

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));

Future<void> showUnavailable(
  BuildContext context,
  String title,
  String message,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Got it'),
        ),
      ],
    ),
  ),
);

class GradientOutlineButton extends StatelessWidget {
  const GradientOutlineButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: NightTheme.gradient, borderRadius: BorderRadius.circular(28)),
    child: Padding(padding: const EdgeInsets.all(1.5), child: FilledButton(
      style: FilledButton.styleFrom(backgroundColor: NightTheme.background,
        foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
      onPressed: onPressed, child: Text(label),
    )),
  );
}
