import 'package:flutter/widgets.dart';

/// How options are drawn.
/// Draws the chat window while it opens (animation 0 to 1) and closes (1 to 0).
/// [origin] is the centre of the help button, relative to the window.
typedef ChatbotWindowTransition = Widget Function(Animation<double> animation, Alignment origin, Widget window);

enum ChatbotOptionShape {
  /// As wide as its text.
  pill,

  /// Full width, text on the left and a chevron on the right.
  row,

  /// Full width, text centred.
  button,
}

/// Every visual setting of the chatbot. Defaults match "Esempio 1" of the design.
class ChatbotTheme {
  const ChatbotTheme({
    this.windowColor = const Color(0xFFFFFFFF),
    this.windowBorderColor = const Color(0xFFE5E5EA),
    this.windowBorderWidth = 1,
    this.windowRadius = 14,
    this.windowShadowColor = const Color(0x1A000000),
    this.windowShadowBlur = 20,
    this.windowWidth = 240,
    this.windowHeight = 420,
    this.headerColor = const Color(0xFFFFFFFF),
    this.headerTitleColor = const Color(0xFF1C1C1E),
    this.headerCloseColor = const Color(0xFF8E8E93),
    this.headerTitleSize = 14,
    this.title = 'Assistente',
    this.messageGap = 8,
    this.messagePadding = 12,
    this.assistantBubbleColor = const Color(0xFFF2F2F7),
    this.assistantTextColor = const Color(0xFF1C1C1E),
    this.userBubbleColor = const Color(0xFF1E88E5),
    this.userTextColor = const Color(0xFFFFFFFF),
    this.bubbleRadius = 12,
    this.bubbleTailRadius = 4,
    this.streamCharDuration = const Duration(milliseconds: 20),
    this.openDuration = const Duration(milliseconds: 250),
    this.openCurve = Curves.easeOutCubic,
    this.closeCurve = Curves.easeInCubic,
    this.windowTransition,
    this.optionShape = ChatbotOptionShape.pill,
    this.optionColor = const Color(0xFFFFFFFF),
    this.optionBorderColor = const Color(0xFFB3D4F5),
    this.optionBorderWidth = 1,
    this.optionTextColor = const Color(0xFF1E88E5),
    this.optionRadius = 999,
    this.optionPaddingH = 12,
    this.optionPaddingV = 6,
    this.helpButtonColor = const Color(0xFF1E88E5),
    this.helpIconColor = const Color(0xFFFFFFFF),
    this.helpButtonRadius = 22,
    this.helpButtonSize = 44,
    this.helpIcon = '?',
    this.highlightColor = const Color(0xFF1E88E5),
    this.highlightWidth = 2,
    this.highlightRadius = 8,
    this.fontFamily,
    this.regularWeight = FontWeight.w400,
    this.strongWeight = FontWeight.w600,
    this.textSize = 12,
  });

  final Color windowColor;
  final Color windowBorderColor;
  final double windowBorderWidth;
  final double windowRadius;
  final Color windowShadowColor;
  final double windowShadowBlur;
  final double windowWidth;
  final double windowHeight;

  final Color headerColor;
  final Color headerTitleColor;
  final Color headerCloseColor;
  final double headerTitleSize;
  final String title;

  final double messageGap;
  final double messagePadding;

  final Color assistantBubbleColor;
  final Color assistantTextColor;
  final Color userBubbleColor;
  final Color userTextColor;
  final double bubbleRadius;
  final double bubbleTailRadius;

  /// Time per character while an assistant message is typed out. [Duration.zero] shows it at once.
  final Duration streamCharDuration;

  /// Time the window takes to open or close. [Duration.zero] turns the animation off.
  final Duration openDuration;
  final Curve openCurve;
  final Curve closeCurve;

  /// `null`: the window grows out of the help button and fades in.
  final ChatbotWindowTransition? windowTransition;

  final ChatbotOptionShape optionShape;
  final Color optionColor;
  final Color optionBorderColor;
  final double optionBorderWidth;
  final Color optionTextColor;
  final double optionRadius;
  final double optionPaddingH;
  final double optionPaddingV;

  final Color helpButtonColor;
  final Color helpIconColor;
  final double helpButtonRadius;
  final double helpButtonSize;

  /// Text shown on the help button while the chat is closed.
  final String helpIcon;

  final Color highlightColor;
  final double highlightWidth;
  final double highlightRadius;

  /// `null` uses the app's default font.
  final String? fontFamily;
  final FontWeight regularWeight;
  final FontWeight strongWeight;
  final double textSize;

  TextStyle text(Color color, {bool strong = false, double? size}) => TextStyle(
        color: color,
        fontFamily: fontFamily,
        fontWeight: strong ? strongWeight : regularWeight,
        fontSize: size ?? textSize,
        height: 1.4,
      );
}
