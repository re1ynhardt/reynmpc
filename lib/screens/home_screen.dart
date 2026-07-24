import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../localization/locale_controller.dart';
import '../models/nav_view.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';
import '../widgets/library_grid_view.dart';
import '../widgets/player_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/track_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  NavView _view = NavView.home;

  void _goTo(NavView view) {
    setState(() => _view = view);
    if (view != NavView.search) {
      // Уходим с поиска — сбрасываем запрос, чтобы не путать при возврате.
      _searchController.clear();
      context.read<MusicLibrary>().search('');
    }
  }

  void _openPlaylistByIndex(int index) {
    final library = context.read<MusicLibrary>();
    if (index < 0 || index >= library.playlists.length) return;
    library.selectPlaylist(library.playlists[index]);
    setState(() => _view = NavView.home);
  }

  void _openPlaylist(Playlist playlist) {
    context.read<MusicLibrary>().selectPlaylist(playlist);
    setState(() => _view = NavView.home);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MusicLibrary>();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  activeView: _view,
                  onNavSelect: _goTo,
                  onPlaylistTap: _openPlaylistByIndex,
                ),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          view: _view,
                          controller: _searchController,
                          onOpenSearch: () => _goTo(NavView.search),
                          onCloseSearch: () => _goTo(NavView.home),
                          onSearchChanged: library.search,
                        ),
                        Expanded(child: _buildContent(library)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PlayerBar(),
        ],
      ),
    );
  }

  Widget _buildContent(MusicLibrary library) {
    switch (_view) {
      case NavView.search:
        return _SearchResults(library: library);
      case NavView.library:
        return LibraryGridView(
          playlists: library.playlists,
          onPlaylistTap: _openPlaylist,
        );
      case NavView.home:
        return _PlaylistContent(library: library);
    }
  }
}

class _TopBar extends StatelessWidget {
  final NavView view;
  final TextEditingController controller;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;

  const _TopBar({
    required this.view,
    required this.controller,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final searching = view == NavView.search;
    final s = context.watch<LocaleController>().s;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Row(
            children: [
              _RoundButton(icon: Icons.chevron_left, onTap: () {}),
              const SizedBox(width: 8),
              _RoundButton(icon: Icons.chevron_right, onTap: () {}),
            ],
          ),
          const SizedBox(width: 16),
          if (searching)
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: s.searchHint,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          IconButton(
            icon: Icon(searching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: searching ? onCloseSearch : onOpenSearch,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _PlaylistContent extends StatelessWidget {
  final MusicLibrary library;
  const _PlaylistContent({required this.library});

  @override
  Widget build(BuildContext context) {
    final playlist = library.selectedPlaylist;
    final s = context.watch<LocaleController>().s;
    if (library.isLoadingPlaylists || playlist == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(playlist.coverUrl, width: 160, height: 160, fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stackTrace) => Container(width: 160, height: 160, color: AppColors.surfaceHigh)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.playlistLabel, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(playlist.name,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(playlist.description, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (library.isLoadingTracks)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.green)),
            )
          else
            TrackListView(tracks: library.tracksOfSelectedPlaylist),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final MusicLibrary library;
  const _SearchResults({required this.library});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    if (library.isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (library.searchResults.isEmpty) {
      return Center(
        child: Text(s.searchPrompt, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TrackListView(tracks: library.searchResults),
      ),
    );
  }
}
