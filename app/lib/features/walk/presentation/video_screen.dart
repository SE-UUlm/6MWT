import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'dhJVekHUkec',
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zurück-Button
              Transform.translate(
                offset: const Offset(-15, -1),
                child: IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Icon + Titel
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBlue,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      size: 50,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Text(
                    'Test Preparation',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // Beschreibung
              // Beschreibung
              const Text(
                'Walk back and forth along the marked distance (e.g. 6 meters), starting from the middle. Walk at your own pace.'
                ' If you are unsure how the test works, watch the video below for guidance.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 60),

              // Video-Karte
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: YoutubePlayerThumbnail(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    thumbnailQuality: ThumbnailQuality.high,
                    thumbnailFormat: ThumbnailFormat.webp,
                  ),
                ),
              ),

              const SizedBox(height: 245),

              // Continue-Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/walk', extra: widget.profileId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continueButton,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
