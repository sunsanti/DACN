import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/dio_client.dart';
import '../core/news_ui.dart';
import '../core/ui.dart';
import '../models/news.dart';
import '../providers/admin_provider.dart';

/// Admin: list / add / delete health & hospital news shown to patients.
class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await context.read<AdminProvider>().loadNews();
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.messageFrom(e));
    }
  }

  Future<void> _delete(News n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tin tức?'),
        content: Text(n.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AdminProvider>().deleteNews(n.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = context.watch<AdminProvider>().news;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const _AddNewsScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Thêm tin'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? EmptyState(Icons.cloud_off, 'Lỗi tải dữ liệu:\n$_error')
            : news.isEmpty
                ? const EmptyState(Icons.newspaper, 'Chưa có tin tức.\nNhấn "Thêm tin" để tạo.')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      for (final n in news)
                        NewsTile(
                          n,
                          trailing: IconButton(
                            tooltip: 'Xoá',
                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            onPressed: () => _delete(n),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _AddNewsScreen extends StatefulWidget {
  const _AddNewsScreen();

  @override
  State<_AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<_AddNewsScreen> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  XFile? _image;
  bool _saving = false;

  bool get _valid {
    final u = Uri.tryParse(_url.text.trim());
    return _title.text.trim().isNotEmpty &&
        u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty &&
        _image != null;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (f != null) setState(() => _image = f);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AdminProvider>().addNews(_title.text.trim(), _url.text.trim(), _image!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(DioClient.messageFrom(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm tin tức')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pick,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _image == null
                    ? Container(
                        color: cs.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: cs.primary),
                            const SizedBox(height: 6),
                            const Text('Chọn ảnh đại diện cho tin'),
                          ],
                        ),
                      )
                    : FutureBuilder(
                        future: _image!.readAsBytes(),
                        builder: (_, s) => s.hasData
                            ? Image.memory(s.data!, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Link bài viết (https://...)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _valid && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
