import 'package:flutter/material.dart';
import '../models/drive_node.dart';
import '../services/drive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/file_tile.dart';
import '../widgets/folder_card.dart';

/// Shown when a folder is tapped, anywhere in the tree. Its contents
/// are fetched lazily — only once this screen actually opens — rather
/// than being part of one giant tree fetched up front. Tapping a
/// subfolder here pushes another instance of this same screen, which
/// in turn fetches only that subfolder's contents.
class FolderScreen extends StatefulWidget {
  /// A lightweight node for this folder (id + name, and an itemCount
  /// hint from the parent listing). Its `children` may be empty even
  /// though the folder isn't — this screen fetches the real contents.
  final DriveNode node;

  const FolderScreen({super.key, required this.node});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final _driveService = DriveService();
  late Future<DriveNode> _future;

  @override
  void initState() {
    super.initState();
    _future = _driveService.fetchNode(folderId: widget.node.id);
  }

  Future<void> _refresh() async {
    final future =
        _driveService.fetchNode(folderId: widget.node.id, forceRefresh: true);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.gradientFor(widget.node.name);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<DriveNode>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomScrollView(
                slivers: [
                  _headerSliver(colors, widget.node.name),
                  const SliverToBoxAdapter(child: DashboardShimmer()),
                ],
              );
            }

            if (snapshot.hasError) {
              return CustomScrollView(
                slivers: [
                  _headerSliver(colors, widget.node.name),
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('${snapshot.error}', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final node = snapshot.data!;
            final subfolders = node.children.where((c) => c.isFolder).toList();
            final files = node.children.where((c) => !c.isFolder).toList();

            return CustomScrollView(
              slivers: [
                _headerSliver(colors, node.name),
                if (node.children.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('This folder is empty.')),
                  )
                else ...[
                  if (subfolders.isNotEmpty) ...[
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text('Folders',
                            style:
                                TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final folder = subfolders[index];
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 40 * index),
                              child: FolderCard(
                                node: folder,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FolderScreen(node: folder),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: subfolders.length,
                        ),
                      ),
                    ),
                  ],
                  if (files.isNotEmpty) ...[
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
                      sliver: SliverToBoxAdapter(
                        child: Text('Files',
                            style:
                                TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FileTile(node: files[index]),
                          childCount: files.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerSliver(List<Color> colors, String title) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      backgroundColor: colors.first,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}
