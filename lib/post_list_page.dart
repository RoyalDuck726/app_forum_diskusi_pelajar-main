import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PostListPage extends StatefulWidget {
  final String category;
  final String currentUserId;
  final String userRole;
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  PostListPage({
    required this.category,
    required this.currentUserId,
    required this.userRole,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  _PostListPageState createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> posts = [];
  String? imageBase64;
  
  final Map<String, List<String>> subCategories = {
    'akademik': ['Tugas', 'Ujian', 'Materi'],
    'non-akademik': ['Kegiatan', 'Pengumuman', 'Lainnya'],
    'mapel': ['Matematika', 'Bahasa Indonesia', 'Bahasa Inggris', 'IPA', 'IPS', 'Agama', 'PPKN', 'Lainnya'],
    // Add more categories and their subcategories as needed
  };

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final loadedPosts = await dbHelper.getPostsByCategory(widget.category);
    setState(() {
      posts = loadedPosts;
    });
  }

  void _toggleTheme() {
    widget.toggleTheme();
    setState(() {
      // Force rebuild UI dengan tema baru
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text('Kategori: ${widget.category}'),
        backgroundColor: isDark ? Colors.grey[850] : Colors.blue,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.brightness_7 : Icons.brightness_2),
            onPressed: () {
              widget.toggleTheme();
              setState(() {}); // Force rebuild
            },
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: dbHelper.getCommentsByPostId(post['id']),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header post
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
                              child: Text(
                                (post['creator_id']?.toString().isNotEmpty == true) 
                                    ? post['creator_id'].toString()[0].toUpperCase()
                                    : '?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      post['creator_id'].toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey[300] : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: dbHelper.getUser(post['creator_id'].toString()),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data != null) {
                                          final userData = snapshot.data!;
                                          return Row(
                                            children: [
                                              if (userData['badge'] != null) ...[
                                                _buildBadge(userData['badge']),
                                                SizedBox(width: 8),
                                              ],
                                              if (userData['role'] == 'server')
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.red, width: 1),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.admin_panel_settings, size: 14, color: Colors.red),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Admin',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        }
                                        return SizedBox();
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      post['sub_category'].toString(),
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _formatDateTime(post['created_at']),
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Spacer(),
                            if (post['creator_id'] == widget.currentUserId || 
                                widget.userRole == 'server')
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                onPressed: () => _deletePost(post['id']),
                              ),
                          ],
                        ),
                      ),
                      // Konten post
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildPostContent(post),
                      ),
                      // Voting dan komentar
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            FutureBuilder<String?>(
                              future: dbHelper.getUserVoteStatus(post['id'], widget.currentUserId),
                              builder: (context, voteSnapshot) {
                                final voteStatus = voteSnapshot.data;
                                return Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_upward,
                                        color: voteStatus == 'up'
                                            ? Colors.blue
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                      onPressed: () => _votePost(post['id'], 'up'),
                                    ),
                                    Text(
                                      '${post['upvotes'] ?? 0}',
                                      style: TextStyle(
                                        color: voteStatus == 'up'
                                            ? Colors.blue
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_downward,
                                        color: voteStatus == 'down'
                                            ? Colors.orange
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                      onPressed: () => _votePost(post['id'], 'down'),
                                    ),
                                    Text(
                                      '${post['downvotes'] ?? 0}',
                                      style: TextStyle(
                                        color: voteStatus == 'down'
                                            ? Colors.orange
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Spacer(),
                            TextButton.icon(
                              onPressed: () => _showCommentDialog(post['id']),
                              icon: Icon(
                                Icons.comment,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              label: Text(
                                'Komentar (${comments.length})',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Daftar komentar
                      if (comments.isNotEmpty) ...[
                        Divider(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment['creator_id'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[300] : Colors.black87,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: dbHelper.getUser(comment['creator_id'].toString()),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data != null) {
                                            final userData = snapshot.data!;
                                            return Row(
                                              children: [
                                                if (userData['badge'] != null) ...[
                                                  _buildBadge(userData['badge']),
                                                  SizedBox(width: 8),
                                                ],
                                                if (userData['role'] == 'server')
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.red, width: 1),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.admin_panel_settings, size: 14, color: Colors.red),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Admin',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            );
                                          }
                                          return SizedBox();
                                        },
                                      ),
                                      Text(
                                        _formatDateTime(comment['created_at']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      if (comment['badge'] != null) _buildBadge(comment['badge']),
                                      if (comment['is_pinned'] == 1)
                                        Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.push_pin,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      Spacer(),
                                      if (widget.userRole == 'server' || post['creator_id'] == widget.currentUserId)
                                        IconButton(
                                          icon: Icon(
                                            comment['is_pinned'] == 1 ? Icons.push_pin : Icons.push_pin_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () => _togglePinComment(comment['id'], comment['is_pinned'] == 1),
                                          color: comment['is_pinned'] == 1 ? Colors.blue : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                        ),
                                      if (comment['creator_id'] == widget.currentUserId || 
                                          widget.userRole == 'server')  // User bisa hapus komentar sendiri
                                        IconButton(
                                          icon: Icon(Icons.delete_outline),
                                          onPressed: () => _deleteComment(comment['id']),
                                          color: Colors.red,
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    comment['content'],
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[300] : Colors.black87,
                                    ),
                                  ),
                                  // Tambahkan tampilan gambar komentar
                                  if (comment['image'] != null && comment['image'].toString().isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: double.infinity,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(comment['image']),
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading comment image: $error');
                                            return Container(
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 8),
                                  // Vote buttons
                                  FutureBuilder<String?>(
                                    future: dbHelper.getCommentVoteStatus(comment['id'], widget.currentUserId),
                                    builder: (context, snapshot) {
                                      final voteStatus = snapshot.data;
                                      return Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_upward,
                                              size: 16,
                                              color: voteStatus == 'up' ? Colors.blue : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            ),
                                            onPressed: () => _voteComment(comment['id'], 'up'),
                                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Text(
                                            '${comment['upvotes'] ?? 0}',
                                            style: TextStyle(
                                              color: voteStatus == 'up' ? Colors.blue : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_downward,
                                              size: 16,
                                              color: voteStatus == 'down' ? Colors.orange : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            ),
                                            onPressed: () => _voteComment(comment['id'], 'down'),
                                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Text(
                                            '${comment['downvotes'] ?? 0}',
                                            style: TextStyle(
                                              color: voteStatus == 'down' ? Colors.orange : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: Icon(Icons.add),
        label: Text('Buat Post'),
        backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
      ),
    );
  }

  Future<void> _createPost() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Buat Post Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Post',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Konten',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 16),
                if (imageBase64 != null)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: double.infinity,
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.memory(
                          base64Decode(imageBase64!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.error),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => imageBase64 = null),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Tambah Gambar'),
                  onPressed: isLoading ? null : () async {
                    await _pickImage();
                    setState(() {}); // Refresh dialog UI
                  },
                ),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                imageBase64 = null; // Reset image when canceling
                Navigator.pop(context);
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: isLoading ? null : () async {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  setState(() => isLoading = true);
                  try {
                    await dbHelper.createPost(
                      widget.category,
                      titleController.text,
                      contentController.text,
                      widget.currentUserId,
                      imageBase64 ?? '',
                    );
                    imageBase64 = null; // Reset image after successful post
                    Navigator.pop(context);
                    _loadPosts();
                  } catch (e) {
                    print('Error creating post: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membuat post')),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                }
              },
              child: isLoading ? 
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) : 
                Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Anda yakin ingin menghapus post ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbHelper.deletePost(postId);
      _loadPosts(); // Refresh daftar post
    }
  }

  Future<void> _votePost(int postId, String voteType) async {
    try {
      // Dapatkan status vote sebelumnya
      final previousVote = await dbHelper.getPostVoteStatus(postId, widget.currentUserId);
      
      // Dapatkan data post saat ini
      final post = posts.firstWhere((p) => p['id'] == postId);
      int upvotes = post['upvotes'] ?? 0;
      int downvotes = post['downvotes'] ?? 0;

      // Update perhitungan vote
      if (previousVote == voteType) {
        // Batalkan vote jika sama
        if (voteType == 'up') upvotes--;
        if (voteType == 'down') downvotes--;
        await dbHelper.deletePostVote(postId, widget.currentUserId);
      } else {
        // Hapus vote sebelumnya jika ada
        if (previousVote != null) {
          if (previousVote == 'up') upvotes--;
          if (previousVote == 'down') downvotes--;
          await dbHelper.deletePostVote(postId, widget.currentUserId);
        }
        
        // Tambah vote baru
        if (voteType == 'up') upvotes++;
        if (voteType == 'down') downvotes++;
        await dbHelper.votePost(postId, widget.currentUserId, voteType);
      }

      // Update jumlah vote di database
      await dbHelper.updatePostVotes(postId, upvotes, downvotes);
      
      // Refresh tampilan
      await _loadPosts();
    } catch (e) {
      print('Error voting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memberikan vote')),
      );
    }
  }

  Future<void> _showCommentDialog(int postId) async {
    final commentController = TextEditingController();
    bool isLoading = false;
    String? commentImageBase64; // Local image state untuk dialog

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Tambah Komentar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Komentar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                if (commentImageBase64 != null)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: double.infinity,
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.memory(
                          base64Decode(commentImageBase64!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.error),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => commentImageBase64 = null),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Tambah Gambar'),
                  onPressed: isLoading ? null : () async {
                    try {
                      // Tampilkan loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Center(child: CircularProgressIndicator());
                        },
                      );

                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 70,
                      );

                      if (image != null) {
                        final imageBytes = await image.readAsBytes();
                        final base64String = await compute(base64Encode, imageBytes);
                        
                        // Tutup loading indicator
                        Navigator.pop(context);

                        if (base64String.length > 1000000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ukuran gambar terlalu besar (maksimal 750KB)')),
                          );
                          return;
                        }

                        setState(() {
                          commentImageBase64 = base64String;
                        });
                      } else {
                        Navigator.pop(context); // Tutup loading jika tidak ada gambar dipilih
                      }
                    } catch (e) {
                      Navigator.pop(context); // Pastikan loading ditutup jika terjadi error
                      print('Error picking image: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal memilih gambar')),
                      );
                    }
                  },
                ),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                commentImageBase64 = null; // Reset image when canceling
                Navigator.pop(context);
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: isLoading ? null : () async {
                if (commentController.text.isNotEmpty) {
                  setState(() => isLoading = true);
                  try {
                    await dbHelper.createComment(
                      postId,
                      commentController.text,
                      commentImageBase64 ?? '',
                      widget.currentUserId,
                    );
                    Navigator.pop(context);
                    _loadPosts();
                  } catch (e) {
                    print('Error creating comment: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menambahkan komentar')),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                }
              },
              child: isLoading ? 
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) : 
                Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      // Tampilkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        
        // Proses gambar di background thread
        final base64String = await compute(base64Encode, imageBytes);
        
        // Tutup loading indicator
        Navigator.pop(context);

        // Cek ukuran base64 string (sekitar 1.33x ukuran file asli)
        if (base64String.length > 1000000) { // Sekitar 750KB
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ukuran gambar terlalu besar (maksimal 750KB)')),
          );
          return;
        }

        setState(() {
          imageBase64 = base64String;
        });
      } else {
        Navigator.pop(context); // Tutup loading jika tidak ada gambar dipilih
      }
    } catch (e) {
      Navigator.pop(context); // Pastikan loading ditutup jika terjadi error
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar')),
      );
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await dbHelper.deleteComment(commentId);
      _loadPosts();
    }
  }

  Future<void> _voteComment(int commentId, String voteType) async {
    try {
      // Dapatkan status vote sebelumnya
      final previousVote = await dbHelper.getCommentVoteStatus(commentId, widget.currentUserId);
      
      // Dapatkan data komentar saat ini
      final comment = await dbHelper.getCommentById(commentId);
      if (comment == null) return;
      
      int upvotes = comment['upvotes'] ?? 0;
      int downvotes = comment['downvotes'] ?? 0;

      // Update perhitungan vote
      if (previousVote == voteType) {
        // Batalkan vote jika sama
        if (voteType == 'up') upvotes--;
        if (voteType == 'down') downvotes--;
        await dbHelper.deleteCommentVote(commentId, widget.currentUserId);
      } else {
        // Hapus vote sebelumnya jika ada
        if (previousVote != null) {
          if (previousVote == 'up') upvotes--;
          if (previousVote == 'down') downvotes--;
          await dbHelper.deleteCommentVote(commentId, widget.currentUserId);
        }
        
        // Tambah vote baru
        if (voteType == 'up') upvotes++;
        if (voteType == 'down') downvotes++;
        await dbHelper.voteComment(commentId, widget.currentUserId, voteType);
      }

      // Update jumlah vote di database
      await dbHelper.updateCommentVotes(commentId, upvotes, downvotes);
      
      // Refresh tampilan
      setState(() {
        _loadPosts();
      });
    } catch (e) {
      print('Error voting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memberikan vote pada komentar')),
      );
    }
  }

  Widget _buildBadge(String badge) {
    Color badgeColor;
    IconData badgeIcon;
    
    // Sesuaikan warna dan ikon berdasarkan jenis badge
    switch (badge) {
      case 'Siswa':
        badgeColor = Colors.green;
        badgeIcon = Icons.school;
        break;
      case 'Aktif':
        badgeColor = Colors.blue;
        badgeIcon = Icons.star;
        break;
      case 'Guru':
        badgeColor = Colors.purple;
        badgeIcon = Icons.psychology;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.shield;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: badgeColor,
          ),
          SizedBox(width: 4),
          Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePinComment(int commentId, bool currentlyPinned) async {
    try {
      await dbHelper.togglePinComment(commentId, !currentlyPinned);
      _loadPosts(); // Refresh data
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyPinned ? 'Komentar dilepas dari pin' : 'Komentar berhasil dipin'),
        ),
      );
    } catch (e) {
      print('Error toggling pin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status pin komentar')),
      );
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Hari ini ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Kemarin ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}h lalu';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildPostContent(Map<String, dynamic> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(post['content'].toString()),
        if (post['image'] != null && post['image'].toString().isNotEmpty) ...[
          SizedBox(height: 8),
          _buildImage(post['image'].toString()),
        ],
      ],
    );
  }

  // Fungsi untuk memproses gambar di isolate terpisah
  Future<String?> _processImageInBackground(List<int> imageBytes) async {
    if (imageBytes.length > 1 * 1024 * 1024) { // 1MB limit
      return null;
    }
    return compute(base64Encode, imageBytes); // Proses di background thread
  }

  // Untuk menampilkan gambar
  Widget _buildImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container();
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      );
    } catch (e) {
      print('Error decoding image: $e');
      return Container();
    }
  }
}
