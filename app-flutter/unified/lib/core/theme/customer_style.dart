import 'package:flutter/material.dart';

/// Optional provider overrides for the subscriber's reusable components.
@immutable
class CustomerStyle extends ThemeExtension<CustomerStyle> {
  final double radius;
  final Color border;
  final List<BoxShadow> shadows;
  final Color? quickActionsCard;
  final Color? quickActionsText;
  final Color? otherCards;
  final Color? otherCardsText;
  final Color? invoiceColor;
  final Color? actionColor;
  final Color? iconColor;

  const CustomerStyle({
    required this.radius,
    required this.border,
    this.shadows = const [],
    this.quickActionsCard,
    this.quickActionsText,
    this.otherCards,
    this.otherCardsText,
    this.invoiceColor,
    this.actionColor,
    this.iconColor,
  });

  @override
  CustomerStyle copyWith({
    double? radius,
    Color? border,
    List<BoxShadow>? shadows,
    Color? quickActionsCard,
    Color? quickActionsText,
    Color? otherCards,
    Color? otherCardsText,
    Color? invoiceColor,
    Color? actionColor,
    Color? iconColor,
  }) =>
      CustomerStyle(
        radius: radius ?? this.radius,
        border: border ?? this.border,
        shadows: shadows ?? this.shadows,
        quickActionsCard: quickActionsCard ?? this.quickActionsCard,
        quickActionsText: quickActionsText ?? this.quickActionsText,
        otherCards: otherCards ?? this.otherCards,
        otherCardsText: otherCardsText ?? this.otherCardsText,
        invoiceColor: invoiceColor ?? this.invoiceColor,
        actionColor: actionColor ?? this.actionColor,
        iconColor: iconColor ?? this.iconColor,
      );

  @override
  CustomerStyle lerp(covariant CustomerStyle? other, double t) => other == null
      ? this
      : CustomerStyle(
          radius: radius + (other.radius - radius) * t,
          border: Color.lerp(border, other.border, t)!,
          shadows: BoxShadow.lerpList(shadows, other.shadows, t)!,
          quickActionsCard:
              Color.lerp(quickActionsCard, other.quickActionsCard, t),
          quickActionsText:
              Color.lerp(quickActionsText, other.quickActionsText, t),
          otherCards: Color.lerp(otherCards, other.otherCards, t),
          otherCardsText: Color.lerp(otherCardsText, other.otherCardsText, t),
          invoiceColor: Color.lerp(invoiceColor, other.invoiceColor, t),
          actionColor: Color.lerp(actionColor, other.actionColor, t),
          iconColor: Color.lerp(iconColor, other.iconColor, t),
        );
}
