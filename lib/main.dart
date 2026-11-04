import 'package:flutter/material.dart';
import 'models/diary.dart';
import 'database/diary_database.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          surface: const Color(0xFFF5F6F8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        useMaterial3: true,
      ),
      home: const DiaryListScreen(),
    );
  }
}

// 日記一覧画面
class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<Diary> _diaries = [];

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  // データベースから日記を読み込む
  Future<void> _loadDiaries() async {
    final diaries = await DiaryDatabase.instance.getAllDiaries();

    if (!mounted) return;

    setState(() {
      _diaries = diaries;
    });
  }

  // 日記作成画面へ移動する
  Future<void> _openEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiaryEditorScreen()),
    );

    if (result == true) {
      _loadDiaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Note',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
      ),
      body: _diaries.isEmpty
          ? const Center(
              child: Text('日記はまだありません', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final diary = _diaries[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      diary.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          diary.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${diary.createdAt.year}年'
                          '${diary.createdAt.month}月'
                          '${diary.createdAt.day}日',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryDetailScreen(diary: diary),
                        ),
                      );

                      if (result == true) {
                        _loadDiaries();
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          '日記を書く',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// 日記作成・編集画面
class DiaryEditorScreen extends StatefulWidget {
  final Diary? diary;

  const DiaryEditorScreen({super.key, this.diary});

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 編集の場合は、既存の日記を入力欄に表示する
    if (widget.diary != null) {
      _titleController.text = widget.diary!.title;
      _contentController.text = widget.diary!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 日記を保存・更新する
  Future<void> _saveDiary() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('タイトルと本文を入力してください')));
      return;
    }

    final now = DateTime.now();

    final diary = Diary(
      id: widget.diary?.id,
      title: title,
      content: content,
      createdAt: widget.diary?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.diary == null) {
      await DiaryDatabase.instance.insertDiary(diary);
    } else {
      await DiaryDatabase.instance.updateDiary(diary);
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.diary != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '日記を編集' : '日記を書く')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '本文',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDiary,
              child: Text(isEditing ? '更新する' : '保存する'),
            ),
          ],
        ),
      ),
    );
  }
}

// 日記詳細画面
class DiaryDetailScreen extends StatefulWidget {
  final Diary diary;

  const DiaryDetailScreen({super.key, required this.diary});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  // 編集画面を開く
  Future<void> _editDiary() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorScreen(diary: widget.diary),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // 日記を削除する
  Future<void> _deleteDiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('日記を削除'),
          content: const Text('この日記を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (widget.diary.id == null) return;

    await DiaryDatabase.instance.deleteDiary(widget.diary.id!);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.diary.createdAt;

    final formattedDate = '${date.year}年${date.month}月${date.day}日';

    return Scaffold(
      appBar: AppBar(
        title: const Text('日記の詳細'),
        actions: [
          IconButton(
            onPressed: _editDiary,
            icon: const Icon(Icons.edit),
            tooltip: '編集',
          ),
          IconButton(
            onPressed: _deleteDiary,
            icon: const Icon(Icons.delete),
            tooltip: '削除',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.diary.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.diary.content,
                  style: const TextStyle(fontSize: 16, height: 1.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
