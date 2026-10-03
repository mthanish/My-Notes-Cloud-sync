import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/note_model.dart';
import 'widgets/drawing_canvas_modal.dart';
import 'widgets/editor_toolbar.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _contentFocusNode;

  final List<String> _history = [];
  int _historyIndex = -1;

  Timer? _debounceSaveTimer;
  late String _currentId;
  String _category = 'notes';
  bool _isPinned = false;
  NoteType _type = NoteType.text;
  DateTime _createdAt = DateTime.now();
  final List<NoteAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _contentFocusNode = FocusNode();

    _currentId = widget.noteId ?? const Uuid().v4();

    // Load existing note if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.noteId != null) {
        final repo = ref.read(notesRepositoryProvider);
        final existing = repo.getNoteById(widget.noteId!);
        if (existing != null) {
          setState(() {
            _titleController.text = existing.title;
            _contentController.text = existing.content;
            _category = existing.category;
            _isPinned = existing.isPinned;
            _type = existing.type;
            _createdAt = existing.createdAt;
            _attachments.addAll(existing.attachments);
            _saveHistoryState();
          });
        }
      } else {
        _saveHistoryState();
      }
    });

    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 700), () {
      _saveNoteLocallyAndRemote();
      _saveHistoryState();
    });
  }

  void _saveHistoryState() {
    final state = '${_titleController.text}|||${_contentController.text}';
    if (_history.isEmpty || _history[_historyIndex] != state) {
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(state);
      _historyIndex = _history.length - 1;
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        final parts = _history[_historyIndex].split('|||');
        _titleController.text = parts[0];
        _contentController.text = parts.length > 1 ? parts[1] : '';
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        final parts = _history[_historyIndex].split('|||');
        _titleController.text = parts[0];
        _contentController.text = parts.length > 1 ? parts[1] : '';
      });
    }
  }

  Future<void> _saveNoteLocallyAndRemote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Avoid saving completely blank notes
    if (title.isEmpty && content.isEmpty && _attachments.isEmpty) {
      return;
    }

    final auth = ref.read(authServiceProvider);
    final repo = ref.read(notesRepositoryProvider);

    final note = NoteModel(
      id: _currentId,
      userId: auth.currentUid,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      type: _type,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      isPinned: _isPinned,
      category: _category,
      attachments: _attachments,
    );

    await repo.saveNote(note);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final auth = ref.read(authServiceProvider);
        final storage = ref.read(storageServiceProvider);

        final url = await storage.uploadImageBytes(
          uid: auth.currentUid,
          bytes: bytes,
          customName: '${const Uuid().v4()}.jpg',
        );

        setState(() {
          _attachments.add(NoteAttachment(
            id: const Uuid().v4(),
            url: url,
            name: picked.name,
            type: 'image',
          ));
        });
        _saveNoteLocallyAndRemote();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    }
  }

  Future<void> _openDrawing() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (ctx) => const DrawingCanvasModal()),
    );
    if (result != null) {
      setState(() {
        final current = _contentController.text;
        _contentController.text = current.isEmpty ? '🎨 $result' : '$current\n🎨 $result';
      });
      _saveNoteLocallyAndRemote();
    }
  }

  void _insertChecklist() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    const checklistPrefix = '\n☐ ';

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, checklistPrefix);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + checklistPrefix.length),
      );
    } else {
      _contentController.text = '$text$checklistPrefix';
    }
  }

  void _showFormattingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.format_bold_rounded, color: AppColors.textPrimary),
              title: const Text('Bold Text', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                _wrapSelection('**', '**');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_italic_rounded, color: AppColors.textPrimary),
              title: const Text('Italic Text', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                _wrapSelection('*', '*');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.textPrimary),
              title: const Text('Bullet List', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                _insertPrefix('• ');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_quote_rounded, color: AppColors.textPrimary),
              title: const Text('Quote Block', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                _insertPrefix('> ');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (sel.isValid && sel.start >= 0 && sel.end > sel.start) {
      final selectedText = text.substring(sel.start, sel.end);
      final replaced = '$prefix$selectedText$suffix';
      final newText = text.replaceRange(sel.start, sel.end, replaced);
      _contentController.text = newText;
    }
  }

  void _insertPrefix(String prefix) {
    final text = _contentController.text;
    _contentController.text = '$text\n$prefix';
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _saveNoteLocallyAndRemote();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.iconPrimary),
            onPressed: () async {
              await _saveNoteLocallyAndRemote();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            // Undo
            IconButton(
              icon: const Icon(Icons.undo_rounded, size: 22, color: AppColors.iconSecondary),
              tooltip: 'Undo',
              onPressed: _undo,
            ),
            // Redo
            IconButton(
              icon: const Icon(Icons.redo_rounded, size: 22, color: AppColors.iconSecondary),
              tooltip: 'Redo',
              onPressed: _redo,
            ),
            // Done / Save Checkmark
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 26, color: AppColors.iconPrimary),
              tooltip: 'Save',
              onPressed: () async {
                await _saveNoteLocallyAndRemote();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Main Text Writing Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    TextField(
                      controller: _titleController,
                      style: AppTypography.noteDetailTitle,
                      cursorColor: AppColors.accent,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 16),

                    // Body Input
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      style: AppTypography.noteBody,
                      cursorColor: AppColors.accent,
                      cursorWidth: 2.2,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    // Attachments preview
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments.map((att) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attachment_rounded, size: 16, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Text(
                                  att.name,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Bottom Keyboard-Aware Toolbar matching screenshot
            SafeArea(
              top: false,
              child: EditorToolbar(
                onVoiceTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice input ready'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onImageTap: _pickImage,
                onDrawingTap: _openDrawing,
                onChecklistTap: _insertChecklist,
                onTypographyTap: _showFormattingSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
