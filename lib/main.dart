import 'package:flutter/material.dart';
//import 'dart:math' as math;

/// Main entry point for the application.
/// Initializes the app with playful dock implementation.
void main() {
  runApp(const MyApp());
}

/// Root widget of the application.
/// Sets up the material app with basic theme configuration.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DockDemo(),
    );
  }
}

/// Demo screen that displays the animated dock.
/// Provides a clean background and centers the dock.
class DockDemo extends StatelessWidget {
  const DockDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PlayfulDock(
          items: List.generate(
            6,
            (index) => DockItem(
              icon: _getIconForIndex(index),
              label: 'Item ${index + 1}',
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a unique icon for each dock item.
  IconData _getIconForIndex(int index) {
    final icons = [
      Icons.home,
      Icons.person,
      Icons.message,
      Icons.phone,
      Icons.camera,
      Icons.music_note,
    ];
    return icons[index];
  }
}

/// Model class for dock items.
/// Contains the icon and label information for each dock item.
class DockItem {
  /// Icon to be displayed in the dock item.
  final IconData icon;

  /// Label text for the dock item.
  final String label;

  const DockItem({
    required this.icon,
    required this.label,
  });
}

/// An animated dock widget that supports drag-drop reordering
/// and playful animations.
class PlayfulDock extends StatefulWidget {
  /// List of items to be displayed in the dock.
  final List<DockItem> items;

  const PlayfulDock({
    super.key,
    required this.items,
  });

  @override
  State<PlayfulDock> createState() => _PlayfulDockState();
}

/// State class for PlayfulDock that manages animations and interactions.
class _PlayfulDockState extends State<PlayfulDock>
    with TickerProviderStateMixin {
  /// List of dock items that can be reordered.
  late List<DockItem> _items;

  /// Currently dragged item index.
  int? _draggedIndex;

  /// Target index for reordering.
  int? _targetIndex;

  /// Currently hovered item index.
  int? _hoveredIndex;

  // Animation controllers
  late final AnimationController _hoverController;
  late final AnimationController _bounceController;
  late final AnimationController _breathingController;

  // Animation instances
  late final Animation<double> _hoverAnimation;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _breathingAnimation;

  /// Animation durations - slowed down for more playful effect
  static const _hoverDuration = Duration(milliseconds: 600);
  static const _bounceDuration = Duration(milliseconds: 1200);
  static const _breathingDuration = Duration(milliseconds: 3000);

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
    _initializeAnimations();
  }

  /// Initialize all animation controllers and animations with slower durations.
  void _initializeAnimations() {
    // Setup hover animation
    _hoverController = AnimationController(
      vsync: this,
      duration: _hoverDuration,
    );

    // Setup bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: _bounceDuration,
    );

    // Setup breathing animation
    _breathingController = AnimationController(
      vsync: this,
      duration: _breathingDuration,
    )..repeat(reverse: true);

    // Configure hover animation with elastic effect
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.elasticOut,
    ));

    // Configure bounce animation sequence
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50.0,
      ),
    ]).animate(_bounceController);

    // Configure breathing animation
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _bounceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_items.length, (index) {
          return _buildDockItem(index);
        }),
      ),
    );
  }

  /// Builds an individual dock item with animations and interactions.
  Widget _buildDockItem(int index) {
    final item = _items[index];
    final isBeingDragged = _draggedIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => _onItemHover(index),
      onExit: (_) => _onItemExit(),
      child: Draggable<int>(
        data: index,
        feedback: _buildDockItemWidget(item, index, isDragging: true),
        childWhenDragging: const SizedBox(width: 48),
        onDragStarted: () => _onDragStart(index),
        onDragEnd: (_) => _onDragEnd(),
        child: DragTarget<int>(
          onWillAccept: (data) => data != index,
          onAccept: (draggedIndex) => _handleReorder(draggedIndex, index),
          builder: (context, candidates, rejects) {
            return AnimatedBuilder(
              animation: Listenable.merge([
                _hoverAnimation,
                _bounceAnimation,
                _breathingAnimation,
              ]),
              builder: (context, child) {
                double scale = _breathingAnimation.value;
                if (isBeingDragged) scale *= _bounceAnimation.value;
                if (isHovered) scale *= _hoverAnimation.value;

                return Transform.scale(
                  scale: scale,
                  child: _buildDockItemWidget(item, index),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds the visual representation of a dock item.
  Widget _buildDockItemWidget(DockItem item, int index,
      {bool isDragging = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 48,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.primaries[index % Colors.primaries.length],
      ),
      child: Center(
        child: Icon(
          item.icon,
          color: Colors.white,
          size: isDragging ? 28 : 24,
        ),
      ),
    );
  }

  /// Handles hover enter event.
  void _onItemHover(int index) {
    setState(() => _hoveredIndex = index);
    _hoverController.forward();
  }

  /// Handles hover exit event.
  void _onItemExit() {
    setState(() => _hoveredIndex = null);
    _hoverController.reverse();
  }

  /// Handles drag start event.
  void _onDragStart(int index) {
    setState(() => _draggedIndex = index);
    _bounceController.forward();
  }

  /// Handles drag end event.
  void _onDragEnd() {
    setState(() {
      _draggedIndex = null;
      _targetIndex = null;
    });
    _bounceController.reverse();
  }

  /// Handles reordering of items.
  void _handleReorder(int draggedIndex, int targetIndex) {
    setState(() {
      final item = _items.removeAt(draggedIndex);
      _items.insert(targetIndex, item);
      _targetIndex = targetIndex;
    });
  }
}
