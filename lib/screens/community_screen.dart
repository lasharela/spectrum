import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Discussion> _allDiscussions = _generateDiscussions();
  List<Discussion> _filteredDiscussions = [];
  final List<Discussion> _myDiscussions = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredDiscussions = List.from(_allDiscussions);
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredDiscussions = List.from(_allDiscussions);
      } else {
        _filteredDiscussions = _allDiscussions.where((discussion) {
          return discussion.title.toLowerCase().contains(_searchQuery) ||
                 discussion.content.toLowerCase().contains(_searchQuery) ||
                 discussion.category.toLowerCase().contains(_searchQuery) ||
                 discussion.author.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  static List<Discussion> _generateDiscussions() {
    return [
      Discussion(
        id: '1',
        title: 'Tips for managing sensory overload in public spaces',
        author: 'Sarah M.',
        category: 'Sensory',
        content: 'I\'ve found that noise-canceling headphones really help...',
        imageUrl: 'placeholder_sensory',
        replies: 23,
        likes: 45,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isLiked: false,
        replyList: [
          Reply(
            id: 'r1',
            author: 'John D.',
            content: 'Great tips! I also find that having a quiet space to retreat to helps a lot.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            likes: 12,
            isLiked: false,
          ),
          Reply(
            id: 'r2',
            author: 'Maria L.',
            content: 'We use a sensory kit with fidget toys and it works wonders!',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            likes: 8,
            isLiked: true,
          ),
        ],
      ),
      Discussion(
        id: '2',
        title: 'Best educational apps for kids on the spectrum',
        author: 'Michael R.',
        category: 'Education',
        content: 'Here are some apps that have worked great for my child...',
        replies: 18,
        likes: 67,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isLiked: true,
        replyList: [
          Reply(
            id: 'r3',
            author: 'Patricia K.',
            content: 'Thank you for sharing! We\'ve been looking for good educational apps.',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            likes: 5,
            isLiked: false,
          ),
        ],
      ),
      Discussion(
        id: '3',
        title: 'Weekly support group - Everyone welcome!',
        author: 'Emma T.',
        category: 'Support',
        content: 'Join us every Wednesday for our online support group...',
        replies: 34,
        likes: 89,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isLiked: false,
        replyList: [],
      ),
      Discussion(
        id: '4',
        title: 'Recommendations for autism-friendly restaurants',
        author: 'David L.',
        category: 'Resources',
        content: 'Looking for restaurant recommendations in the Bay Area...',
        replies: 12,
        likes: 28,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        isLiked: false,
        replyList: [],
      ),
      Discussion(
        id: '5',
        title: 'Strategies for improving sleep routines',
        author: 'Anna K.',
        category: 'Daily Life',
        content: 'We\'ve been struggling with bedtime routines. Any tips?',
        imageUrl: 'placeholder_sleep',
        replies: 41,
        likes: 56,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isLiked: true,
        replyList: [],
      ),
      Discussion(
        id: '6',
        title: 'New therapy center opening downtown',
        author: 'Robert P.',
        category: 'News',
        content: 'Excited to share that a new therapy center is opening...',
        replies: 8,
        likes: 34,
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 12)),
        isLiked: false,
        replyList: [],
      ),
      Discussion(
        id: '7',
        title: 'Social skills activities for teenagers',
        author: 'Lisa W.',
        category: 'Social',
        content: 'Looking for activity ideas to help my teen with social skills...',
        replies: 27,
        likes: 71,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isLiked: false,
        replyList: [],
      ),
      Discussion(
        id: '8',
        title: 'Understanding stimming behaviors',
        author: 'James H.',
        category: 'Education',
        content: 'Can someone help explain stimming to family members?',
        replies: 52,
        likes: 93,
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        isLiked: true,
        replyList: [],
      ),
    ];
  }
  
  void _createNewDiscussion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateDiscussionModal(
        onSubmit: (discussion) {
          setState(() {
            _allDiscussions.insert(0, discussion);
            _filteredDiscussions.insert(0, discussion);
            _myDiscussions.insert(0, discussion);
          });
        },
      ),
    );
  }
  
  void _toggleLike(Discussion discussion) {
    setState(() {
      discussion.isLiked = !discussion.isLiked;
      if (discussion.isLiked) {
        discussion.likes++;
      } else {
        discussion.likes--;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All Discussions'),
                Tab(text: 'My Discussions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Discussions with Search
                Column(
                  children: [
                    // Search Bar for All Discussions only
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search discussions...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildDiscussionsList(_filteredDiscussions),
                    ),
                  ],
                ),
                // My Discussions without Search
                _buildDiscussionsList(_myDiscussions, isMyDiscussions: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewDiscussion,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildDiscussionsList(List<Discussion> discussions, {bool isMyDiscussions = false}) {
    if (discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyDiscussions ? Icons.forum_outlined : Icons.message_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isMyDiscussions 
                ? 'You haven\'t created any discussions yet'
                : 'No discussions available',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (isMyDiscussions) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the + button to start a discussion',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: discussions.length,
      itemBuilder: (context, index) {
        return _buildDiscussionCard(discussions[index]);
      },
    );
  }
  
  Widget _buildDiscussionCard(Discussion discussion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: AppColors.cardBorderStyle,
        boxShadow: [AppColors.cardShadow],
      ),
      child: InkWell(
        onTap: () {
          _showDiscussionDetails(discussion);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      discussion.author[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discussion.author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimestamp(discussion.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(discussion.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      discussion.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCategoryColor(discussion.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                discussion.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                discussion.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (discussion.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Image',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleLike(discussion),
                    child: Row(
                      children: [
                        Icon(
                          discussion.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: discussion.isLiked ? AppColors.error : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${discussion.likes}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.comment_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${discussion.replies}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDiscussionDetails(Discussion discussion) {
    final TextEditingController replyController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            discussion.author[0].toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                discussion.author,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatTimestamp(discussion.timestamp),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(discussion.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            discussion.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(discussion.category),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      discussion.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      discussion.content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Replies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${discussion.replyList.length} replies',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (discussion.replyList.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No replies yet. Be the first to reply!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...discussion.replyList.map((reply) => _buildReplyCard(reply, setModalState)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        decoration: InputDecoration(
                          hintText: 'Add a reply...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (replyController.text.trim().isNotEmpty) {
                            final newReply = Reply(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              author: 'Alex',
                              content: replyController.text.trim(),
                              timestamp: DateTime.now(),
                              likes: 0,
                              isLiked: false,
                            );
                            
                            setModalState(() {
                              discussion.replyList.add(newReply);
                              discussion.replies = discussion.replyList.length;
                            });
                            
                            setState(() {});
                            
                            replyController.clear();
                            FocusScope.of(context).unfocus();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reply added successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReplyCard(Reply reply, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                child: Text(
                  reply.author[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      reply.author,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(reply.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setModalState(() {
                    reply.isLiked = !reply.isLiked;
                    if (reply.isLiked) {
                      reply.likes++;
                    } else {
                      reply.likes--;
                    }
                  });
                  setState(() {});
                },
                child: Row(
                  children: [
                    Icon(
                      reply.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: reply.isLiked ? AppColors.error : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reply.likes}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sensory':
        return AppColors.primary;
      case 'Education':
        return AppColors.secondary;
      case 'Support':
        return AppColors.tertiary;
      case 'Resources':
        return AppColors.quaternary;
      case 'Daily Life':
        return AppColors.accent1;
      case 'News':
        return AppColors.accent2;
      case 'Social':
        return AppColors.accent3;
      default:
        return AppColors.primary;
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

class Discussion {
  final String id;
  final String title;
  final String author;
  final String category;
  final String content;
  final String? imageUrl;
  int replies;
  int likes;
  final DateTime timestamp;
  bool isLiked;
  final List<Reply> replyList;
  
  Discussion({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.content,
    this.imageUrl,
    required this.replies,
    required this.likes,
    required this.timestamp,
    required this.isLiked,
    List<Reply>? replyList,
  }) : replyList = replyList ?? [];
}

class Reply {
  final String id;
  final String author;
  final String content;
  final DateTime timestamp;
  int likes;
  bool isLiked;
  
  Reply({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.isLiked,
  });
}

class CreateDiscussionModal extends StatefulWidget {
  final Function(Discussion) onSubmit;
  
  const CreateDiscussionModal({
    super.key,
    required this.onSubmit,
  });
  
  @override
  State<CreateDiscussionModal> createState() => _CreateDiscussionModalState();
}

class _CreateDiscussionModalState extends State<CreateDiscussionModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  bool _hasImage = false;
  
  final List<String> _categories = [
    'General',
    'Sensory',
    'Education',
    'Support',
    'Resources',
    'Daily Life',
    'News',
    'Social',
  ];
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  void _submit() {
    if (_titleController.text.trim().isEmpty || 
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final discussion = Discussion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      author: 'Alex',  // Using the name from home screen
      category: _selectedCategory,
      content: _contentController.text.trim(),
      imageUrl: _hasImage ? 'user_uploaded_image' : null,
      replies: 0,
      likes: 0,
      timestamp: DateTime.now(),
      isLiked: false,
    );
    
    widget.onSubmit(discussion);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discussion created successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Text(
                  'New Discussion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _submit,
                  child: Text(
                    'Post',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'What would you like to discuss?',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts, questions, or experiences...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  
                  // Image Upload Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Image',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_hasImage)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _hasImage = false;
                            });
                          },
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (!_hasImage)
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.camera_alt, color: AppColors.primary),
                                  ),
                                  title: const Text('Take Photo'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _hasImage = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Photo added to discussion'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.photo_library, color: AppColors.secondary),
                                  ),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _hasImage = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image added to discussion'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 32,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add image',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 50,
                                  color: AppColors.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image attached',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}