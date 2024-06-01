import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:gap/gap.dart';
import 'package:html/parser.dart' as parser;
import 'package:markdown/markdown.dart' as md;
import 'package:open_local_ui/services/tts.dart';
import 'package:open_local_ui/utils/logger.dart';
import 'package:unicons/unicons.dart';

class TTSPlayer extends StatefulWidget {
  final String text;
  final Function onPlayerClosed;
  final Function(double) onPlaybackRateChanged;

  const TTSPlayer({
    super.key,
    required this.text,
    required this.onPlayerClosed,
    required this.onPlaybackRateChanged,
  });

  @override
  State<TTSPlayer> createState() => _TTSPlayerState();
}

class _TTSPlayerState extends State<TTSPlayer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<int> _audioBytes = [];
  bool _isLoaded = false;
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  double _progress = 0.0;
  Duration _totalDuration = Duration.zero;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.paused) {
        setState(() {
          _isPlaying = false;
        });
      } else if (state == PlayerState.playing) {
        setState(() {
          _isPlaying = true;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((duration) {
      if (_totalDuration.inMilliseconds > 0) {
        setState(() {
          _currentDuration = duration;

          _progress = clampDouble(
            duration.inMilliseconds / _totalDuration.inMilliseconds,
            0.0,
            1.0,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();

    super.dispose();
  }

  Future<bool> _load() async {
    final service = TTSService();

    final html = md.markdownToHtml(widget.text);
    final document = parser.parse(html);
    final text = document.body!.text;

    try {
      _audioBytes = await service.synthesize(text);

      await _audioPlayer.setSource(
        BytesSource(
          Uint8List.fromList(_audioBytes),
        ),
      );
    } catch (e) {
      logger.e(e);

      _isLoaded = false;

      return false;
    }

    _isLoaded = true;

    return true;
  }

  Future<void> _play() async {
    if (!_isLoaded) {
      await _load();

      setState(() {
        _isLoaded = true;
      });
    }

    setState(() {
      _isPlaying = true;
    });

    await _audioPlayer.seek(_currentDuration);
    await _audioPlayer.resume();

    _audioPlayer.setPlaybackRate(_playbackRate);

    final totalDuration = await _audioPlayer.getDuration();

    setState(() {
      _totalDuration = totalDuration ?? Duration.zero;
    });
  }

  Future<void> _pause() async {
    setState(() {
      _isPlaying = false;
    });

    await _audioPlayer.pause();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(
          Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          const Gap(8.0),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (_isPlaying) {
                await _pause();
              } else {
                await _play();
              }
            },
          ),
          const Gap(8.0),
          Text(
            '${_formatDuration(_currentDuration)}/${_formatDuration(_totalDuration)}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          const Gap(8.0),
          TextButton.icon(
            icon: const Icon(Icons.speed),
            label: Text(_playbackRate.toStringAsFixed(2)),
            onPressed: () {
              late double newPlaybackRate;

              switch (_playbackRate) {
                case 1.0:
                  newPlaybackRate = 1.25;
                  break;
                case 1.25:
                  newPlaybackRate = 1.5;
                  break;
                case 1.5:
                  newPlaybackRate = 0.5;
                  break;
                case 0.5:
                  newPlaybackRate = 0.75;
                  break;
                case 0.75:
                  newPlaybackRate = 1.0;
                  break;
              }

              setState(() {
                _playbackRate = newPlaybackRate;
              });

              if (_isPlaying) {
                widget.onPlaybackRateChanged(newPlaybackRate);

                _audioPlayer.setPlaybackRate(newPlaybackRate);
              }
            },
          ),
          const Gap(8.0),
          Expanded(
            child: Slider(
              value: _progress,
              onChanged: (value) {
                final newDuration = Duration(
                  milliseconds: (_totalDuration.inMilliseconds * value).toInt(),
                );

                _audioPlayer.seek(newDuration);

                if (context.mounted) {
                  setState(() {
                    _currentDuration = newDuration;
                    _progress = value;
                  });
                }
              },
              min: 0.0,
              max: 1.0,
            ),
          ),
          const Gap(8.0),
          IconButton(
            onPressed: () {
              _audioPlayer.stop();

              widget.onPlayerClosed();
            },
            icon: const Icon(UniconsLine.times),
          ),
          const Gap(8.0),
        ],
      ),
    );
  }
}
