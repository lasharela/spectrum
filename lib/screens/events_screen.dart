import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_text_field.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final Set<String> _savedEventIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Event> _filteredEvents = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    // Initialize filtered events after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterEvents();
    });
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterEvents();
    });
  }
  
  void _filterEvents() {
    setState(() {
      _filteredEvents = _events.where((event) {
        final matchesCategory = _selectedCategory == 'All' || 
            event.category.name == _selectedCategory.toLowerCase().replaceAll(' ', '');
        
        final matchesSearch = _searchQuery.isEmpty ||
            event.title.toLowerCase().contains(_searchQuery) ||
            event.organization.toLowerCase().contains(_searchQuery) ||
            event.description.toLowerCase().contains(_searchQuery) ||
            event.location.toLowerCase().contains(_searchQuery);
        
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  final List<String> _categories = [
    'All',
    'Workshops',
    'Support Groups',
    'Social',
    'Educational',
    'Recreation',
  ];
  
  final List<Event> _events = [
    Event(
      id: '1',
      title: 'Parent Support Group Meeting',
      organization: 'Autism Society SF',
      description: 'Monthly support group for parents of children on the spectrum',
      category: EventCategory.supportGroup,
      date: 'Nov 25, 2024',
      time: '6:00 PM - 8:00 PM',
      location: '123 Market St, San Francisco',
      imageIcon: Icons.groups,
      isOnline: false,
      isFree: true,
    ),
    Event(
      id: '2',
      title: 'Sensory Play Workshop',
      organization: 'Children\'s Creativity Museum',
      description: 'Hands-on workshop exploring sensory activities for kids',
      category: EventCategory.workshop,
      date: 'Nov 28, 2024',
      time: '10:00 AM - 12:00 PM',
      location: '221 4th St, San Francisco',
      imageIcon: Icons.palette,
      isOnline: false,
      isFree: false,
      price: '\$25',
    ),
    Event(
      id: '3',
      title: 'Teen Social Skills Group',
      organization: 'Friends Together',
      description: 'Weekly social skills development for teens on the spectrum',
      category: EventCategory.social,
      date: 'Nov 30, 2024',
      time: '3:00 PM - 5:00 PM',
      location: 'Online via Zoom',
      imageIcon: Icons.video_call,
      isOnline: true,
      isFree: true,
    ),
    Event(
      id: '4',
      title: 'Understanding IEPs Workshop',
      organization: 'Special Education Alliance',
      description: 'Learn how to advocate for your child\'s educational needs',
      category: EventCategory.educational,
      date: 'Dec 2, 2024',
      time: '7:00 PM - 9:00 PM',
      location: 'SF Public Library, Main Branch',
      imageIcon: Icons.school,
      isOnline: false,
      isFree: true,
    ),
    Event(
      id: '5',
      title: 'Adaptive Swimming Lessons',
      organization: 'Aqua Abilities',
      description: 'Swimming lessons designed for children with special needs',
      category: EventCategory.recreation,
      date: 'Dec 5, 2024',
      time: '4:00 PM - 5:00 PM',
      location: 'YMCA Pool, 1 Tennis Dr',
      imageIcon: Icons.pool,
      isOnline: false,
      isFree: false,
      price: '\$40',
    ),
    Event(
      id: '6',
      title: 'Siblings Support Circle',
      organization: 'Family Support Network',
      description: 'Support group for siblings of children with autism',
      category: EventCategory.supportGroup,
      date: 'Dec 8, 2024',
      time: '2:00 PM - 3:30 PM',
      location: 'Community Center, 100 Oak St',
      imageIcon: Icons.favorite,
      isOnline: false,
      isFree: true,
    ),
    Event(
      id: '7',
      title: 'Art Therapy Session',
      organization: 'Creative Minds Studio',
      description: 'Express yourself through art in a supportive environment',
      category: EventCategory.workshop,
      date: 'Dec 10, 2024',
      time: '11:00 AM - 1:00 PM',
      location: '456 Valencia St, San Francisco',
      imageIcon: Icons.brush,
      isOnline: false,
      isFree: false,
      price: '\$35',
    ),
    Event(
      id: '8',
      title: 'Holiday Sensory Event',
      organization: 'California Academy of Sciences',
      description: 'Special sensory-friendly holiday celebration',
      category: EventCategory.social,
      date: 'Dec 15, 2024',
      time: '9:00 AM - 11:00 AM',
      location: '55 Music Concourse Dr, SF',
      imageIcon: Icons.celebration,
      isOnline: false,
      isFree: false,
      price: '\$15',
    ),
    Event(
      id: '9',
      title: 'Parent Education Seminar',
      organization: 'Autism Research Center',
      description: 'Latest research and strategies for supporting your child',
      category: EventCategory.educational,
      date: 'Dec 18, 2024',
      time: '6:30 PM - 8:30 PM',
      location: 'Online Webinar',
      imageIcon: Icons.computer,
      isOnline: true,
      isFree: true,
    ),
    Event(
      id: '10',
      title: 'Music Therapy Group',
      organization: 'Harmony Music Center',
      description: 'Interactive music therapy session for all ages',
      category: EventCategory.recreation,
      date: 'Dec 20, 2024',
      time: '10:00 AM - 11:00 AM',
      location: '789 Mission St, San Francisco',
      imageIcon: Icons.music_note,
      isOnline: false,
      isFree: false,
      price: '\$30',
    ),
  ];
  
  
  List<Event> get savedEvents {
    return _events.where((e) => _savedEventIds.contains(e.id)).toList();
  }
  
  EventCategory _getCategoryEnum(String category) {
    switch (category) {
      case 'Workshops':
        return EventCategory.workshop;
      case 'Support Groups':
        return EventCategory.supportGroup;
      case 'Social':
        return EventCategory.social;
      case 'Educational':
        return EventCategory.educational;
      case 'Recreation':
        return EventCategory.recreation;
      default:
        return EventCategory.workshop;
    }
  }
  
  void _toggleSaveEvent(String eventId) {
    setState(() {
      if (_savedEventIds.contains(eventId)) {
        _savedEventIds.remove(eventId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event removed from saved'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _savedEventIds.add(eventId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event saved!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }
  
  void _showEventDetails(Event event) {
    final isSaved = _savedEventIds.contains(event.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    event.imageIcon,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.organization,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        event.date,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        event.time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        event.isOnline ? Icons.computer : Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!event.isFree) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          event.price ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                                                ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleSaveEvent(event.id);
                    },
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                    label: Text(isSaved ? 'Saved' : 'Save Event'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registering for ${event.title}'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventCard(Event event, {bool showRemoveButton = false}) {
    final isSaved = _savedEventIds.contains(event.id);
    
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and save button
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        event.imageIcon,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: isSaved ? AppColors.primary : Colors.grey,
                      ),
                      onPressed: () => _toggleSaveEvent(event.id),
                    ),
                  ),
                  if (event.isOnline)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.computer, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (event.isFree)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (event.price != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.price!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.organization,
                    style: TextStyle(
                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        event.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        event.isOnline ? Icons.computer : Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showRemoveButton)
                        IconButton(
                          onPressed: () => _toggleSaveEvent(event.id),
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.error,
                          iconSize: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpcomingTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: CustomTextField(
            controller: _searchController,
            hintText: 'Search events...',
            prefixIcon: const Icon(Icons.search),
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
        // Category Filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterEvents();
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Events count
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          alignment: Alignment.centerLeft,
          child: Text(
            '${_filteredEvents.length} Upcoming Events',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Events List
        Expanded(
          child: _filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events in this category',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _filterEvents();
                          });
                        },
                        child: const Text('View all events'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) => _buildEventCard(_filteredEvents[index]),
                ),
        ),
      ],
    );
  }
  
  Widget _buildSavedTab() {
    if (savedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved events yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark events to see them here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedEvents.length,
      itemBuilder: (context, index) => _buildEventCard(
        savedEvents[index],
        showRemoveButton: true,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Compact header with tabs
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.event, size: 24),
                    text: 'Upcoming',
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    icon: Icon(Icons.bookmark, size: 24),
                    text: 'Saved',
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Event model
class Event {
  final String id;
  final String title;
  final String organization;
  final String description;
  final EventCategory category;
  final String date;
  final String time;
  final String location;
  final IconData imageIcon;
  final bool isOnline;
  final bool isFree;
  final String? price;
  
  Event({
    required this.id,
    required this.title,
    required this.organization,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.imageIcon,
    required this.isOnline,
    required this.isFree,
    this.price,
  });
}

enum EventCategory {
  workshop,
  supportGroup,
  social,
  educational,
  recreation,
}