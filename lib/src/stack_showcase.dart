/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../showcaseview.dart';
import 'extension.dart';
import 'get_position.dart';
import 'shape_clipper.dart';
import 'tooltip_widget.dart';

class StackShowcase extends StatefulWidget {
  /// A key that is unique across the entire app.
  ///
  /// This Key will be used to control state of individual showcase and also
  /// used in [ShowCaseWidgetState.startShowCase] to define position of current
  /// target widget while showcasing.

  /// Target widget that will be showcased or highlighted
  final Widget child;

  /// Represents subject line of target widget
  final String? title;

  /// Title alignment with in tooltip widget
  ///
  /// Defaults to [TextAlign.start]
  final TextAlign titleAlignment;

  /// Represents summary description of target widget
  final String? description;

  /// ShapeBorder of the highlighted box when target widget will be showcased.
  ///
  /// Note: If [targetBorderRadius] is specified, this parameter will be ignored.
  ///
  /// Default value is:
  /// ```dart
  /// RoundedRectangleBorder(
  ///   borderRadius: BorderRadius.all(Radius.circular(8)),
  /// ),
  /// ```
  final ShapeBorder targetShapeBorder;

  /// Radius of rectangle box while target widget is being showcased.
  final BorderRadius? targetBorderRadius;

  /// TextStyle for default tooltip title
  final TextStyle? titleTextStyle;

  /// TextStyle for default tooltip description
  final TextStyle? descTextStyle;

  /// Empty space around tooltip content.
  ///
  /// Default Value for [Showcase] widget is:
  /// ```dart
  /// EdgeInsets.symmetric(vertical: 8, horizontal: 8)
  /// ```
  final EdgeInsets tooltipPadding;

  /// Background color of overlay during showcase.
  ///
  /// Default value is [Colors.black45]
  final Color overlayColor;

  /// Opacity apply on [overlayColor] (which ranges from 0.0 to 1.0)
  ///
  /// Default to 0.75
  final double overlayOpacity;

  /// Custom tooltip widget when [Showcase.withWidget] is used.
  final Widget? container;

  /// Defines background color for tooltip widget.
  ///
  /// Default to [Colors.white]
  final Color tooltipBackgroundColor;

  /// Defines text color of default tooltip when [titleTextStyle] and
  /// [descTextStyle] is not provided.
  ///
  /// Default to [Colors.black]
  final Color textColor;

  /// If [enableAutoScroll] is sets to `true`, this widget will be shown above
  /// the overlay until the target widget is visible in the viewport.
  final Widget scrollLoadingWidget;

  /// Whether the default tooltip will have arrow to point out the target widget.
  ///
  /// Default to `true`
  final bool showArrow;

  /// Height of [container]
  final double? height;

  /// Width of [container]
  final double? width;

  /// The duration of time the bouncing animation of tooltip should last.
  ///
  /// Default to [Duration(milliseconds: 2000)]
  final Duration movingAnimationDuration;

  /// Triggered when default tooltip is tapped
  final VoidCallback? onToolTipClick;

  /// Triggered when showcased target widget is tapped
  ///
  /// Note: [disposeOnTap] is required if you're using [onTargetClick]
  /// otherwise throws error
  final VoidCallback? onTargetClick;

  /// Will dispose all showcases if tapped on target widget or tooltip
  ///
  /// Note: [onTargetClick] is required if you're using [disposeOnTap]
  /// otherwise throws error
  final bool? disposeOnTap;

  /// Whether tooltip should have bouncing animation while showcasing
  ///
  /// If null value is provided,
  /// [ShowCaseWidget.disableAnimation] will be considered.
  final bool? disableMovingAnimation;

  /// Whether disabling initial scale animation for default tooltip when
  /// showcase is started and completed
  ///
  /// Default to `false`
  final bool? disableScaleAnimation;

  /// Padding around target widget
  ///
  /// Default to [EdgeInsets.zero]
  final EdgeInsets targetPadding;

  /// Triggered when target has been double tapped
  final VoidCallback? onTargetDoubleTap;

  /// Triggered when target has been long pressed.
  ///
  /// Detected when a pointer has remained in contact with the screen at the same location for a long period of time.
  final VoidCallback? onTargetLongPress;

  /// Border Radius of default tooltip
  ///
  /// Default to [BorderRadius.circular(8)]
  final BorderRadius? tooltipBorderRadius;

