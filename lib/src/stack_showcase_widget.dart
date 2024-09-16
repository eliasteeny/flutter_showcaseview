import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../showcaseview.dart';

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
  bool _isManuallyScrolling = false;

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

  /// Starts Showcase view from the beginning of specified list of widget ids.
  void startShowCase(List<GlobalKey<StackShowcaseState>> keys) {
    if (mounted) {
      setState(() {
        allKeys = keys;

        currentIndex = 0;

        _onStart();
      });
    }
  }

  void _ensureVisible() async {
    if (currentIndex == null || allKeys == null) {
      return;
    }

    bool didScrollManually = false;

    if (_onScrollToCallback != null) {
      final scrollFuture = _onScrollToCallback!.call(currentIndex!);

      if (scrollFuture != null) {
        setState(() {
          _isManuallyScrolling = true;
        });
        await scrollFuture;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        setState(() {
          _isManuallyScrolling = false;
        });
        didScrollManually = true;
      }
    }

    final currentState = allKeys![currentIndex!].currentState;

    if (currentState == null) {
      return;
    }

    final scrollFuture =
        currentState.scrollIntoView(disableScroll: didScrollManually);

    setState(() {});

    await scrollFuture;

    if (mounted) {
      setState(() {});
    }
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
  }

  bool isLastItem() =>
      allKeys != null &&
      ((currentIndex ?? 0) + 1) >= allKeys!.length &&
      mounted;

  /// Completes current active showcase and starts previous one
  /// otherwise will finish the entire showcase view
  void previous() {
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
  }

  bool canGoToPrevious() =>
      allKeys != null && ((currentIndex ?? 0) - 1) >= 0 && mounted;

  /// Dismiss entire showcase view
  void dismiss() {
    if (mounted) {
      setState(_cleanupAfterSteps);
    }
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

  void _cleanupAfterSteps() {
    _onScrollToCallback = null;
    currentIndex = null;
    allKeys = null;
  }

  Widget renderShowcase() {
    if (currentIndex == null || allKeys == null) {
      return const SizedBox();
    }

    final currentState = allKeys![currentIndex!].currentState;

    if (currentState == null) {
      return const SizedBox();
    }

    final overlayWidget = currentState.getOverlayWidget();

    if (overlayWidget == null) {
      return const SizedBox();
    }

    return OrientationBuilder(builder: (context, orientation) {
      return overlayWidget;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder,
        if (!_isManuallyScrolling)
          renderShowcase()
        else
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: Colors.black45.withOpacity(0.75),
              ),
            ),
          ),
      ],
    );
  }
}
