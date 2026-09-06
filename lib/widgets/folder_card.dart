import 'package:flutter/material.dart';
import '../models/drive_node.dart';
import '../theme/app_theme.dart';

/// A vibrant gradient card representing one folder. Tapping it is the
/// only way in — its contents are shown on their own screen rather
/// than expanding inline, so a folder full of files never floods the
/// screen it was tapped from.
class FolderCard extends StatefulWidget {
  final DriveNode node;
  final VoidCallback onTap;

  const FolderCard({super.key, required this.node, required this.onTap});

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  double _scale = 1;

  int get _itemCount => widget.node.displayItemCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.gradientFor(widget.node.name);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.folder_rounded,
                    color: Colors.white, size: 26),
              ),
              const Spacer(),
              Text(
                widget.node.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _itemCount == 1 ? '1 item' : '$_itemCount items',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
