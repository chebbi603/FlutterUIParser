import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NetworkOrAssetImage extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  const NetworkOrAssetImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  bool get isNetwork => src.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final image =
        isNetwork
            ? Image.network(src, fit: fit, width: width, height: height)
            : Image.asset(src, fit: fit, width: width, height: height);
    return image;
  }
}

class SimpleAudioPlayer extends StatefulWidget {
  final String src;
  const SimpleAudioPlayer({super.key, required this.src});
  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  final player = AudioPlayer();
  bool playing = false;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      child: Text(playing ? 'Pause Audio' : 'Play Audio'),
      onPressed: () async {
        if (playing) {
          await player.pause();
        } else {
          final src = widget.src;
          if (src.startsWith('http')) {
            await player.play(UrlSource(src));
          } else {
            await player.play(AssetSource(src));
          }
        }
        setState(() => playing = !playing);
      },
    );
  }
}

class SimpleVideoPlayer extends StatefulWidget {
  final String src;
  const SimpleVideoPlayer({super.key, required this.src});
  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  late VideoPlayerController controller;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    controller =
        widget.src.startsWith('http')
            ? VideoPlayerController.networkUrl(Uri.parse(widget.src))
            : VideoPlayerController.asset(widget.src);
    controller.initialize().then((_) {
      setState(() => initialized = true);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(controller),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            child: Icon(
              controller.value.isPlaying
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
            ),
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
          ),
        ],
      ),
    );
  }
}

class SimpleWebView extends StatefulWidget {
  final String url;
  const SimpleWebView({super.key, required this.url});

  @override
  State<SimpleWebView> createState() => _SimpleWebViewState();
}

class _SimpleWebViewState extends State<SimpleWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