  /// Description alignment with in tooltip widget
  ///
  /// Defaults to [TextAlign.start]
  final TextAlign descriptionAlignment;

  /// if `disableDefaultTargetGestures` parameter is true
  /// onTargetClick, onTargetDoubleTap, onTargetLongPress and
  /// disposeOnTap parameter will not work
  ///
  /// Note: If `disableDefaultTargetGestures` is true then make sure to
  /// dismiss current showcase with `ShowCaseWidget.of(context).dismiss()`
  /// if you are navigating to other screen. This will be handled by default
  /// if `disableDefaultTargetGestures` is set to false.
  final bool disableDefaultTargetGestures;

  /// Defines blur value.
  /// This will blur the background while displaying showcase.
  ///
  /// If null value is provided,
  /// [ShowCaseWidget.blurValue] will be considered.
  ///
  final double? blurValue;

  /// A duration for animation which is going to played when
  /// tooltip comes first time in the view.
  ///
  /// Defaults to 300 ms.
  final Duration scaleAnimationDuration;

  /// The curve to be used for initial animation of tooltip.
  ///
  /// Defaults to Curves.easeIn
  final Curve scaleAnimationCurve;

  /// An alignment to origin of initial tooltip animation.
  ///
  /// Alignment will be pre-calculated but if pre-calculated
  /// alignment doesn't work then this parameter can be
  /// used to customise the direct of the tooltip animation.
  ///
  /// eg.
  /// ```dart
  ///     Alignment(-0.2,0.3) or Alignment.centerLeft
  /// ```
  final Alignment? scaleAnimationAlignment;

  final TooltipAlignment? tooltipAlignment;
  final DynamicKeys? focusedWidgetsKeys;
  final double? focusedWidgetsOverlayHorizontalShift;
  final double? focusedWidgetsOverlayVerticalShift;
  final double? tooltipTopPadding;
  final String? skipButtonText;
  final String? previousButtonText;
  final String? nextButtonText;
  final String? doneButtonText;
  final bool disableNextOnTap;
  final bool disableAutoScroll;
  final void Function()? onSkipPressed;
  final void Function()? onDonePressed;
  final bool addBorderAroundTarget;
  final Color? borderAroundTargetColor;
  final bool joinShowcaseAndFocusedWidgets;

