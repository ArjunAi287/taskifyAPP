import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context)? mobileBuilder;
  final Widget Function(BuildContext context)? tabletBuilder;
  final Widget Function(BuildContext context)? desktopBuilder;
  final Widget Function(BuildContext context) builder; // Fallback

  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static DeviceType getDeviceType(BuildContext context) {
    if (isDesktop(context)) return DeviceType.desktop;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          if (desktopBuilder != null) return desktopBuilder!(context);
        } else if (constraints.maxWidth >= 600) {
          if (tabletBuilder != null) return tabletBuilder!(context);
        } else {
          if (mobileBuilder != null) return mobileBuilder!(context);
        }
        return builder(context); // Fallback
      },
    );
  }
}
