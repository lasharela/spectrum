import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  
  final List<String> _filters = [
    'All',
    'Events',
    'Community',
    'Promotions',
    'System',
  ];
  
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'New Event: Art Therapy Session',
      message: 'A new art therapy session has been scheduled for next week. Tap to view details and register.',
      type: NotificationType.event,
      time: '2 hours ago',
      isRead: false,
      icon: Icons.brush,
    ),
    NotificationItem(
      id: '2',
      title: 'Community Post',
      message: 'Sarah commented on your post: "Thank you for sharing this resource!"',
      type: NotificationType.community,
      time: '5 hours ago',
      isRead: false,
      icon: Icons.forum,
    ),
    NotificationItem(
      id: '3',
      title: '50% Off Sensory Toys',
      message: 'Limited time offer at Learning Express. Valid until Sunday.',
      type: NotificationType.promotion,
      time: 'Yesterday',
      isRead: true,
      icon: Icons.local_offer,
    ),
    NotificationItem(
      id: '4',
      title: 'Event Reminder',
      message: 'Parent Support Group Meeting starts tomorrow at 6:00 PM',
      type: NotificationType.event,
      time: 'Yesterday',
      isRead: true,
      icon: Icons.event,
    ),
    NotificationItem(
      id: '5',
      title: 'Welcome to Spectrum!',
      message: 'Start exploring events, connect with the community, and discover resources.',
      type: NotificationType.system,
      time: '2 days ago',
      isRead: true,
      icon: Icons.celebration,
    ),
    NotificationItem(
      id: '6',
      title: 'New Resource Available',
      message: 'IEP Planning Guide has been added to the resources section.',
      type: NotificationType.system,
      time: '3 days ago',
      isRead: true,
      icon: Icons.library_books,
    ),
    NotificationItem(
      id: '7',
      title: 'Event Cancelled',
      message: 'Swimming Lessons on Dec 5 has been cancelled due to maintenance.',
      type: NotificationType.event,
      time: '3 days ago',
      isRead: true,
      icon: Icons.cancel,
    ),
    NotificationItem(
      id: '8',
      title: 'New Connection',
      message: 'Alex has accepted your connection request.',
      type: NotificationType.community,
      time: '4 days ago',
      isRead: true,
      icon: Icons.person_add,
    ),
    NotificationItem(
      id: '9',
      title: 'Weekly Digest',
      message: 'Check out this week\'s upcoming events and activities.',
      type: NotificationType.system,
      time: '1 week ago',
      isRead: true,
      icon: Icons.summarize,
    ),
    NotificationItem(
      id: '10',
      title: 'Flash Sale Alert',
      message: 'Barnes & Noble: Buy 1 Get 1 Free on all children\'s books today only!',
      type: NotificationType.promotion,
      time: '1 week ago',
      isRead: true,
      icon: Icons.auto_awesome,
    ),
  ];
  
  List<NotificationItem> get filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    }
    return _notifications.where((notification) {
      switch (_selectedFilter) {
        case 'Events':
          return notification.type == NotificationType.event;
        case 'Community':
          return notification.type == NotificationType.community;
        case 'Promotions':
          return notification.type == NotificationType.promotion;
        case 'System':
          return notification.type == NotificationType.system;
        default:
          return true;
      }
    }).toList();
  }
  
  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }
  
  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
      }
    });
  }
  
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.info,
      ),
    );
  }
  
  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: AppColors.info,
      ),
    );
  }
  
  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return AppColors.primary;
      case NotificationType.community:
        return AppColors.secondary;
      case NotificationType.promotion:
        return AppColors.tertiary;
      case NotificationType.system:
        return AppColors.quaternary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 20),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Unread count
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Text(
                '$unreadCount unread notifications',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Notifications list
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          _deleteNotification(notification.id);
                        },
                        child: InkWell(
                          onTap: () {
                            if (!notification.isRead) {
                              _markAsRead(notification.id);
                            }
                            // Handle notification tap
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening: ${notification.title}'),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: notification.isRead 
                                    ? Colors.grey.shade200 
                                    : AppColors.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(notification.type).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notification.icon,
                                    size: 20,
                                    color: _getTypeColor(notification.type),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: notification.isRead 
                                                    ? FontWeight.w500 
                                                    : FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!notification.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notification.time,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary.withOpacity(0.7),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String time;
  bool isRead;
  final IconData icon;
  
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    required this.isRead,
    required this.icon,
  });
}

enum NotificationType {
  event,
  community,
  promotion,
  system,
}