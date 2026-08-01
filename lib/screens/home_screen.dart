import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../library/music_library.dart';
import '../localization/locale_controller.dart';
import '../models/nav_view.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/library_grid_view.dart';
import '../widgets/player_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_list_view.dart';

const _blue = Color(0xFF3D6BF0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NavEntry {
  final NavView view;
  final Playlist? playlist;
  const _NavEntry(this.view, this.playlist);
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  NavView _view = NavView.home;

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
      _searchController.clear();
      context.read<MusicLibrary>().search('');
    }
    if (view == NavView.home) {
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
    final showQueuePanel = _view == NavView.home && library.selectedPlaylist == null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Sidebar(activeView: _view, onNavSelect: _goTo, onPlaylistTap: (_) {}),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(pal.accentGlow.withOpacity(0.05), pal.background),
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
                          onSearchChanged: (q) {
                            library.search(q);
                            if (q.isNotEmpty && _view != NavView.search) _goTo(NavView.search);
                          },
                          onBack: _canGoBack ? _goBack : null,
                          onForward: _canGoForward ? _goForward : null,
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildContent(library)),
                              if (showQueuePanel) const _NowPlayingPanel(),
                            ],
                          ),
                        ),
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
        return LibraryGridView(playlists: library.playlists, onPlaylistTap: _openPlaylist);
      case NavView.home:
        return library.selectedPlaylist != null
            ? _PlaylistContent(library: library)
            : _DashboardContent(library: library, onPlaylistTap: _openPlaylist);
    }
  }
}