  const StackShowcase({
    required GlobalKey<StackShowcaseState> key,
    // required this.showCaseKey,
    required this.child,
    this.title,
    this.titleAlignment = TextAlign.start,
    required this.description,
    this.descriptionAlignment = TextAlign.start,
    this.targetShapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    this.overlayColor = Colors.black45,
    this.overlayOpacity = 0.75,
    this.titleTextStyle,
    this.descTextStyle,
    this.tooltipBackgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.scrollLoadingWidget = const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white)),
    this.showArrow = true,
    this.onTargetClick,
    this.disposeOnTap,
    this.movingAnimationDuration = const Duration(milliseconds: 2000),
    this.disableMovingAnimation,
    this.disableScaleAnimation,
    this.tooltipPadding =
        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    this.onToolTipClick,
    this.targetPadding = EdgeInsets.zero,
    this.blurValue,
    this.targetBorderRadius,
    this.onTargetLongPress,
    this.onTargetDoubleTap,
    this.tooltipBorderRadius,
    this.disableDefaultTargetGestures = false,
    this.focusedWidgetsKeys,
    this.tooltipAlignment,
    this.focusedWidgetsOverlayHorizontalShift,
    this.focusedWidgetsOverlayVerticalShift,
    this.tooltipTopPadding,
    this.skipButtonText,
    this.scaleAnimationDuration = const Duration(milliseconds: 300),
    this.scaleAnimationCurve = Curves.easeIn,
    this.scaleAnimationAlignment,
    this.previousButtonText,
    this.nextButtonText,
    this.doneButtonText,
    this.disableNextOnTap = false,
    this.disableAutoScroll = false,
    this.onSkipPressed,
    this.onDonePressed,
    this.addBorderAroundTarget = false,
    this.borderAroundTargetColor,
    this.joinShowcaseAndFocusedWidgets = false,
  })  : height = null,
        width = null,
        container = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
            "overlay opacity must be between 0 and 1."),
        assert(
            onTargetClick == null
                ? true
                : (disposeOnTap == null ? false : true),
            "disposeOnTap is required if you're using onTargetClick"),
        assert(
            disposeOnTap == null
                ? true
                : (onTargetClick == null ? false : true),
            "onTargetClick is required if you're using disposeOnTap"),
        assert(
            joinShowcaseAndFocusedWidgets == false
                ? true
                : targetBorderRadius == null ||
                    targetBorderRadius == BorderRadius.zero,
            "Can't join showcase and focused widgets with target border radius"),
        super(key: key);

  const StackShowcase.withWidget({
    required GlobalKey<StackShowcaseState> key,
    // required this.showCaseKey,
    required this.child,
    required this.container,
    required this.height,
    required this.width,
    this.targetShapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    this.overlayColor = Colors.black45,
    this.targetBorderRadius,
    this.overlayOpacity = 0.75,
    this.scrollLoadingWidget = const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white)),
    this.onTargetClick,
    this.disposeOnTap,
    this.movingAnimationDuration = const Duration(milliseconds: 2000),
    this.disableMovingAnimation,
    this.targetPadding = EdgeInsets.zero,
    this.blurValue,
    this.onTargetLongPress,
    this.onTargetDoubleTap,
    this.disableDefaultTargetGestures = false,
    this.focusedWidgetsKeys,
    this.tooltipAlignment,
    this.focusedWidgetsOverlayHorizontalShift,
    this.focusedWidgetsOverlayVerticalShift,
    this.tooltipTopPadding,
    this.skipButtonText,
    this.previousButtonText,
    this.nextButtonText,
    this.doneButtonText,
    this.disableNextOnTap = false,
    this.disableAutoScroll = false,
    this.onSkipPressed,
    this.onDonePressed,
    this.addBorderAroundTarget = false,
    this.borderAroundTargetColor,
    this.joinShowcaseAndFocusedWidgets = false,
  })  : showArrow = false,
        onToolTipClick = null,
        scaleAnimationDuration = const Duration(milliseconds: 300),
        scaleAnimationCurve = Curves.decelerate,
        scaleAnimationAlignment = null,
        disableScaleAnimation = null,
        title = null,
        description = null,
        titleAlignment = TextAlign.start,
        descriptionAlignment = TextAlign.start,
        titleTextStyle = null,
        descTextStyle = null,
        tooltipBackgroundColor = Colors.white,
        textColor = Colors.black,
        tooltipBorderRadius = null,
        tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
            "overlay opacity must be between 0 and 1."),
        assert(
            joinShowcaseAndFocusedWidgets == false
                ? true
                : targetBorderRadius == null ||
                    targetBorderRadius == BorderRadius.zero,
            "Can't join showcase and focused widgets with target border radius"),
        super(key: key);

  @override
  State<StackShowcase> createState() => StackShowcaseState();
}

class StackShowcaseState extends State<StackShowcase> {
  bool _showShowCase = true;
  bool _isScrollRunning = false;
  bool _isTooltipDismissed = false;
  Timer? timer;
  GetPosition? position;

