import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/music_library.dart';
import '../localization/app_strings.dart';
import '../localization/locale_controller.dart';
import '../models/nav_view.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';
import '../widgets/account_menu.dart';
import '../widgets/library_grid_view.dart';
import '../widgets/logo_mark.dart';
import '../widgets/player_bar.dart';
import '../widgets/track_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Один шаг истории навигации: раздел (Главная/Поиск/Медиатека) и —
/// если это плейлист, открытый на Главной — сам плейлист, чтобы кнопка
/// "назад" возвращала именно к нему, а не к дефолтному.
class _NavEntry {
  final NavView view;
  final Playlist? playlist;
  const _NavEntry(this.view, this.playlist);
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  NavView _view = NavView.home;

  // История навигации для кнопок "назад"/"вперёд" в верхней панели —
  // работает как в браузере: любой переход, кроме самих back/forward,
  // обрезает "будущее" и добавляет новую запись.
  final List<_NavEntry> _history = [const _NavEntry(NavView.home, null)];
  int _historyIndex = 0;

  bool get _canGoBack => _historyIndex > 0;
  bool get _canGoForward => _historyIndex < _history.length - 1;

  void _pushHistory(NavView view, {Playlist? playlist}) {
    final entry = _NavEntry(view, playlist ?? context.read<MusicLibrary>().selectedPlaylist);
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(entry);
    _historyIndex = _history.length - 1;
  }

  void _applyEntry(_NavEntry entry) {
    final library = context.read<MusicLibrary>();
    setState(() => _view = entry.view);
    if (entry.playlist != null) {
      if (library.selectedPlaylist?.id != entry.playlist!.id) {
        library.selectPlaylist(entry.playlist!);
      }
    } else if (entry.view == NavView.home) {
      // Запись истории без плейлиста на Главной — значит там был общий
      // список первых треков, а не открытый плейлист.
      library.clearSelectedPlaylist();
    }
    if (entry.view != NavView.search) {
      _searchController.clear();
      library.search('');
    }
  }

  void _goBack() {
    if (!_canGoBack) return;
    _historyIndex--;
    _applyEntry(_history[_historyIndex]);
  }

  void _goForward() {
    if (!_canGoForward) return;
    _historyIndex++;
    _applyEntry(_history[_historyIndex]);
  }

  void _goTo(NavView view) {
    setState(() => _view = view);
    if (view != NavView.search) {
      // Уходим с поиска — сбрасываем запрос, чтобы не путать при возврате.
      _searchController.clear();
      context.read<MusicLibrary>().search('');
    }
    if (view == NavView.home) {
      // Клик по "Главная" в навигации всегда возвращает к общему списку
      // первых треков, а не к последнему открытому плейлисту.
      context.read<MusicLibrary>().clearSelectedPlaylist();
    }
    _pushHistory(view);
  }

  void _openPlaylist(Playlist playlist) {
    context.read<MusicLibrary>().selectPlaylist(playlist);
    setState(() => _view = NavView.home);
    _pushHistory(NavView.home, playlist: playlist);
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(pal.accentGlow.withOpacity(0.06), pal.background),
                    pal.background,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    view: _view,
                    controller: _searchController,
                    onNavSelect: _goTo,
                    onSearchChanged: library.search,
                    onBack: _canGoBack ? _goBack : null,
                    onForward: _canGoForward ? _goForward : null,
                  ),
                  Expanded(child: _buildContent(library)),
                ],
              ),
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
        return library.selectedPlaylist != null
            ? _PlaylistContent(library: library)
            : _AllTracksContent(library: library);
    }
  }
}

class _TopBar extends StatelessWidget {
  final NavView view;
  final TextEditingController controller;
  final ValueChanged<NavView> onNavSelect;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const _TopBar({
    required this.view,
    required this.controller,
    required this.onNavSelect,
    required this.onSearchChanged,
    this.onBack,
    this.onForward,
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
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Логотип и надпись ReynM — раньше жили в сайдбаре, теперь
              // слева в верхней панели вместе с кнопками истории.
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoMark(size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'ReynM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pal.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _RoundButton(icon: Icons.chevron_left, onTap: onBack),
                    const SizedBox(width: 8),
                    _RoundButton(icon: Icons.chevron_right, onTap: onForward),
                  ],
                ),
              ),
              // Группа навигационных виджетов центрируется относительно
              // всей ширины полосы независимо от ширины боковых групп.
              _NavPillGroup(
                view: view,
                onNavSelect: onNavSelect,
                labels: s,
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: AccountAvatarButton(),
              ),
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
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: pal.glassBorder),
            boxShadow: [
              BoxShadow(
                color: pal.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(pal.glassHighlight, strong ? pal.glassFillStrong : pal.glassFill),
                strong ? pal.glassFillStrong : pal.glassFill,
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: pal.glassFill,
            shape: BoxShape.circle,
            border: Border.all(color: pal.glassBorder),
          ),
          child: Icon(icon, size: 20, color: enabled ? pal.textPrimary : pal.textSecondary.withOpacity(0.5)),
        ),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: pal.glassShadow, blurRadius: 32, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: playlist.isVirtual
                        ? Container(
                            width: 160,
                            height: 160,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8395F0), Color(0xFFB33F86)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.favorite, color: Colors.white, size: 64),
                            ),
                          )
                        : Image.network(playlist.coverUrl, width: 160, height: 160, fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) => Container(width: 160, height: 160, color: pal.surfaceHigh)),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playlist.isVirtual ? s.libraryLabel : s.playlistLabel,
                        style: TextStyle(fontSize: 12, color: pal.textPrimary)),
                    const SizedBox(height: 8),
                    Text(playlist.isVirtual ? s.likedLibraryName : playlist.name,
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: pal.textPrimary)),
                    const SizedBox(height: 8),
                    Text(playlist.isVirtual ? s.likedLibraryDescription : playlist.description,
                        style: TextStyle(color: pal.textSecondary)),
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

/// Главная по умолчанию: первые [MusicLibrary.homeTracksLimit] треков из
/// всех треков, загруженных в плеер (см. [MusicLibrary.homeTracks]) —
/// не привязано ни к какому конкретному плейлисту.
class _AllTracksContent extends StatelessWidget {
  final MusicLibrary library;
  const _AllTracksContent({required this.library});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final pal = AppColors.of(context);

    if (library.isLoadingAllTracks) {
      return Center(child: CircularProgressIndicator(color: pal.accent));
    }
    if (library.allTracks.isEmpty) {
      return Center(
        child: Text(s.libraryEmpty, style: TextStyle(color: pal.textSecondary)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              s.navHome,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: pal.textPrimary),
            ),
          ),
          TrackListView(tracks: library.homeTracks),
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
