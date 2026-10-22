import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news.dart';
import 'ui.dart';

/// Opens [url] in the external browser; SnackBar if it can't.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  // Web only supports platformDefault (= new tab); mobile opens the external browser.
  final mode = kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
  Object? error;
  final ok = await launchUrl(Uri.parse(url), mode: mode).catchError((Object e) {
    error = e;
    return false;
  });
  if (!ok) {
    debugPrint('openExternal($url) failed: $error');
    messenger.showSnackBar(const SnackBar(content: Text('Không mở được liên kết')));
  }
}

/// News cover image with a placeholder when it fails to load.
class NewsImage extends StatelessWidget {
  final String path;
  const NewsImage(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: cs.outline),
    );
    final url = imageUrl(path);
    if (url == null) return placeholder;
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
  }
}

/// Auto-advancing (5s) page carousel of the newest news; tap opens the link.
class NewsCarousel extends StatefulWidget {
  final List<News> items;
  const NewsCarousel(this.items, {super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  /// Auto-advance every 5 s; restarted on every manual move so a slide never jumps right after a tap/swipe.
  void _restartTimer() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _go(1, manual: false));
  }

  /// Move by [delta] pages, wrapping around at both ends.
  void _go(int delta, {bool manual = true}) {
    if (!_controller.hasClients) return;
    final n = widget.items.length;
    _controller.animateToPage(
      (_page + delta + n) % n,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    if (manual) _restartTimer();
  }

  Widget _arrow(Alignment align, IconData icon, String tooltip, int delta) => Align(
    alignment: align,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.85)),
        icon: Icon(icon),
        onPressed: () => _go(delta),
      ),
    ),
  );

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              NotificationListener<ScrollStartNotification>(
                // A finger swipe also counts as manual: restart the auto-play countdown.
                onNotification: (n) {
                  if (n.dragDetails != null) _restartTimer();
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.items.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final n = widget.items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => openExternal(context, n.url),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NewsImage(n.imagePath),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black87],
                                    stops: [0.45, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 12,
                                child: Text(
                                  n.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (widget.items.length > 1) ...[
                _arrow(Alignment.centerLeft, Icons.chevron_left, 'Tin trước', -1),
                _arrow(Alignment.centerRight, Icons.chevron_right, 'Tin sau', 1),
              ],
            ],
          ),
        ),
        if (widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One row in the news list: 64×64 thumbnail + title (max 2 lines).
class NewsTile extends StatelessWidget {
  final News news;
  final Widget? trailing;
  const NewsTile(this.news, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 64, height: 64, child: NewsImage(news.imagePath)),
        ),
        title: Text(news.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(fmtDate(news.createdAt)),
        trailing: trailing,
        onTap: () => openExternal(context, news.url),
      ),
    );
  }
}