  StackShowCaseWidgetState get showCaseWidgetState =>
      StackShowCaseWidget.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    position ??= GetPosition(
      key: (widget.key as GlobalKey),
      padding: widget.targetPadding,
      screenWidth: MediaQuery.of(context).size.width,
      screenHeight: MediaQuery.of(context).size.height,
    );
    // showOverlay();
  }

  /// show overlay if there is any target widget
  ///
  // void showOverlay() {
  //   final activeStep = ShowCaseWidget.activeTargetWidget(context);
  //   setState(() {
  //     // _showShowCase = activeStep == widget.key;
  //   });

  //   if (activeStep == widget.key) {
  //     if (!widget.disableAutoScroll &&
  //         ShowCaseWidget.of(context).enableAutoScroll) {
  //       _scrollIntoView();
  //     }

  //     // if (showCaseWidgetState.autoPlay) {
  //     //   timer = Timer(
  //     //       Duration(seconds: showCaseWidgetState.autoPlayDelay.inSeconds),
  //     //       _nextIfAny);
  //     // }
  //   }
  // }

  void scrollIntoViewOld() {
    if (widget.disableAutoScroll ||
        !StackShowCaseWidget.of(context).enableAutoScroll) {
      return;
    }

    ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((timeStamp) async {
      setState(() {
        _isScrollRunning = true;
      });
      await Scrollable.ensureVisible(
        (widget.key as GlobalKey).currentContext!,
        duration: showCaseWidgetState.widget.scrollDuration,
        alignment: 0.5,
      );
      setState(() {
        _isScrollRunning = false;
      });
    });
  }

  Future<void> scrollIntoView() async {
    if (widget.disableAutoScroll ||
        !StackShowCaseWidget.of(context).enableAutoScroll) {
      return;
    }

    final completer = Completer<void>();

    _isScrollRunning = true;
    ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((timeStamp) async {
      // setState(() {

      // });
      await Scrollable.ensureVisible(
        (widget.key as GlobalKey).currentContext!,
        duration: showCaseWidgetState.widget.scrollDuration,
        alignment: 0.5,
      );
      // setState(() {
      _isScrollRunning = false;
      // });

      completer.complete();
    });

    return completer.future;
  }

  Widget? getOverlayWidget() {
    final box = context.findRenderObject() as RenderBox?;

    if (box == null) {
      return null;
    }
    return AnimatedBuilder(
      animation: ModalRoute.of(context)!.secondaryAnimation!,
      builder: (context, _) {
        final topLeft =
            box.size.topLeft(box.localToGlobal(const Offset(0.0, 0.0)));
        final bottomRight =
            box.size.bottomRight(box.localToGlobal(const Offset(0.0, 0.0)));
        Rect anchorBounds;
        anchorBounds = (topLeft.dx.isNaN ||
                topLeft.dy.isNaN ||
                bottomRight.dx.isNaN ||
                bottomRight.dy.isNaN)
            ? const Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)
            : Rect.fromLTRB(
                topLeft.dx,
                topLeft.dy,
                bottomRight.dx,
                bottomRight.dy,
              );
        final anchorCenter = box.size.center(topLeft);

        final size = MediaQuery.of(context).size;

        return buildOverlayOnTarget(
          anchorCenter,
          anchorBounds.size,
          anchorBounds,
          size,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  // Future<void> _nextIfAny() async {
  //   if (timer != null && timer!.isActive) {
  //     if (showCaseWidgetState.enableAutoPlayLock) {
  //       return;
  //     }
  //     timer!.cancel();
  //   } else if (timer != null && !timer!.isActive) {
  //     timer = null;
  //   }
  //   await _reverseAnimateTooltip();
  //   showCaseWidgetState.completed(widget.key);
  // }

  Future<void> _getOnTargetTap() async {
    if (widget.disableNextOnTap) {
      return;
    }

    if (widget.disposeOnTap == true) {
      await _reverseAnimateTooltip();
      showCaseWidgetState.dismiss();
      widget.onTargetClick!();
    } else {
      // (widget.onTargetClick ?? _nextIfAny).call();
    }
  }

  Future<void> _getOnTooltipTap() async {
    if (widget.disposeOnTap == true) {
      await _reverseAnimateTooltip();
      showCaseWidgetState.dismiss();
    }
    widget.onToolTipClick?.call();
  }

  /// Reverse animates the provided tooltip or
  /// the custom container widget.
  Future<void> _reverseAnimateTooltip() async {
    setState(() {
      _isTooltipDismissed = true;
    });
    await Future<dynamic>.delayed(widget.scaleAnimationDuration);
    _isTooltipDismissed = false;
  }

  Widget buildOverlayOnTarget(
    Offset offset,
    Size size,
    Rect rectBound,
    Size screenSize,
  ) {
    var blur = 0.0;
    if (_showShowCase) {
      blur = widget.blurValue ?? showCaseWidgetState.blurValue;
    }

    // Set blur to 0 if application is running on web and
    // provided blur is less than 0.
    blur = kIsWeb && blur < 0 ? 0 : blur;

    final routeTransitionAnimationValue =
        ModalRoute.of(context)!.secondaryAnimation!.value;

    final bool hide = _isScrollRunning ||
        routeTransitionAnimationValue - routeTransitionAnimationValue.toInt() !=
            0.0;

    Widget baseOverlay = ClipPath(
      clipper: RRectClipper(
        area: hide ? Rect.zero : rectBound,
        isCircle: widget.targetShapeBorder == const CircleBorder(),
        radius: hide ? BorderRadius.zero : widget.targetBorderRadius,
        overlayPadding: hide ? EdgeInsets.zero : widget.targetPadding,
      ),
      child: blur != 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: widget.overlayColor.withOpacity(widget.overlayOpacity),
                ),
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: widget.overlayColor.withOpacity(widget.overlayOpacity),
              ),
            ),
    );

    baseOverlay = Stack(
      children: [
        baseOverlay,
        if (!hide && widget.addBorderAroundTarget)
          Positioned(
            left: rectBound.left,
            top: rectBound.top,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 2,
                    color: widget.borderAroundTargetColor ??
                        Colors.white.withOpacity(0.5),
                  ),
                  top: BorderSide(
                    width: 2,
                    color: widget.borderAroundTargetColor ??
                        Colors.white.withOpacity(0.5),
                  ),
                  right: BorderSide(
                    width: 2,
                    color: widget.borderAroundTargetColor ??
                        Colors.white.withOpacity(0.5),
                  ),
                  bottom: widget.joinShowcaseAndFocusedWidgets
                      ? BorderSide.none
                      : BorderSide(
                          width: 2,
                          color: widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                ),
                borderRadius: widget.joinShowcaseAndFocusedWidgets
                    ? null
                    : widget.targetBorderRadius,
              ),
              width: rectBound.width,
              height: rectBound.height + widget.targetPadding.vertical,
            ),
          ),
      ],
    );

    final focusedWidgetsPointerAbsorber = <Widget>[];

    if (widget.focusedWidgetsKeys != null) {
      final allKeys = widget.focusedWidgetsKeys!.getAllKeys();

      for (int i = 0; i < allKeys.length; i++) {
        final otherContext = allKeys[i].currentContext;

        if (otherContext != null) {
          final box = otherContext.findRenderObject() as RenderBox;
          final topLeft =
              box.size.topLeft(box.localToGlobal(const Offset(0.0, 0.0)));
          final bottomRight =
              box.size.bottomRight(box.localToGlobal(const Offset(0.0, 0.0)));
          Rect anchorBounds;
          anchorBounds = (topLeft.dx.isNaN ||
                  topLeft.dy.isNaN ||
                  bottomRight.dx.isNaN ||
                  bottomRight.dy.isNaN)
              ? const Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)
              : Rect.fromLTRB(
                  topLeft.dx -
                      (widget.focusedWidgetsOverlayHorizontalShift ?? 0),
                  topLeft.dy - (widget.focusedWidgetsOverlayVerticalShift ?? 0),
                  bottomRight.dx +
                      (widget.focusedWidgetsOverlayHorizontalShift ?? 0),
                  bottomRight.dy +
                      (widget.focusedWidgetsOverlayVerticalShift ?? 0),
                );

          baseOverlay = Stack(
            children: [
              ClipPath(
                clipper: RRectClipper(
                  area: hide ? Rect.zero : anchorBounds,
                  isCircle: widget.targetShapeBorder == const CircleBorder(),
                  radius: hide ? BorderRadius.zero : widget.targetBorderRadius,
                  overlayPadding: hide ? EdgeInsets.zero : widget.targetPadding,
                ),
                child: baseOverlay,
              ),
              if (!hide && widget.addBorderAroundTarget)
                Positioned(
                  left: anchorBounds.left,
                  top: anchorBounds.top,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 2,
                          color: widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                        bottom: BorderSide(
                          width: 2,
                          color: widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                        right: BorderSide(
                          width: 2,
                          color: widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                        top: widget.joinShowcaseAndFocusedWidgets
                            ? BorderSide.none
                            : BorderSide(
                                width: 2,
                                color: widget.borderAroundTargetColor ??
                                    Colors.white.withOpacity(0.5),
                              ),
                      ),
                      borderRadius: widget.joinShowcaseAndFocusedWidgets
                          ? null
                          : widget.targetBorderRadius,
                    ),
                    width: anchorBounds.width,
                    height: anchorBounds.height,
                  ),
                ),
            ],
          );

          focusedWidgetsPointerAbsorber.add(
            _TargetWidget(
              offset: box.size.center(topLeft),
              size: anchorBounds.size,
              onTap: _getOnTargetTap,
              radius: widget.targetBorderRadius,
              onDoubleTap: widget.onTargetDoubleTap,
              onLongPress: widget.onTargetLongPress,
              shapeBorder: widget.targetShapeBorder,
              disableDefaultChildGestures: widget.disableDefaultTargetGestures,
            ),
          );
        }
      }
    }

    return _showShowCase
        ? Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (!showCaseWidgetState.disableBarrierInteraction) {
                    // _nextIfAny();
                  }
                },
                child: baseOverlay,
              ),
              if (hide) Center(child: widget.scrollLoadingWidget),
              if (!hide) ...[
                _TargetWidget(
                  offset: offset,
                  size: size,
                  onTap: _getOnTargetTap,
                  radius: widget.targetBorderRadius,
                  onDoubleTap: widget.onTargetDoubleTap,
                  onLongPress: widget.onTargetLongPress,
                  shapeBorder: widget.targetShapeBorder,
                  disableDefaultChildGestures:
                      widget.disableDefaultTargetGestures,
                ),
                ...focusedWidgetsPointerAbsorber,
              ],
              if (!hide)
                ToolTipWidget(
                  position: position,
                  offset: offset,
                  screenSize: screenSize,
                  title: widget.title,
                  titleAlignment: widget.titleAlignment,
                  description: widget.description,
                  descriptionAlignment: widget.descriptionAlignment,
                  titleTextStyle: widget.titleTextStyle,
                  descTextStyle: widget.descTextStyle,
                  container: widget.container,
                  tooltipBackgroundColor: widget.tooltipBackgroundColor,
                  textColor: widget.textColor,
                  showArrow: widget.showArrow,
                  contentHeight: widget.height,
                  contentWidth: widget.width,
                  onTooltipTap: _getOnTooltipTap,
                  tooltipPadding: widget.tooltipPadding,
                  disableMovingAnimation: widget.disableMovingAnimation ??
                      showCaseWidgetState.disableMovingAnimation,
                  disableScaleAnimation: widget.disableScaleAnimation ??
                      showCaseWidgetState.disableScaleAnimation,
                  movingAnimationDuration: widget.movingAnimationDuration,
                  tooltipBorderRadius: widget.tooltipBorderRadius,
                  scaleAnimationDuration: widget.scaleAnimationDuration,
                  scaleAnimationCurve: widget.scaleAnimationCurve,
                  scaleAnimationAlignment: widget.scaleAnimationAlignment,
                  isTooltipDismissed: _isTooltipDismissed,
                  tooltipAlignment: widget.tooltipAlignment,
                  topPadding: widget.tooltipTopPadding,
                  showPreviousButton: showCaseWidgetState.canGoToPrevious(),
                  onNextPressed: () {
                    if (showCaseWidgetState.isLastItem()) {
                      widget.onDonePressed?.call();
                    }
                    showCaseWidgetState.next();
                  },
                  onPreviousPressed: () => showCaseWidgetState.previous(),
                  previousButtonText: widget.previousButtonText,
                  nextButtonText: showCaseWidgetState.isLastItem()
                      ? widget.doneButtonText
                      : widget.nextButtonText,
                ),
              if (widget.skipButtonText != null &&
                  !showCaseWidgetState.isLastItem())
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).viewPadding.bottom + 16,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        showCaseWidgetState.dismiss();
                        widget.onSkipPressed?.call();
                      },
                      child: Text(widget.skipButtonText!),
                    ),
                  ),
                ),
            ],
          )
        : const SizedBox.shrink();
  }
}

class _TargetWidget extends StatelessWidget {
  final Offset offset;
  final Size? size;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final ShapeBorder? shapeBorder;
  final BorderRadius? radius;
  final bool disableDefaultChildGestures;

  const _TargetWidget({
    Key? key,
    required this.offset,
    this.size,
    this.onTap,
    this.shapeBorder,
    this.radius,
    this.onDoubleTap,
    this.onLongPress,
    this.disableDefaultChildGestures = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: disableDefaultChildGestures
          ? IgnorePointer(
              child: _targetWidgetLayer(),
            )
          : _targetWidgetLayer(),
    );
  }

  Widget _targetWidgetLayer() {
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        child: Container(
          height: size!.height + 16,
          width: size!.width + 16,
          decoration: ShapeDecoration(
            shape: radius != null
                ? RoundedRectangleBorder(borderRadius: radius!)
                : shapeBorder ??
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
