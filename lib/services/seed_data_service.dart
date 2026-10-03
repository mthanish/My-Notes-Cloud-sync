import 'package:uuid/uuid.dart';
import '../core/utils/crypto_vault_util.dart';
import '../models/mind_map_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../models/vault_item_model.dart';
import 'local_storage_service.dart';

class SeedDataService {
  final LocalStorageService _storage;

  SeedDataService(this._storage);

  Future<void> seedInitialDataIfFirstRun({required String userId}) async {
    final alreadySeeded = _storage.getHasSeededData();
    if (alreadySeeded) return;

    final now = DateTime.now();

    // 1. Mind Map Data structure for Dropshipping Plan
    final rootNode = MindMapNode(
      text: 'Dropshipping Plan',
      children: [
        MindMapNode(
          text: 'Website',
          children: [
            MindMapNode(text: 'Shopify (paid)'),
            MindMapNode(text: 'Ecwid (free)'),
            MindMapNode(text: 'Custom store (free trial)'),
          ],
        ),
        MindMapNode(
          text: 'Products',
          children: [
            MindMapNode(text: 'Printify'),
            MindMapNode(text: 'Alibaba'),
            MindMapNode(text: 'Local suppliers'),
            MindMapNode(text: 'Direct logistics'),
          ],
        ),
        MindMapNode(
          text: 'Marketing',
          children: [
            MindMapNode(text: 'Organic short-form reels'),
            MindMapNode(text: 'Platform ad campaigns'),
            MindMapNode(text: 'Influencer reviews'),
          ],
        ),
        MindMapNode(
          text: 'Payment gateway',
          children: [
            MindMapNode(text: 'Stripe payments'),
            MindMapNode(text: 'UPI / Direct transfer'),
          ],
        ),
      ],
    );

    final seedNotes = [
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Quotes',
        content: 'Ab zakham bhar gye hai mere, Ab aye ho?\nAb dard mit gye hai mere, Ab aye ho?\n\n'
            'Ab mujhme mein baki bhi nhi bacha, Ab khudko mujhme dhundne aye ho?\n\n'
            'Ab kisi bi mod pr jaan chod skta hu, Kisi bi mod pr aas chod skta hu, Mera qatal karke chle gye the, tum ab aye ho?\n\n'
            '"Kaun kehta hai hum tabaah nahi hain,\n'
            'Meri barbaadi ka bas Koi gawaah nahi hai,\n'
            'Sab dekhte hain mujhe muskurate huwe,\n'
            'Kyun ki rone ke liye Koi jagah nahi hai."',
        type: NoteType.text,
        createdAt: DateTime(now.year, 9, 11, 21, 23),
        updatedAt: DateTime(now.year, 9, 11, 21, 23),
        isPinned: true,
        category: 'notes',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Mein shayar to...',
        content: 'Us raat maine usay kuch yun dekha,\nJaise kisi ne pehli baar chaand ko ho dekha...',
        type: NoteType.text,
        createdAt: DateTime(now.year, 7, 1, 14, 10),
        updatedAt: DateTime(now.year, 7, 1, 14, 10),
        category: 'notes',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Movies to watch',
        content: 'Laapata ladies\nLaila majnu\nGran turismo\nRockstar\nInterstellar\nDead Poets Society',
        type: NoteType.text,
        createdAt: DateTime(now.year, 6, 16, 19, 45),
        updatedAt: DateTime(now.year, 6, 16, 19, 45),
        category: 'notes',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'winners',
        content: 'Lemon and spoon 1st game 5-6\nZanoor\nLemon and spoon 2nd game 7-8\nFarhan',
        type: NoteType.text,
        createdAt: DateTime(now.year, 1, 1, 10, 0),
        updatedAt: DateTime(now.year, 1, 1, 10, 0),
        category: 'notes',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Dropshipping...',
        content: 'Interactive Mind-Map Plan for eCommerce & suppliers',
        type: NoteType.mindMap,
        mindMapData: rootNode.toMap(),
        createdAt: DateTime(2025, 9, 24, 18, 20),
        updatedAt: DateTime(2025, 9, 24, 18, 20),
        category: 'notes',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Mummy...',
        content: 'Banking portal safety info\nAccount pass-keys encrypted in vault',
        type: NoteType.vault,
        createdAt: DateTime(2025, 7, 21, 11, 15),
        updatedAt: DateTime(2025, 7, 21, 11, 15),
        category: 'passwords',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Books',
        content: 'Surrounded by idiots\nAtomic Habits\nPsychology of Money\nDeep Work',
        type: NoteType.text,
        createdAt: DateTime(2025, 6, 13, 16, 30),
        updatedAt: DateTime(2025, 6, 13, 16, 30),
        category: 'notes',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'SBI PW',
        content: 'Protected Credential Card\nDouble encrypted with AES-256 Vault',
        type: NoteType.vault,
        createdAt: DateTime(2025, 5, 10, 9, 0),
        updatedAt: DateTime(2025, 5, 10, 9, 0),
        category: 'passwords',
      ),
      NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Ideas',
        content: 'Scrap app\nLocal audio journal with zero latency\nCross-device offline PWA',
        type: NoteType.text,
        createdAt: DateTime(2025, 4, 1, 22, 10),
        updatedAt: DateTime(2025, 4, 1, 22, 10),
        category: 'Uncategorised',
      ),
    ];

    await _storage.saveNotes(seedNotes);

    // Initial Vault Items (Encrypted with default seed pin: '1234')
    const seedPin = '1234';
    final enc1 = CryptoVaultUtil.encryptString('SecretBankingPass@2026', seedPin);
    final enc2 = CryptoVaultUtil.encryptString('User7349#VaultSecure', seedPin);

    final seedVaultItems = [
      VaultItemModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'SBI Net Banking',
        accountName: 'Thanish7349',
        encryptedPassword: enc1.ciphertext,
        iv: enc1.iv,
        salt: enc1.salt,
        notes: 'Personal savings bank credentials',
        updatedAt: DateTime(2025, 7, 21),
      ),
      VaultItemModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Cloud Workstation',
        accountName: 'admin@workstation.io',
        encryptedPassword: enc2.ciphertext,
        iv: enc2.iv,
        salt: enc2.salt,
        notes: 'SSH & Root access key',
        updatedAt: DateTime(2025, 5, 10),
      ),
    ];

    for (final v in seedVaultItems) {
      await _storage.saveVaultItem(v);
    }

    // Set default vault PIN hash
    final salt = CryptoVaultUtil.generateRandomBytes(16);
    final hash = CryptoVaultUtil.hashPin(seedPin, String.fromCharCodes(salt));
    await _storage.saveVaultPin(hash, String.fromCharCodes(salt));

    // Initial Tasks
    final seedTasks = [
      TaskModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Complete cross-device MI Notes build',
        isCompleted: false,
        dueDate: now.add(const Duration(days: 1)),
        priority: TaskPriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      TaskModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Verify offline SQLite / Hive cache persistence',
        isCompleted: true,
        dueDate: now,
        priority: TaskPriority.medium,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      TaskModel(
        id: const Uuid().v4(),
        userId: userId,
        title: 'Test Firestore multi-device real-time sync',
        isCompleted: false,
        dueDate: now.add(const Duration(days: 2)),
        priority: TaskPriority.high,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    await _storage.saveTasks(seedTasks);
    await _storage.setHasSeededData(true);
  }
}