/// Верхняя панель: поиск на всю ширину + колокольчик + аватарка аккаунта.
/// Кнопки истории (назад/вперёд) — слева, как в референсе.
class _TopBar extends StatelessWidget {
  final NavView view;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const _TopBar({
    required this.view,
    required this.controller,
    required this.onSearchChanged,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final pal = AppColors.of(context);
    final auth = context.watch<AuthController>();
    final name = (auth.currentUserName?.trim().isNotEmpty ?? false) ? auth.currentUserName! : 'reynhardt';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Row(
        children: [
          _RoundButton(icon: Icons.chevron_left, onTap: onBack),
          const SizedBox(width: 8),
          _RoundButton(icon: Icons.chevron_right, onTap: onForward),
          const SizedBox(width: 20),
          Expanded(
            child: _GlassSurface(
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                style: TextStyle(color: pal.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  hintStyle: TextStyle(color: pal.textSecondary, fontSize: 13.5),
                  prefixIcon: Icon(Icons.search, color: pal.textSecondary, size: 20),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _GlassSurface(
                      borderRadius: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('Ctrl K', style: TextStyle(color: pal.textSecondary, fontSize: 11)),
                    ),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _RoundButton(icon: Icons.notifications_none_rounded, onTap: () {}),
          const SizedBox(width: 12),
          _AccountChip(name: name),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String name;
  const _AccountChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return _GlassSurface(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: _blue.withOpacity(0.3),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: pal.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(color: pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: pal.textSecondary),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _GlassSurface({
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: pal.glassBorder),
            color: pal.glassFill,
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
          width: 36,
          height: 36,
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

/// Главная панель по умолчанию: приветствие с погодой, карусель
/// "Продолжить прослушивание" и сетка "Для вас" — как в референсе.
class _DashboardContent extends StatelessWidget {
  final MusicLibrary library;
  final ValueChanged<Playlist> onPlaylistTap;
  const _DashboardContent({required this.library, required this.onPlaylistTap});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final auth = context.watch<AuthController>();
    final name = (auth.currentUserName?.trim().isNotEmpty ?? false) ? auth.currentUserName! : 'reynhardt';

    if (library.isLoadingAllTracks) {
      return Center(child: CircularProgressIndicator(color: pal.accent));
    }

    final continueTracks = library.homeTracks.take(4).toList();
    final forYou = library.playlists.take(6).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingBanner(name: name),
          const SizedBox(height: 28),
          if (continueTracks.isNotEmpty) ...[
            Text('Продолжить прослушивание',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: pal.textPrimary)),
            const SizedBox(height: 14),
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: continueTracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => _ContinueCard(track: continueTracks[i], queue: continueTracks, index: i),
              ),
            ),
            const SizedBox(height: 28),
          ],
          if (forYou.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text('Для вас',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: pal.textPrimary)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: pal.textSecondary),
                  child: const Text('Показать всё'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 18.0;
                const cardWidth = 176.0;
                final count = ((constraints.maxWidth + spacing) / (cardWidth + spacing)).floor().clamp(1, forYou.length);
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: forYou
                      .take(count)
                      .map((p) => _ForYouCard(playlist: p, width: cardWidth, onTap: () => onPlaylistTap(p)))
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  final String name;
  const _GreetingBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16233A), Color(0xFF0B111C)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Добрый вечер, $name',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: pal.textPrimary)),
                  const SizedBox(height: 10),
                  Text('Слушай музыку, которая\nпонимает тебя.',
                      style: TextStyle(fontSize: 14, color: pal.textSecondary, height: 1.4)),
                ],
              ),
            ),
            _GlassSurface(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop_rounded, color: Colors.white70, size: 20),
                  const SizedBox(height: 4),
                  Text('12°', style: TextStyle(color: pal.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Дождь', style: TextStyle(color: pal.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Track track;
  final List<Track> queue;
  final int index;
  const _ContinueCard({required this.track, required this.queue, required this.index});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final player = context.watch<PlayerController>();
    final progress = player.currentTrack?.id == track.id && player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.35;

    return SizedBox(
      width: 168,
      child: Material(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.read<PlayerController>().playFromList(queue, index),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    TrackArtwork(artworkUrl: track.artworkUrl, size: 152, borderRadius: BorderRadius.circular(8)),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _GlassSurface(
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 13, color: Colors.white),
                            if (track.duration > Duration.zero) ...[
                              const SizedBox(width: 2),
                              Text(_fmt(track.duration), style: const TextStyle(fontSize: 10, color: Colors.white)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2)),
                Text(track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: pal.textSecondary, fontSize: 11.5, height: 1.2)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: pal.sliderInactive,
                      valueColor: AlwaysStoppedAnimation(pal.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForYouCard extends StatelessWidget {
  final Playlist playlist;
  final double width;
  final VoidCallback onTap;
  const _ForYouCard({required this.playlist, required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: playlist.isVirtual
                        ? Container(
                            width: width,
                            height: width,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8395F0), Color(0xFFB33F86)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(child: Icon(Icons.favorite, color: Colors.white, size: 44)),
                          )
                        : Image.network(
                            playlist.coverUrl,
                            width: width,
                            height: width,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: width, height: width, color: pal.surfaceHigh),
                          ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(playlist.isVirtual ? 'Ночной вайб' : playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: pal.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(playlist.description.isNotEmpty ? playlist.description : 'Подборка для тебя',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: pal.textSecondary, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Правая панель "Сейчас играет" с обложкой, сид-баром и очередью —
/// как в референсе. Показывается только на Главной вне открытого плейлиста.
class _NowPlayingPanel extends StatelessWidget {
  const _NowPlayingPanel();

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final player = context.watch<PlayerController>();
    final track = player.currentTrack;

    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(0, 4, 20, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Сейчас играет',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: pal.textPrimary)),
                ),
                Icon(Icons.open_in_full_rounded, size: 16, color: pal.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            if (track == null)
              _EmptyNowPlaying(pal: pal)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: TrackArtwork(artworkUrl: track.artworkUrl, size: 260, borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: pal.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: pal.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite, color: _blue, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(_fmt(player.position), style: TextStyle(color: pal.textSecondary, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _blue,
                        thumbColor: _blue,
                        inactiveTrackColor: pal.sliderInactive,
                      ),
                      child: Slider(
                        value: player.duration.inMilliseconds > 0
                            ? player.position.inMilliseconds.clamp(0, player.duration.inMilliseconds).toDouble()
                            : 0,
                        max: player.duration.inMilliseconds > 0 ? player.duration.inMilliseconds.toDouble() : 1,
                        onChanged: (v) => player.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                  ),
                  Text(_fmt(player.duration), style: TextStyle(color: pal.textSecondary, fontSize: 11)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text('Далее в очереди',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pal.textPrimary)),
            const SizedBox(height: 10),
            ...player.queue.skip(player.queue.isEmpty ? 0 : (player.queue.indexOf(track ?? player.queue.first) + 1))
                .take(6)
                .map((t) => _QueueRow(track: t)),
          ],
        ),
      ),
    );
  }
}

class _EmptyNowPlaying extends StatelessWidget {
  final AppPalette pal;
  const _EmptyNowPlaying({required this.pal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: pal.surface),
      alignment: Alignment.center,
      child: Icon(Icons.music_note, size: 48, color: pal.textSecondary.withOpacity(0.5)),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final Track track;
  const _QueueRow({required this.track});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final player = context.read<PlayerController>();
            final idx = player.queue.indexOf(track);
            if (idx >= 0) player.playFromList(player.queue, idx);
          },
          child: Row(
            children: [
              TrackArtwork(artworkUrl: track.artworkUrl, size: 40, borderRadius: BorderRadius.circular(6)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: pal.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              Text(_fmt(track.duration), style: TextStyle(color: pal.textSecondary, fontSize: 11.5)),
            ],
          ),
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
