import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/app_colors.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  
  // Filter states
  bool _showSensoryFriendly = true;
  bool _showPlaygrounds = true;
  bool _showDoctors = true;
  bool _showAfterSchool = true;
  
  // Selected location
  MapLocation? _selectedLocation;
  
  // Map center (San Francisco coordinates)
  final LatLng _center = LatLng(37.7749, -122.4194);
  
  // Current zoom level
  double _currentZoom = 13.0;
  
  // Real SF Bay Area autism-friendly locations
  final List<MapLocation> _locations = [
    // Sensory-Friendly Venues
    MapLocation(
      id: '1',
      name: 'California Academy of Sciences',
      category: LocationCategory.sensoryFriendly,
      position: LatLng(37.7699, -122.4661),
      distance: 2.3,
      description: 'Sensory-friendly hours monthly',
      rating: 4.7,
      isCrowded: false,
    ),
    MapLocation(
      id: '2',
      name: 'Children\'s Creativity Museum',
      category: LocationCategory.sensoryFriendly,
      position: LatLng(37.7826, -122.4042),
      distance: 1.8,
      description: 'Quiet hours Tuesdays 10-11am',
      rating: 4.5,
      isCrowded: false,
    ),
    MapLocation(
      id: '3',
      name: 'Randall Museum',
      category: LocationCategory.sensoryFriendly,
      position: LatLng(37.7642, -122.4384),
      distance: 2.1,
      description: 'Sensory-friendly programs',
      rating: 4.6,
      isCrowded: false,
    ),
    
    // Playgrounds
    MapLocation(
      id: '4',
      name: 'Magical Bridge Playground',
      category: LocationCategory.playground,
      position: LatLng(37.4217, -122.1079),
      distance: 28.5,
      description: 'Fully inclusive playground',
      rating: 4.9,
      isCrowded: true,
    ),
    MapLocation(
      id: '5',
      name: 'Golden Gate Park Playground',
      category: LocationCategory.playground,
      position: LatLng(37.7694, -122.4862),
      distance: 3.2,
      description: 'Accessible play structures',
      rating: 4.4,
      isCrowded: true,
    ),
    MapLocation(
      id: '6',
      name: 'Sue Bierman Park',
      category: LocationCategory.playground,
      position: LatLng(37.7955, -122.3937),
      distance: 1.4,
      description: 'Quiet neighborhood playground',
      rating: 4.3,
      isCrowded: false,
    ),
    
    // Medical/Therapy Centers
    MapLocation(
      id: '7',
      name: 'UCSF Autism Center',
      category: LocationCategory.doctor,
      position: LatLng(37.7643, -122.4580),
      distance: 2.8,
      description: 'Comprehensive autism services',
      rating: 4.8,
      isCrowded: false,
    ),
    MapLocation(
      id: '8',
      name: 'Stanford Autism Center',
      category: LocationCategory.doctor,
      position: LatLng(37.4323, -122.1775),
      distance: 32.1,
      description: 'Specialized autism clinic',
      rating: 4.9,
      isCrowded: false,
    ),
    MapLocation(
      id: '9',
      name: 'Speech Therapy SF',
      category: LocationCategory.doctor,
      position: LatLng(37.7923, -122.4382),
      distance: 2.5,
      description: 'Speech & occupational therapy',
      rating: 4.7,
      isCrowded: false,
    ),
    
    // After-School Programs
    MapLocation(
      id: '10',
      name: 'Friends of Children SF',
      category: LocationCategory.afterSchool,
      position: LatLng(37.7602, -122.4142),
      distance: 1.9,
      description: 'Special needs programs',
      rating: 4.6,
      isCrowded: false,
    ),
    MapLocation(
      id: '11',
      name: 'Support for Families',
      category: LocationCategory.afterSchool,
      position: LatLng(37.7885, -122.4118),
      distance: 1.6,
      description: 'Family resource center',
      rating: 4.5,
      isCrowded: false,
    ),
    MapLocation(
      id: '12',
      name: 'Stepping Stones Growth',
      category: LocationCategory.afterSchool,
      position: LatLng(37.7749, -122.4194),
      distance: 0.8,
      description: 'Developmental programs',
      rating: 4.7,
      isCrowded: true,
    ),
    
    // Additional Sensory-Friendly
    MapLocation(
      id: '13',
      name: 'AMC Bay Street 16',
      category: LocationCategory.sensoryFriendly,
      position: LatLng(37.8344, -122.2571),
      distance: 8.2,
      description: 'Sensory-friendly films monthly',
      rating: 4.4,
      isCrowded: false,
    ),
    MapLocation(
      id: '14',
      name: 'Exploratorium',
      category: LocationCategory.sensoryFriendly,
      position: LatLng(37.8016, -122.3975),
      distance: 1.8,
      description: 'Tactile learning experiences',
      rating: 4.6,
      isCrowded: true,
    ),
  ];
  
  List<MapLocation> get filteredLocations {
    return _locations.where((location) {
      // Apply category filters
      switch (location.category) {
        case LocationCategory.sensoryFriendly:
          if (!_showSensoryFriendly) return false;
          break;
        case LocationCategory.playground:
          if (!_showPlaygrounds) return false;
          break;
        case LocationCategory.doctor:
          if (!_showDoctors) return false;
          break;
        case LocationCategory.afterSchool:
          if (!_showAfterSchool) return false;
          break;
      }
      
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return location.name.toLowerCase().contains(searchTerm) ||
               location.description.toLowerCase().contains(searchTerm);
      }
      
      return true;
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _selectLocation(MapLocation location) {
    setState(() => _selectedLocation = location);
    
    // Animate map to selected location
    _mapController.move(location.position, 15.0);
  }
  
  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(5.0, 18.0);
    setState(() => _currentZoom = newZoom);
    _mapController.move(_mapController.camera.center, newZoom);
  }
  
  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(5.0, 18.0);
    setState(() => _currentZoom = newZoom);
    _mapController.move(_mapController.camera.center, newZoom);
  }
  
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
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
              const Text(
                'Filter Locations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    'Sensory-Friendly',
                    Icons.spa,
                    _showSensoryFriendly,
                    (value) {
                      setModalState(() => _showSensoryFriendly = value);
                      setState(() => _showSensoryFriendly = value);
                    },
                  ),
                  _buildFilterChip(
                    'Playgrounds',
                    Icons.park,
                    _showPlaygrounds,
                    (value) {
                      setModalState(() => _showPlaygrounds = value);
                      setState(() => _showPlaygrounds = value);
                    },
                  ),
                  _buildFilterChip(
                    'Doctors',
                    Icons.medical_services,
                    _showDoctors,
                    (value) {
                      setModalState(() => _showDoctors = value);
                      setState(() => _showDoctors = value);
                    },
                  ),
                  _buildFilterChip(
                    'After-School',
                    Icons.school,
                    _showAfterSchool,
                    (value) {
                      setModalState(() => _showAfterSchool = value);
                      setState(() => _showAfterSchool = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, IconData icon, bool selected, Function(bool) onChanged) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _currentZoom,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: (_, __) => setState(() => _selectedLocation = null),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.zoom != null) {
                  setState(() => _currentZoom = position.zoom!);
                }
              },
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.spectrum.app',
              ),
              
              // Markers layer
              MarkerLayer(
                markers: filteredLocations.map((location) {
                  final isSelected = _selectedLocation?.id == location.id;
                  return Marker(
                    point: location.position,
                    width: isSelected ? 56 : 40,
                    height: isSelected ? 56 : 40,
                    child: GestureDetector(
                      onTap: () => _selectLocation(location),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: location.getCategoryColor(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: isSelected 
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        ),
                        child: Icon(
                          location.getCategoryIcon(),
                          color: Colors.white,
                          size: isSelected ? 26 : 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          // Top Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search places...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _showFilterOptions,
                      icon: Badge(
                        isLabelVisible: !_showSensoryFriendly || !_showPlaygrounds || 
                                       !_showDoctors || !_showAfterSchool,
                        smallSize: 8,
                        child: const Icon(Icons.tune, size: 20),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Zoom Controls
          Positioned(
            right: 16,
            bottom: 160,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: _currentZoom < 18 ? _zoomIn : null,
                        icon: const Icon(Icons.add),
                        iconSize: 24,
                        padding: const EdgeInsets.all(12),
                        disabledColor: Colors.grey.withOpacity(0.5),
                      ),
                      Container(
                        height: 1,
                        width: 30,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      IconButton(
                        onPressed: _currentZoom > 5 ? _zoomOut : null,
                        icon: const Icon(Icons.remove),
                        iconSize: 24,
                        padding: const EdgeInsets.all(12),
                        disabledColor: Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(0)}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Cards Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.05),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cards List
                  ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      final isSelected = _selectedLocation?.id == location.id;
                      
                      return GestureDetector(
                        onTap: () => _selectLocation(location),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 240,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? Colors.white.withOpacity(0.95)
                              : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                  ? AppColors.primary.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                                blurRadius: isSelected ? 15 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: isSelected 
                              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 2)
                              : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: location.getCategoryColor().withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  location.getCategoryIcon(),
                                  color: location.getCategoryColor(),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      location.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.near_me, size: 10, color: AppColors.primary),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${location.distance} mi',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 12, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              location.rating.toString(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
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
                    },
                  ),
                  
                  // Left Arrow
                  Positioned(
                    left: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _scrollLeft,
                        icon: const Icon(Icons.chevron_left),
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  
                  // Right Arrow
                  Positioned(
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _scrollRight,
                        icon: const Icon(Icons.chevron_right),
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Location model
class MapLocation {
  final String id;
  final String name;
  final LocationCategory category;
  final LatLng position;
  final double distance;
  final String description;
  final double rating;
  final bool isCrowded;
  
  MapLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.distance,
    required this.description,
    required this.rating,
    required this.isCrowded,
  });
  
  IconData getCategoryIcon() {
    switch (category) {
      case LocationCategory.sensoryFriendly:
        return Icons.spa;
      case LocationCategory.playground:
        return Icons.park;
      case LocationCategory.doctor:
        return Icons.medical_services;
      case LocationCategory.afterSchool:
        return Icons.school;
    }
  }
  
  Color getCategoryColor() {
    switch (category) {
      case LocationCategory.sensoryFriendly:
        return AppColors.primary;
      case LocationCategory.playground:
        return AppColors.secondary;
      case LocationCategory.doctor:
        return AppColors.tertiary;
      case LocationCategory.afterSchool:
        return AppColors.quaternary;
    }
  }
  
  String getCategoryName() {
    switch (category) {
      case LocationCategory.sensoryFriendly:
        return 'Sensory-Friendly';
      case LocationCategory.playground:
        return 'Playground';
      case LocationCategory.doctor:
        return 'Doctor/Therapist';
      case LocationCategory.afterSchool:
        return 'After-School Program';
    }
  }
}

enum LocationCategory {
  sensoryFriendly,
  playground,
  doctor,
  afterSchool,
}