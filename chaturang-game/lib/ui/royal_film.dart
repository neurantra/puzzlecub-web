import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'theme.dart';

class RoyalFilmCard extends StatelessWidget {
  const RoyalFilmCard({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Semantics(
      button: true,
      label: 'Watch the royal game cinematic',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const RoyalFilmScreen()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.asset(
                'assets/video/royal-game-poster.jpg',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .9),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: 42,
                      color: ChaturangTheme.saffronLight,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch the royal game',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'A cinematic journey into Chaturang',
                            style: TextStyle(
                              color: Color(0xFFE6DFD3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RoyalFilmScreen extends StatefulWidget {
  const RoyalFilmScreen({super.key});
  @override
  State<RoyalFilmScreen> createState() => _RoyalFilmScreenState();
}

class _RoyalFilmScreenState extends State<RoyalFilmScreen>
    with WidgetsBindingObserver {
  late final VideoPlayerController _video;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _video = VideoPlayerController.asset('assets/video/royal-game.mp4');
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      _video.addListener(_update);
      setState(() {});
      await _video.play();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The film could not be opened. Please try again.',
        );
      }
    }
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _video.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video.removeListener(_update);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('The royal game'),
      backgroundColor: Colors.black,
    ),
    body: SafeArea(
      child: Center(
        child: _error != null
            ? Text(_error!)
            : !_video.value.isInitialized
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _video.value.aspectRatio,
                    child: VideoPlayer(_video),
                  ),
                  VideoProgressIndicator(
                    _video,
                    allowScrubbing: true,
                    padding: const EdgeInsets.all(16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: _video.value.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(
                          _video.value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                        ),
                        iconSize: 42,
                        onPressed: () async {
                          if (_video.value.isPlaying) {
                            await _video.pause();
                          } else {
                            if (_video.value.position >=
                                _video.value.duration) {
                              await _video.seekTo(Duration.zero);
                            }
                            await _video.play();
                          }
                        },
                      ),
                      IconButton(
                        tooltip: _video.value.volume == 0 ? 'Unmute' : 'Mute',
                        icon: Icon(
                          _video.value.volume == 0
                              ? Icons.volume_off
                              : Icons.volume_up,
                        ),
                        onPressed: () =>
                            _video.setVolume(_video.value.volume == 0 ? 1 : 0),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'A cinematic interpretation of a Chaturang opening.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFCAC6BE)),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
