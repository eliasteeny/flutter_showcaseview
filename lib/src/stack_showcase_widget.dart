import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:showcaseview/src/shape_clipper.dart';
import 'package:showcaseview/src/tooltip_widget.dart';
import '../showcaseview.dart';
import 'extension.dart';
import 'get_position.dart';
import 'utils.dart';

class StackShowCaseWidget extends StatefulWidget {
  final Builder builder;

  /// Triggered when all the showcases are completed.
  final VoidCallback? onFinish;

  /// Triggered every time on start of each showcase.
  final Function(int?, GlobalKey)? onStart;

  /// Triggered every time on completion of each showcase
  final Function(int?, GlobalKey)? onComplete;

  /// Whether all showcases will auto sequentially start
  /// having time interval of [autoPlayDelay] .
  ///
  /// Default to `false`
  final bool autoPlay;

  /// Visibility time of current showcase when [autoplay] sets to true.
  ///
  /// Default to [Duration(seconds: 3)]
  final Duration autoPlayDelay;

  /// Whether blocking user interaction while [autoPlay] is enabled.
  ///
  /// Default to `false`
  final bool enableAutoPlayLock;

  /// Whether disabling bouncing/moving animation for all tooltips
  /// while showcasing
  ///
  /// Default to `false`
  final bool disableMovingAnimation;

  /// Whether disabling initial scale animation for all the default tooltips
  /// when showcase is started and completed
  ///
  /// Default to `false`
  final bool disableScaleAnimation;

  /// Whether disabling barrier interaction
  final bool disableBarrierInteraction;

  /// Provides time duration for auto scrolling when [enableAutoScroll] is true
  final Duration scrollDuration;

  /// Default overlay blur used by showcase. if [Showcase.blurValue]
  /// is not provided.
  ///
  /// Default value is 0.
  final double blurValue;

  /// While target widget is out viewport then
  /// whether enabling auto scroll so as to make the target widget visible.
  final bool enableAutoScroll;

  final void Function(Object error, StackTrace stackTrace) onError;

  const StackShowCaseWidget({
    required this.builder,
    this.onFinish,
    this.onStart,
    this.onComplete,
    this.autoPlay = false,
    this.autoPlayDelay = const Duration(milliseconds: 2000),
    this.enableAutoPlayLock = false,
    this.blurValue = 0,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.disableMovingAnimation = false,
    this.disableScaleAnimation = false,
    this.enableAutoScroll = false,
    this.disableBarrierInteraction = false,
    required this.onError,
  });

  static StackShowCaseWidgetState of(BuildContext context) {
    final state = context.findAncestorStateOfType<StackShowCaseWidgetState>();
    if (state != null) {
      return state;
    } else {
      throw Exception('Please provide StackShowCaseView context');
    }
  }

  @override
  StackShowCaseWidgetState createState() => StackShowCaseWidgetState();
}

class StackShowCaseWidgetState extends State<StackShowCaseWidget> {
  List<GlobalKey<StackShowcaseState>>? allKeys;
  int? currentIndex;

  late bool autoPlay;
  late bool disableMovingAnimation;
  late bool disableScaleAnimation;
  late Duration autoPlayDelay;
  late bool enableAutoPlayLock;
  late bool enableAutoScroll;
  late bool disableBarrierInteraction;
  bool _isScrolling = false;

  /// Returns value of  [ShowCaseWidget.blurValue]
  double get blurValue => widget.blurValue;

  Future<void>? Function(int)? _onScrollToCallback;

  @override
  void initState() {
    super.initState();

    _init();
  }

  @override
  void didUpdateWidget(covariant StackShowCaseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _init();
  }

  void _init() {
    autoPlayDelay = widget.autoPlayDelay;
    autoPlay = widget.autoPlay;
    disableMovingAnimation = widget.disableMovingAnimation;
    disableScaleAnimation = widget.disableScaleAnimation;
    enableAutoPlayLock = widget.enableAutoPlayLock;
    enableAutoScroll = widget.enableAutoScroll;
    disableBarrierInteraction = widget.disableBarrierInteraction;
  }

