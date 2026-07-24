import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../localization/app_strings.dart';
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
    final pal = AppColors.of(context);

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
                    color: pal.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          view: _view,
                          controller: _searchController,
                          onNavSelect: _goTo,
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
  final ValueChanged<NavView> onNavSelect;
  final ValueChanged<String> onSearchChanged;

  const _TopBar({
    required this.view,
    required this.controller,
    required this.onNavSelect,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final searching = view == NavView.search;
    final s = context.watch<LocaleController>().s;
    final pal = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        children: [
          Row(
            children: [
              Row(
                children: [
                  _RoundButton(icon: Icons.chevron_left, onTap: () {}),
                  const SizedBox(width: 8),
                  _RoundButton(icon: Icons.chevron_right, onTap: () {}),
                ],
              ),
              // Центрируем группу навигационных виджетов относительно всей
              // ширины полосы — по бокам такой же по смыслу "вес", как у
              // кнопок навигации слева.
              Expanded(
                child: Center(
                  child: _NavPillGroup(
                    view: view,
                    onNavSelect: onNavSelect,
                    labels: s,
                  ),
                ),
              ),
              const SizedBox(width: 32 + 8 + 32), // баланс под левые кнопки
            ],
          ),
          if (searching) ...[
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _GlassSurface(
                  borderRadius: 24,
                  strong: true,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: onSearchChanged,
                    style: TextStyle(color: pal.textPrimary),
                    decoration: InputDecoration(
                      hintText: s.searchHint,
                      hintStyle: TextStyle(color: pal.textSecondary),
                      prefixIcon: Icon(Icons.search, color: pal.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close, color: pal.textSecondary, size: 18),
                        onPressed: () => onNavSelect(NavView.home),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Группа из трёх кнопок навигации (Главная / Поиск / Моя медиатека),
/// оформленная как единый полупрозрачный "стеклянный" виджет по центру
/// верхней панели.
class _NavPillGroup extends StatelessWidget {
  final NavView view;
  final ValueChanged<NavView> onNavSelect;
  final AppStrings labels;

  const _NavPillGroup({
    required this.view,
    required this.onNavSelect,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      borderRadius: 28,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavPillButton(
            icon: Icons.home_filled,
            label: labels.navHome,
            selected: view == NavView.home,
            onTap: () => onNavSelect(NavView.home),
          ),
          _NavPillButton(
            icon: Icons.search,
            label: labels.navSearch,
            selected: view == NavView.search,
            onTap: () => onNavSelect(NavView.search),
          ),
          _NavPillButton(
            icon: Icons.library_music,
            label: labels.navLibrary,
            selected: view == NavView.library,
            onTap: () => onNavSelect(NavView.library),
          ),
        ],
      ),
    );
  }
}

class _NavPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavPillButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? pal.glassFillStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: selected ? Border.all(color: pal.glassBorderStrong) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? pal.textPrimary : pal.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? pal.textPrimary : pal.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Общая "стеклянная" (glassmorphism) поверхность: блюр фона + полупрозрачная
/// заливка + тонкая обводка — цвета берутся из текущей палитры темы.
/// Используется и для группы навигации, и для поля поиска, чтобы визуально
/// они смотрелись как единая система.
class _GlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool strong;
  final EdgeInsetsGeometry padding;

  const _GlassSurface({
    required this.child,
    this.borderRadius = 20,
    this.strong = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: strong ? pal.glassFillStrong : pal.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: pal.glassBorder),
            boxShadow: [
              BoxShadow(
                color: pal.glassShadow,
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
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
    final pal = AppColors.of(context);
    if (library.isLoadingPlaylists || playlist == null) {
      return Center(child: CircularProgressIndicator(color: pal.accent));
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
                      errorBuilder: (ctx, error, stackTrace) => Container(width: 160, height: 160, color: pal.surfaceHigh)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.playlistLabel, style: TextStyle(fontSize: 12, color: pal.textPrimary)),
                    const SizedBox(height: 8),
                    Text(playlist.name,
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: pal.textPrimary)),
                    const SizedBox(height: 8),
                    Text(playlist.description, style: TextStyle(color: pal.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (library.isLoadingTracks)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: pal.accent)),
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
    final pal = AppColors.of(context);
    if (library.isSearching) {
      return Center(child: CircularProgressIndicator(color: pal.accent));
    }
    if (library.searchResults.isEmpty) {
      return Center(
        child: Text(s.searchPrompt, style: TextStyle(color: pal.textSecondary)),
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
