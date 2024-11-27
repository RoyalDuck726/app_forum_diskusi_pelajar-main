import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'forum_app.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    //tabel user + kolom badge
    await db.execute('''
      CREATE TABLE users(
        username TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        badge TEXT DEFAULT NULL
      )
    ''');

    //tabel post
    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        content TEXT NOT NULL,
        image TEXT,
        creator_id TEXT NOT NULL,
        upvotes INTEGER DEFAULT 0,
        downvotes INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (creator_id) REFERENCES users (username)
      )
    ''');

    //tabel komen
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        image TEXT,
        creator_id TEXT NOT NULL,
        upvotes INTEGER DEFAULT 0,
        downvotes INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
      )
    ''');

    //tabel votes di post
    await db.execute('''
      CREATE TABLE post_votes(
        post_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        vote_type TEXT NOT NULL,
        PRIMARY KEY (post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts (id),
        FOREIGN KEY (user_id) REFERENCES users (username)
      )
    ''');

    //tabel votes untuk komen
    await db.execute('''
      CREATE TABLE comment_votes(
        comment_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        vote_type TEXT NOT NULL,
        PRIMARY KEY (comment_id, user_id),
        FOREIGN KEY (comment_id) REFERENCES comments (id),
        FOREIGN KEY (user_id) REFERENCES users (username)
      )
    ''');

    //tabel sessions buat login
    await db.execute('''
      CREATE TABLE sessions(
        user_id TEXT PRIMARY KEY,
        is_logged_in INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (username)
      )
    ''');

    // Tabel categories dengan kolom icon
    await db.execute('''
      CREATE TABLE categories(
        name TEXT PRIMARY KEY,
        color TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'school'
      )
    ''');

    // Insert kategori default
    await db.insert('categories', {'name': 'Bahasa', 'color': 'orange', 'icon': 'translate'});
    await db.insert('categories', {'name': 'Sains', 'color': 'green', 'icon': 'science'});
    await db.insert('categories', {'name': 'Matematika', 'color': 'purple', 'icon': 'calculate'});
    await db.insert('categories', {'name': 'Lainnya', 'color': 'blue', 'icon': 'menu_book'});
  }

  //method posts
  Future<List<Map<String, dynamic>>> getPostsByCategory(String category) async {
    final db = await database;
    return await db.query(
      'posts',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC'
    );
  }

  Future<int> createPost(
    String category,
    String subCategory,
    String content,
    String creatorId,
    String imageBase64,
  ) async {
    final db = await database;
    final post = {
      'category': category,
      'sub_category': subCategory,
      'content': content,
      'creator_id': creatorId,
      'image': imageBase64,
      'upvotes': 0,
      'downvotes': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.insert('posts', post);
  }

  Future<int> createComment(
    int postId,
    String content,
    String? imageBase64,
    String creatorId
  ) async {
    final db = await database;
    final comment = {
      'post_id': postId,
      'content': content,
      'image': imageBase64,
      'creator_id': creatorId,
      'upvotes': 0,
      'downvotes': 0,
      'is_pinned': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.insert('comments', comment);
  }

  //method user
  Future<int> insertUser(String username, String password) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password': password,
      'role': 'user',
    });
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  //method login session
  Future<void> setUserLoggedIn(String userId) async {
    final db = await database;
    await db.insert(
      'sessions',
      {'user_id': userId, 'is_logged_in': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> logoutUser(String userId) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  //method akun server
  Future<bool> checkServerAccount() async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['server'],
    );
    return result.isNotEmpty;
  }

  Future<void> createServerAccount() async {
    final db = await database;
    await db.insert('users', {
      'username': 'server',
      'password': 'serveradmin123',
      'role': 'server',
    });
  }

  //method voting di post
  Future<void> votePost(int postId, String userId, String voteType) async {
    final db = await database;
    await db.insert(
      'post_votes',
      {
        'post_id': postId,
        'user_id': userId,
        'vote_type': voteType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getUserVoteStatus(int postId, String userId) async {
    final db = await database;
    final result = await db.query(
      'post_votes',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );
    return result.isNotEmpty ? result.first['vote_type'] as String : null;
  }

  //method voting di komen
  Future<void> voteComment(int commentId, String userId, String voteType) async {
    final db = await database;
    await db.insert(
      'comment_votes',
      {
        'comment_id': commentId,
        'user_id': userId,
        'vote_type': voteType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCommentVoteStatus(int commentId, String userId) async {
    final db = await database;
    final result = await db.query(
      'comment_votes',
      where: 'comment_id = ? AND user_id = ?',
      whereArgs: [commentId, userId],
    );
    return result.isNotEmpty ? result.first['vote_type'] as String : null;
  }

  Future<void> togglePinComment(int commentId, bool isPinned) async {
    final db = await database;
    await db.update(
      'comments',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  Future<void> deletePost(int postId) async {
    final db = await database;
    await db.transaction((txn) async {
      //hapus vote post terkait
      await txn.delete('post_votes', where: 'post_id = ?', whereArgs: [postId]);
      //hapus vote komen terkait
      await txn.delete(
        'comment_votes',
        where: 'comment_id IN (SELECT id FROM comments WHERE post_id = ?)',
        whereArgs: [postId],
      );
      //hapus komentar terkait
      await txn.delete('comments', where: 'post_id = ?', whereArgs: [postId]);
      //hapus post
      await txn.delete('posts', where: 'id = ?', whereArgs: [postId]);
    });
  }

  Future<bool> isUserLoggedIn(String userId) async {
    final db = await database;
    final result = await db.query(
      'sessions',
      where: 'user_id = ? AND is_logged_in = 1',
      whereArgs: [userId],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getPost(int postId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT p.*, 
        (SELECT COUNT(*) FROM post_votes WHERE post_id = p.id AND vote_type = 'up') as upvotes,
        (SELECT COUNT(*) FROM post_votes WHERE post_id = p.id AND vote_type = 'down') as downvotes
      FROM posts p
      WHERE p.id = ?
    ''', [postId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getCommentsByPostId(int postId) async {
    final db = await database;
    return await db.query(
      'comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'is_pinned DESC, created_at DESC'
    );
  }

  Future<void> deleteComment(int commentId) async {
    final db = await database;
    await db.transaction((txn) async {
      //hapus vote sama komen
      await txn.delete(
        'comment_votes',
        where: 'comment_id = ?',
        whereArgs: [commentId],
      );
      //hapus komentar
      await txn.delete(
        'comments',
        where: 'id = ?',
        whereArgs: [commentId],
      );
    });
  }

  //method badge
  Future<void> updateUserBadge(String username, String badge) async {
    final db = await database;
    await db.update(
      'users',
      {'badge': badge},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  //method semua user (untuk server)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(
      'users',
      where: 'role != ?',
      whereArgs: ['server'],
      orderBy: 'username ASC',
    );
  }

  //buat hapus user
  Future<void> deleteUser(String username) async {
    final db = await database;
    //mulai transaksi buat hapus data
    await db.transaction((txn) async {
      //hapus jejak vote dan login user
      await txn.delete('post_votes', where: 'user_id = ?', whereArgs: [username]);
      await txn.delete('comment_votes', where: 'user_id = ?', whereArgs: [username]);
      await txn.delete('sessions', where: 'user_id = ?', whereArgs: [username]);
      
      //beresin semua komentar user
      final comments = await txn.query('comments', where: 'creator_id = ?', whereArgs: [username]);
      for (var comment in comments) {
        await txn.delete('comment_votes', where: 'comment_id = ?', whereArgs: [comment['id']]);
      }
      await txn.delete('comments', where: 'creator_id = ?', whereArgs: [username]);
      
      //beresin semua postingan user
      final posts = await txn.query('posts', where: 'creator_id = ?', whereArgs: [username]);
      for (var post in posts) {
        await txn.delete('post_votes', where: 'post_id = ?', whereArgs: [post['id']]);
        await txn.delete('comments', where: 'post_id = ?', whereArgs: [post['id']]);
      }
      await txn.delete('posts', where: 'creator_id = ?', whereArgs: [username]);
      
      //sayonara user
      await txn.delete('users', where: 'username = ?', whereArgs: [username]);
    });
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        // Cek apakah tabel categories sudah ada
        final tables = await db.query('sqlite_master', 
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'categories']
        );
        
        if (tables.isEmpty) {
          print('Creating categories table...');
          // Buat tabel categories jika belum ada
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories(
              name TEXT PRIMARY KEY,
              color TEXT NOT NULL,
              icon TEXT NOT NULL DEFAULT 'school'
            )
          ''');

          // Insert kategori default hanya jika tabel baru dibuat
          await db.insert('categories', {'name': 'Bahasa', 'color': 'orange', 'icon': 'translate'});
          await db.insert('categories', {'name': 'Sains', 'color': 'green', 'icon': 'science'});
          await db.insert('categories', {'name': 'Matematika', 'color': 'purple', 'icon': 'calculate'});
          await db.insert('categories', {'name': 'Lainnya', 'color': 'blue', 'icon': 'menu_book'});
        } else {
          // Jika tabel sudah ada, cek apakah perlu menambah kolom icon
          final columns = await db.rawQuery('PRAGMA table_info(categories)');
          bool hasIconColumn = false;
          for (var column in columns) {
            if (column['name'] == 'icon') {
              hasIconColumn = true;
              break;
            }
          }
          
          if (!hasIconColumn) {
            // Tambah kolom icon jika belum ada
            await db.execute('ALTER TABLE categories ADD COLUMN icon TEXT NOT NULL DEFAULT \'school\'');
            
            // Update icon untuk kategori yang sudah ada
            await db.update('categories', {'icon': 'translate'}, where: 'name = ?', whereArgs: ['Bahasa']);
            await db.update('categories', {'icon': 'science'}, where: 'name = ?', whereArgs: ['Sains']);
            await db.update('categories', {'icon': 'calculate'}, where: 'name = ?', whereArgs: ['Matematika']);
            await db.update('categories', {'icon': 'menu_book'}, where: 'name = ?', whereArgs: ['Lainnya']);
          }
        }
        print('Database upgrade completed successfully');
      } catch (e) {
        print('Error during upgrade: $e');
      }
    }
  }

  // Tambahkan method untuk categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name');
  }

  Future<void> addCategory(String name, String color, String icon) async {
    final db = await database;
    await db.insert('categories', {
      'name': name,
      'color': color,
      'icon': icon,
    });
  }

  Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      try {
        // Dapatkan semua post dalam kategori ini
        final posts = await txn.query(
          'posts',
          where: 'category = ?',
          whereArgs: [name],
        );

        // Hapus semua data terkait untuk setiap post
        for (var post in posts) {
          final postId = post['id'] as int;
          
          // Hapus votes untuk komentar dari post ini
          await txn.delete(
            'comment_votes',
            where: 'comment_id IN (SELECT id FROM comments WHERE post_id = ?)',
            whereArgs: [postId],
          );
          
          // Hapus komentar dari post ini
          await txn.delete(
            'comments',
            where: 'post_id = ?',
            whereArgs: [postId],
          );
          
          // Hapus votes untuk post ini
          await txn.delete(
            'post_votes',
            where: 'post_id = ?',
            whereArgs: [postId],
          );
        }

        // Hapus semua post dalam kategori ini
        await txn.delete(
          'posts',
          where: 'category = ?',
          whereArgs: [name],
        );

        // Terakhir, hapus kategori
        final result = await txn.delete(
          'categories',
          where: 'name = ?',
          whereArgs: [name],
        );

        if (result == 0) {
          throw Exception('Kategori tidak ditemukan');
        }
      } catch (e) {
        print('Error in deleteCategory transaction: $e');
        rethrow; // Lempar error untuk ditangkap di UI
      }
    });
  }

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'forum_app.db');
    await deleteDatabase(path);
    _database = null;
    
    // Reinitialize database
    _database = await _initDatabase();
    
    // Create server account after reset
    await createServerAccount();
  }

  Future<void> updatePostVotes(int postId, int upvotes, int downvotes) async {
    final db = await database;
    await db.update(
      'posts',
      {
        'upvotes': upvotes,
        'downvotes': downvotes,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
  }


  // Method untuk mendapatkan status vote post
  Future<String?> getPostVoteStatus(int postId, String userId) async {
    final db = await database;
    final result = await db.query(
      'post_votes',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );
    return result.isNotEmpty ? result.first['vote_type'] as String : null;
  }

  // Method untuk update votes comment
  Future<void> updateCommentVotes(int commentId, int upvotes, int downvotes) async {
    final db = await database;
    await db.update(
      'comments',
      {
        'upvotes': upvotes,
        'downvotes': downvotes,
      },
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  Future<void> deletePostVote(int postId, String userId) async {
    final db = await database;
    await db.delete(
      'post_votes',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );
  }

  Future<void> deleteCommentVote(int commentId, String userId) async {
    final db = await database;
    await db.delete(
      'comment_votes',
      where: 'comment_id = ? AND user_id = ?',
      whereArgs: [commentId, userId],
    );
  }

  // Method untuk mendapatkan komentar berdasarkan ID
  Future<Map<String, dynamic>?> getCommentById(int commentId) async {
    final db = await database;
    final results = await db.query(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