  /// The callback will be automatically removed after the showcase is done
  void registerScrollTo({required Future<void>? Function(int index) onStart}) {
    _onScrollToCallback = onStart;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  void _catchError(FutureOr<void> Function() callback) async {
    try {
      await callback();
    } catch (error, stackTrace) {
      widget.onError(error, stackTrace);
      _cleanupAfterSteps();
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Starts Showcase view from the beginning of specified list of widget ids.
  void startShowCase(List<GlobalKey<StackShowcaseState>> keys) {
    _catchError(
      () {
        if (mounted) {
          setState(() {
            allKeys = keys;

            currentIndex = 0;

            _onStart();
          });
        }
      },
    );
  }

  void _ensureVisible() async {
    _catchError(() async {
      if (currentIndex == null || allKeys == null) {
        return;
      }

      bool didScrollManually = false;

      if (_onScrollToCallback != null) {
        final scrollFuture = _onScrollToCallback!.call(currentIndex!);

        if (scrollFuture != null) {
          setState(() {
            _isScrolling = true;
          });
          await scrollFuture;
          await Future<void>.delayed(const Duration(milliseconds: 200));
          setState(() {
            _isScrolling = false;
          });
          didScrollManually = true;
        }
      }

      final currentState = allKeys![currentIndex!].currentState;

      if (currentState == null) {
        return;
      }

      final scrollFuture = scrollIntoView(
        disableScroll: didScrollManually,
        state: currentState,
      );

      setState(() {});

      await scrollFuture;

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> scrollIntoView({
    bool disableScroll = false,
    required StackShowcaseState state,
  }) async {
    if (state.widget.disableAutoScroll || !enableAutoScroll || disableScroll) {
      return;
    }

    final completer = Completer<void>();

    _isScrolling = true;
    ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((timeStamp) async {
      // setState(() {

      // });

      await Scrollable.ensureVisible(
        allKeys![currentIndex!].currentContext!,
        duration: widget.scrollDuration,
        alignment: 0.5,
      );
      // setState(() {
      _isScrolling = false;
      // });

      completer.complete();
    });

    return completer.future;
  }

  /// Completes showcase of given key and starts next one
  /// otherwise will finish the entire showcase view
  // void completed(GlobalKey? key) {
  //   if (allWidgets != null && ids![activeWidgetId!] == key && mounted) {
  //     setState(() {
  //       _onComplete();
  //       activeWidgetId = activeWidgetId! + 1;
  //       _onStart();

  //       if (activeWidgetId! >= ids!.length) {
  //         _cleanupAfterSteps();
  //         if (widget.onFinish != null) {
  //           widget.onFinish!();
  //         }
  //       }
  //     });
  //   }
  // }

  /// Completes current active showcase and starts next one
  /// otherwise will finish the entire showcase view
  void next() {
    _catchError(
      () {
        if (allKeys != null && mounted) {
          setState(() {
            _onComplete();

            if (currentIndex! >= allKeys!.length - 1) {
              _cleanupAfterSteps();
              if (widget.onFinish != null) {
                widget.onFinish!();
              }
            } else {
              currentIndex = currentIndex! + 1;
              _onStart();
            }
          });
        }
      },
    );
  }

  bool isLastItem() =>
      allKeys != null &&
      ((currentIndex ?? 0) + 1) >= allKeys!.length &&
      mounted;

  /// Completes current active showcase and starts previous one
  /// otherwise will finish the entire showcase view
  void previous() {
    _catchError(() {
      if (canGoToPrevious()) {
        setState(() {
          _onComplete();
          currentIndex = currentIndex! - 1;
          _onStart();
          if (currentIndex! >= allKeys!.length) {
            _cleanupAfterSteps();
            if (widget.onFinish != null) {
              widget.onFinish!();
            }
          }
        });
      }
    });
  }

  bool canGoToPrevious() =>
      allKeys != null && ((currentIndex ?? 0) - 1) >= 0 && mounted;

  /// Dismiss entire showcase view
  void dismiss() {
    if (mounted) {
      setState(_cleanupAfterSteps);
    }
  }

  void dismissWithoutRebuild() {
    _cleanupAfterSteps();
  }

  void _onStart() {
    // if (_onStartCallbacks.isNotEmpty) {
    //   for (final callback in _onStartCallbacks) {
    //     callback.call(currentIndex!);
    //   }

    //   SchedulerBinding.instance.addPostFrameCallback((_) {
    //     setState(() {});
    //   });
    // }

    // if(_onStartCallback != null) {

    // }
    _ensureVisible();
    if (currentIndex! < allKeys!.length) {
      widget.onStart?.call(currentIndex, allKeys![currentIndex!]);
    }
  }

  void _onComplete() {
    widget.onComplete?.call(currentIndex, allKeys![currentIndex!]);
  }

  bool isCurrentlyDisplayed() {
    return currentIndex != null && allKeys != null;
  }

  void _cleanupAfterSteps() {
    _onScrollToCallback = null;
    currentIndex = null;
    allKeys = null;
    _isScrolling = false;
  }

  Widget renderShowcase() {
    try {
      if (currentIndex == null || allKeys == null) {
        return const SizedBox();
      }

      final currentState = allKeys![currentIndex!].currentState;

      if (currentState == null) {
        return const SizedBox();
      }

      return _Overlay(showcaseKey: allKeys![currentIndex!]);
    } catch (error, stackTrace) {
      widget.onError(error, stackTrace);
      _cleanupAfterSteps();

      // rebuild without blocking interactions in case an error occurs
      // by _cleanupAfterSteps, currentIndex and allKeys are both set to null so another post frame callback won't be registered
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder,
        if (!_isScrolling) renderShowcase() else const BlockForegroundWidget(),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    Key? key,
    required this.showcaseKey,
  }) : super(key: key);

  final GlobalKey<StackShowcaseState> showcaseKey;

  RenderBox? _getRenderObjectFromContext() {
    try {
      final context = showcaseKey.currentContext;
      final state = showcaseKey.currentState;
      if (context == null || state == null) {
        return null;
      }
      return context.findRenderObject() as RenderBox?;
    } catch (_) {
      return null;
    }
  }

  StackShowcaseState get currentShowcaseState => showcaseKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return AnimatedBuilder(
        animation: ModalRoute.of(context)!.secondaryAnimation!,
        builder: (animatedBuilderContext, _) {
          final box = _getRenderObjectFromContext();

          if (box == null) {
            return const SizedBox();
          }
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
            context,
          );
        },
      );
    });
  }

  Widget buildOverlayOnTarget(
    Offset offset,
    Size size,
    Rect rectBound,
    Size screenSize,
    BuildContext stackContext,
  ) {
    final showCaseWidgetState = StackShowCaseWidget.of(stackContext);
    final position = GetPosition(
      key: (currentShowcaseState.widget.key as GlobalKey),
      padding: currentShowcaseState.widget.targetPadding,
      screenWidth: MediaQuery.of(stackContext).size.width,
      screenHeight: MediaQuery.of(stackContext).size.height,
    );
    var blur = 0.0;

    blur =
        currentShowcaseState.widget.blurValue ?? showCaseWidgetState.blurValue;

    // Set blur to 0 if application is running on web and
    // provided blur is less than 0.
    blur = kIsWeb && blur < 0 ? 0 : blur;

    final routeTransitionAnimationValue =
        ModalRoute.of(stackContext)!.secondaryAnimation!.value;

    final bool hide = showCaseWidgetState._isScrolling ||
        routeTransitionAnimationValue - routeTransitionAnimationValue.toInt() !=
            0.0;

    Widget baseOverlay = ClipPath(
      clipper: RRectClipper(
        area: hide ? Rect.zero : rectBound,
        isCircle: currentShowcaseState.widget.targetShapeBorder ==
            const CircleBorder(),
        radius: hide
            ? BorderRadius.zero
            : currentShowcaseState.widget.targetBorderRadius,
        overlayPadding:
            hide ? EdgeInsets.zero : currentShowcaseState.widget.targetPadding,
      ),
      child: blur != 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                width: MediaQuery.of(stackContext).size.width,
                height: MediaQuery.of(stackContext).size.height,
                decoration: BoxDecoration(
                  color: currentShowcaseState.widget.overlayColor
                      .withOpacity(currentShowcaseState.widget.overlayOpacity),
                ),
              ),
            )
          : Container(
              width: MediaQuery.of(stackContext).size.width,
              height: MediaQuery.of(stackContext).size.height,
              decoration: BoxDecoration(
                color: currentShowcaseState.widget.overlayColor
                    .withOpacity(currentShowcaseState.widget.overlayOpacity),
              ),
            ),
    );

    baseOverlay = Stack(
      children: [
        baseOverlay,
        if (!hide && currentShowcaseState.widget.addBorderAroundTarget)
          Positioned(
            left: rectBound.left,
            top: rectBound.top,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 2,
                    color:
                        currentShowcaseState.widget.borderAroundTargetColor ??
                            Colors.white.withOpacity(0.5),
                  ),
                  top: BorderSide(
                    width: 2,
                    color:
                        currentShowcaseState.widget.borderAroundTargetColor ??
                            Colors.white.withOpacity(0.5),
                  ),
                  right: BorderSide(
                    width: 2,
                    color:
                        currentShowcaseState.widget.borderAroundTargetColor ??
                            Colors.white.withOpacity(0.5),
                  ),
                  bottom:
                      currentShowcaseState.widget.joinShowcaseAndFocusedWidgets
                          ? BorderSide.none
                          : BorderSide(
                              width: 2,
                              color: currentShowcaseState
                                      .widget.borderAroundTargetColor ??
                                  Colors.white.withOpacity(0.5),
                            ),
                ),
                borderRadius:
                    currentShowcaseState.widget.joinShowcaseAndFocusedWidgets
                        ? null
                        : currentShowcaseState.widget.targetBorderRadius,
              ),
              width: rectBound.width,
              height: rectBound.height +
                  currentShowcaseState.widget.targetPadding.vertical,
            ),
          ),
      ],
    );

    final focusedWidgetsPointerAbsorber = <Widget>[];

    if (currentShowcaseState.widget.focusedWidgetsKeys != null) {
      final allKeys =
          currentShowcaseState.widget.focusedWidgetsKeys!.getAllKeys();

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
                      (currentShowcaseState
                              .widget.focusedWidgetsOverlayHorizontalShift ??
                          0),
                  topLeft.dy -
                      (currentShowcaseState
                              .widget.focusedWidgetsOverlayVerticalShift ??
                          0),
                  bottomRight.dx +
                      (currentShowcaseState
                              .widget.focusedWidgetsOverlayHorizontalShift ??
                          0),
                  bottomRight.dy +
                      (currentShowcaseState
                              .widget.focusedWidgetsOverlayVerticalShift ??
                          0),
                );

          baseOverlay = Stack(
            children: [
              ClipPath(
                clipper: RRectClipper(
                  area: hide ? Rect.zero : anchorBounds,
                  isCircle: currentShowcaseState.widget.targetShapeBorder ==
                      const CircleBorder(),
                  radius: hide
                      ? BorderRadius.zero
                      : currentShowcaseState.widget.targetBorderRadius,
                  overlayPadding: hide
                      ? EdgeInsets.zero
                      : currentShowcaseState.widget.targetPadding,
                ),
                child: baseOverlay,
              ),
              if (!hide && currentShowcaseState.widget.addBorderAroundTarget)
                Positioned(
                  left: anchorBounds.left,
                  top: anchorBounds.top,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 2,
                          color: currentShowcaseState
                                  .widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                        bottom: BorderSide(
                          width: 2,
                          color: currentShowcaseState
                                  .widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                        right: BorderSide(
                          width: 2,
                          color: currentShowcaseState
                                  .widget.borderAroundTargetColor ??
                              Colors.white.withOpacity(0.5),
                        ),
                        top: currentShowcaseState
                                .widget.joinShowcaseAndFocusedWidgets
                            ? BorderSide.none
                            : BorderSide(
                                width: 2,
                                color: currentShowcaseState
                                        .widget.borderAroundTargetColor ??
                                    Colors.white.withOpacity(0.5),
                              ),
                      ),
                      borderRadius: currentShowcaseState
                              .widget.joinShowcaseAndFocusedWidgets
                          ? null
                          : currentShowcaseState.widget.targetBorderRadius,
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
              onTap: () async {
                if (currentShowcaseState.widget.disableNextOnTap) {
                  return;
                }

                // if (currentShowcaseState.widget.disposeOnTap == true) {
                //   await _reverseAnimateTooltip();
                //   showCaseWidgetState.dismiss();
                //   currentShowcaseState.widget.onTargetClick!();
                // } else {
                //   // (widget.onTargetClick ?? _nextIfAny).call();
                // }
              },
              radius: currentShowcaseState.widget.targetBorderRadius,
              onDoubleTap: currentShowcaseState.widget.onTargetDoubleTap,
              onLongPress: currentShowcaseState.widget.onTargetLongPress,
              shapeBorder: currentShowcaseState.widget.targetShapeBorder,
              disableDefaultChildGestures:
                  currentShowcaseState.widget.disableDefaultTargetGestures,
            ),
          );
        }
      }
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (!showCaseWidgetState.disableBarrierInteraction) {
              // _nextIfAny();
            }
          },
          child: baseOverlay,
        ),
        if (hide)
          Center(child: currentShowcaseState.widget.scrollLoadingWidget),
        if (!hide) ...[
          _TargetWidget(
            offset: offset,
            size: size,
            onTap: () async {
              if (currentShowcaseState.widget.disableNextOnTap) {
                return;
              }

              // if (currentShowcaseState.widget.disposeOnTap == true) {
              //   await _reverseAnimateTooltip();
              //   showCaseWidgetState.dismiss();
              //   currentShowcaseState.widget.onTargetClick!();
              // } else {
              //   // (widget.onTargetClick ?? _nextIfAny).call();
              // }
            },
            radius: currentShowcaseState.widget.targetBorderRadius,
            onDoubleTap: currentShowcaseState.widget.onTargetDoubleTap,
            onLongPress: currentShowcaseState.widget.onTargetLongPress,
            shapeBorder: currentShowcaseState.widget.targetShapeBorder,
            disableDefaultChildGestures:
                currentShowcaseState.widget.disableDefaultTargetGestures,
          ),
          ...focusedWidgetsPointerAbsorber,
        ],
        if (!hide)
          ToolTipWidget(
            position: position,
            offset: offset,
            screenSize: screenSize,
            title: currentShowcaseState.widget.title,
            titleAlignment: currentShowcaseState.widget.titleAlignment,
            description: currentShowcaseState.widget.description,
            descriptionAlignment:
                currentShowcaseState.widget.descriptionAlignment,
            titleTextStyle: currentShowcaseState.widget.titleTextStyle,
            descTextStyle: currentShowcaseState.widget.descTextStyle,
            container: currentShowcaseState.widget.container,
            tooltipBackgroundColor:
                currentShowcaseState.widget.tooltipBackgroundColor,
            textColor: currentShowcaseState.widget.textColor,
            showArrow: currentShowcaseState.widget.showArrow,
            contentHeight: currentShowcaseState.widget.height,
            contentWidth: currentShowcaseState.widget.width,
            onTooltipTap: () {},
            tooltipPadding: currentShowcaseState.widget.tooltipPadding,
            disableMovingAnimation:
                currentShowcaseState.widget.disableMovingAnimation ??
                    showCaseWidgetState.disableMovingAnimation,
            disableScaleAnimation:
                currentShowcaseState.widget.disableScaleAnimation ??
                    showCaseWidgetState.disableScaleAnimation,
            movingAnimationDuration:
                currentShowcaseState.widget.movingAnimationDuration,
            tooltipBorderRadius:
                currentShowcaseState.widget.tooltipBorderRadius,
            scaleAnimationDuration:
                currentShowcaseState.widget.scaleAnimationDuration,
            scaleAnimationCurve:
                currentShowcaseState.widget.scaleAnimationCurve,
            scaleAnimationAlignment:
                currentShowcaseState.widget.scaleAnimationAlignment,
            isTooltipDismissed: false,
            tooltipAlignment: currentShowcaseState.widget.tooltipAlignment,
            topPadding: currentShowcaseState.widget.tooltipTopPadding,
            showPreviousButton: showCaseWidgetState.canGoToPrevious(),
            onNextPressed: () {
              if (showCaseWidgetState.isLastItem()) {
                currentShowcaseState.widget.onDonePressed?.call();
              }
              showCaseWidgetState.next();
            },
            onPreviousPressed: () => showCaseWidgetState.previous(),
            previousButtonText: currentShowcaseState.widget.previousButtonText,
            nextButtonText: showCaseWidgetState.isLastItem()
                ? currentShowcaseState.widget.doneButtonText
                : currentShowcaseState.widget.nextButtonText,
          ),
        if (currentShowcaseState.widget.skipButtonText != null &&
            !showCaseWidgetState.isLastItem())
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(stackContext).viewPadding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: () {
                  showCaseWidgetState.dismiss();
                  currentShowcaseState.widget.onSkipPressed?.call();
                },
                child: Text(currentShowcaseState.widget.skipButtonText!),
              ),
            ),
          ),
      ],
    );
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
