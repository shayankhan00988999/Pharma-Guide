import 'package:flutter/material.dart';
import '../models/drive_node.dart';
import '../services/drive_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/file_tile.dart';
import '../widgets/folder_card.dart';
import 'folder_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _driveService = DriveService();
  late Future<DriveNode> _treeFuture;

  @override
  void initState() {
    super.initState();
    _treeFuture = _driveService.fetchNode();
  }

  Future<void> _refresh() async {
    final future = _driveService.fetchNode(forceRefresh: true);
    setState(() => _treeFuture = future);
    await future;
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<DriveNode>(
          future: _treeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomScrollView(
                slivers: [
                  _buildHeaderSliver(itemsLabel: 'Loading your notes…'),
                  const SliverToBoxAdapter(child: DashboardShimmer()),
                ],
              );
            }

            if (snapshot.hasError) {
              return CustomScrollView(
                slivers: [
                  _buildHeaderSliver(itemsLabel: 'Something went wrong'),
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

            final root = snapshot.data!;
            final subfolders = root.children.where((c) => c.isFolder).toList();
            final files = root.children.where((c) => !c.isFolder).toList();

            if (root.children.isEmpty) {
              return CustomScrollView(
                slivers: [
                  _buildHeaderSliver(itemsLabel: 'No notes uploaded yet'),
                  const SliverFillRemaining(
                    child: Center(child: Text('No notes uploaded yet.')),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                _buildHeaderSliver(
                  itemsLabel:
                      '${subfolders.length} folders · ${files.length} files',
                ),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSliver({required String itemsLabel}) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      backgroundColor: AppColors.teal,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          tooltip: 'Log out',
          onPressed: _logout,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.teal, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.local_pharmacy_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Shayan Pharma Guide',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    itemsLabel,
                    style: TextStyle(color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
