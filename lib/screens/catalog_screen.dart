import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Category filters
  bool _showSensoryFriendly = false;
  bool _showPlaygrounds = false;
  bool _showIndoorPlaygrounds = false;
  bool _showOutdoorPlaygrounds = false;
  bool _showDoctors = false;
  bool _showDentists = false;
  bool _showTherapists = false;
  bool _showAfterSchool = false;
  bool _showRestaurants = false;
  bool _showEducation = false;
  
  // Age group filters
  bool _ageInfants = false; // 0-2
  bool _ageToddlers = false; // 2-4
  bool _agePreschool = false; // 4-6
  bool _ageSchoolAge = false; // 6-12
  bool _ageTeens = false; // 12-18
  bool _ageAdults = false; // 18+
  
  // Special needs filters
  bool _autismSpecific = false;
  bool _wheelchairAccessible = false;
  bool _nonverbal = false;
  bool _sensoryProcessing = false;
  
  // Saved places
  final Set<String> _savedPlaceIds = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Count active filters
  int get activeFilterCount {
    int count = 0;
    if (_showSensoryFriendly) count++;
    if (_showPlaygrounds) count++;
    if (_showIndoorPlaygrounds) count++;
    if (_showOutdoorPlaygrounds) count++;
    if (_showDoctors) count++;
    if (_showDentists) count++;
    if (_showTherapists) count++;
    if (_showAfterSchool) count++;
    if (_showRestaurants) count++;
    if (_showEducation) count++;
    if (_ageInfants) count++;
    if (_ageToddlers) count++;
    if (_agePreschool) count++;
    if (_ageSchoolAge) count++;
    if (_ageTeens) count++;
    if (_ageAdults) count++;
    if (_autismSpecific) count++;
    if (_wheelchairAccessible) count++;
    if (_nonverbal) count++;
    if (_sensoryProcessing) count++;
    return count;
  }
  
  // All places data with enhanced categories
  final List<Place> _allPlaces = [
    // Sensory-Friendly Venues
    Place(
      id: '1',
      name: 'California Academy of Sciences',
      category: PlaceCategory.sensoryFriendly,
      description: 'Natural history museum with sensory-friendly hours monthly',
      address: '55 Music Concourse Dr, San Francisco',
      rating: 4.7,
      tags: ['Sensory-Friendly', 'Educational', 'Family'],
      imageIcon: Icons.museum,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.wheelchairAccessible],
    ),
    Place(
      id: '2',
      name: 'Children\'s Creativity Museum',
      category: PlaceCategory.sensoryFriendly,
      description: 'Interactive exhibits with quiet hours Tuesdays 10-11am',
      address: '221 4th St, San Francisco',
      rating: 4.5,
      tags: ['Quiet Hours', 'Creative', 'Interactive'],
      imageIcon: Icons.palette,
      color: AppColors.secondary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // Indoor Playgrounds
    Place(
      id: '3',
      name: 'Pump It Up SF',
      category: PlaceCategory.indoorPlayground,
      description: 'Indoor bounce house with special needs sessions',
      address: '560 Brannan St, San Francisco',
      rating: 4.4,
      tags: ['Indoor', 'Active', 'Special Sessions'],
      imageIcon: Icons.sports_handball,
      color: AppColors.quaternary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    Place(
      id: '4',
      name: 'Sensory Gym SF',
      category: PlaceCategory.indoorPlayground,
      description: 'Indoor gym designed for sensory integration',
      address: '1800 Jerrold Ave, San Francisco',
      rating: 4.8,
      tags: ['Indoor', 'Sensory', 'Therapeutic'],
      imageIcon: Icons.fitness_center,
      color: AppColors.tertiary,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.nonverbal],
    ),
    
    // Outdoor Playgrounds
    Place(
      id: '5',
      name: 'Magical Bridge Playground',
      category: PlaceCategory.outdoorPlayground,
      description: 'Fully inclusive outdoor playground for all abilities',
      address: '3700 Middlefield Rd, Palo Alto',
      rating: 4.9,
      tags: ['Outdoor', 'Inclusive', 'Wheelchair Accessible'],
      imageIcon: Icons.park,
      color: AppColors.success,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible, SpecialNeed.sensoryProcessing],
    ),
    Place(
      id: '6',
      name: 'Golden Gate Park Playground',
      category: PlaceCategory.outdoorPlayground,
      description: 'Large outdoor playground with accessible equipment',
      address: 'Golden Gate Park, San Francisco',
      rating: 4.4,
      tags: ['Outdoor', 'Large', 'Popular'],
      imageIcon: Icons.nature_people,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.wheelchairAccessible],
    ),
    
    // Doctors
    Place(
      id: '7',
      name: 'UCSF Autism Center',
      category: PlaceCategory.doctor,
      description: 'Comprehensive autism assessment and treatment',
      address: '401 Parnassus Ave, San Francisco',
      rating: 4.8,
      tags: ['Medical', 'Assessment', 'Treatment'],
      imageIcon: Icons.local_hospital,
      color: AppColors.error,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens, AgeGroup.adults],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal, SpecialNeed.sensoryProcessing],
    ),
    Place(
      id: '8',
      name: 'Stanford Autism Center',
      category: PlaceCategory.doctor,
      description: 'Research-based autism interventions',
      address: '401 Quarry Rd, Stanford',
      rating: 4.9,
      tags: ['Research', 'Medical', 'Specialized'],
      imageIcon: Icons.medical_services,
      color: AppColors.tertiary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    
    // Dentists
    Place(
      id: '9',
      name: 'Special Smiles Dentistry',
      category: PlaceCategory.dentist,
      description: 'Pediatric dentist specializing in special needs',
      address: '2000 Van Ness Ave, San Francisco',
      rating: 4.7,
      tags: ['Dentist', 'Special Needs', 'Pediatric'],
      imageIcon: Icons.medical_information,
      color: AppColors.info,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.nonverbal],
    ),
    Place(
      id: '10',
      name: 'Gentle Dental SF',
      category: PlaceCategory.dentist,
      description: 'Sensory-friendly dental care with quiet rooms',
      address: '450 Sutter St, San Francisco',
      rating: 4.6,
      tags: ['Dentist', 'Sensory-Friendly', 'Quiet'],
      imageIcon: Icons.health_and_safety,
      color: AppColors.secondary,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // Therapists
    Place(
      id: '11',
      name: 'Speech Therapy SF',
      category: PlaceCategory.therapist,
      description: 'Speech and language therapy for children',
      address: '2100 Webster St, San Francisco',
      rating: 4.7,
      tags: ['Speech', 'Language', 'Pediatric'],
      imageIcon: Icons.record_voice_over,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    Place(
      id: '12',
      name: 'Bay Area OT',
      category: PlaceCategory.therapist,
      description: 'Occupational therapy specializing in sensory integration',
      address: '1800 Divisadero St, San Francisco',
      rating: 4.6,
      tags: ['OT', 'Sensory', 'Motor Skills'],
      imageIcon: Icons.accessibility_new,
      color: AppColors.secondary,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // After-School Programs
    Place(
      id: '13',
      name: 'Friends of Children SF',
      category: PlaceCategory.afterSchool,
      description: 'After-school programs for special needs',
      address: '1660 Pine St, San Francisco',
      rating: 4.6,
      tags: ['After-School', 'Special Needs', 'Social'],
      imageIcon: Icons.groups,
      color: AppColors.info,
      ageGroups: [AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible],
    ),
    
    // Education
    Place(
      id: '14',
      name: 'Learning Differences Center',
      category: PlaceCategory.education,
      description: 'Specialized tutoring for neurodiverse learners',
      address: '3150 California St, San Francisco',
      rating: 4.8,
      tags: ['Education', 'Tutoring', 'Specialized'],
      imageIcon: Icons.school,
      color: AppColors.quaternary,
      ageGroups: [AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    
    // Restaurants
    Place(
      id: '15',
      name: 'Sensory-Safe Pizza Co.',
      category: PlaceCategory.restaurant,
      description: 'Pizza restaurant with quiet dining room',
      address: '2455 Fillmore St, San Francisco',
      rating: 4.4,
      tags: ['Restaurant', 'Quiet', 'Family-Friendly'],
      imageIcon: Icons.local_pizza,
      color: AppColors.secondary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // Additional Sensory-Friendly Venues
    Place(
      id: '16',
      name: 'Oakland Museum of California',
      category: PlaceCategory.sensoryFriendly,
      description: 'Museum with monthly sensory-friendly family days',
      address: '1000 Oak St, Oakland',
      rating: 4.6,
      tags: ['Museum', 'Sensory Hours', 'Educational'],
      imageIcon: Icons.account_balance,
      color: AppColors.tertiary,
      ageGroups: [AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.wheelchairAccessible],
    ),
    Place(
      id: '17',
      name: 'Bay Area Discovery Museum',
      category: PlaceCategory.sensoryFriendly,
      description: 'Children\'s museum with quiet mornings program',
      address: '557 McReynolds Rd, Sausalito',
      rating: 4.5,
      tags: ['Museum', 'Quiet Hours', 'Interactive'],
      imageIcon: Icons.explore,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // More Indoor Playgrounds
    Place(
      id: '18',
      name: 'We Rock the Spectrum',
      category: PlaceCategory.indoorPlayground,
      description: 'Sensory gym designed for children with special needs',
      address: '350 Townsend St, San Francisco',
      rating: 4.9,
      tags: ['Indoor', 'Sensory Gym', 'Inclusive'],
      imageIcon: Icons.sports_gymnastics,
      color: AppColors.success,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.nonverbal],
    ),
    Place(
      id: '19',
      name: 'Peekadoodle Kidsclub',
      category: PlaceCategory.indoorPlayground,
      description: 'Indoor playground with special needs accommodations',
      address: '900 North Point St, San Francisco',
      rating: 4.3,
      tags: ['Indoor', 'Play Area', 'Birthday Parties'],
      imageIcon: Icons.celebration,
      color: AppColors.quaternary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible],
    ),
    
    // More Outdoor Playgrounds
    Place(
      id: '20',
      name: 'Koret Children\'s Quarter',
      category: PlaceCategory.outdoorPlayground,
      description: 'Historic playground with accessible play structures',
      address: '320 Bowling Green Dr, San Francisco',
      rating: 4.5,
      tags: ['Outdoor', 'Historic', 'Large'],
      imageIcon: Icons.castle,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.wheelchairAccessible],
    ),
    Place(
      id: '21',
      name: 'Mitchell Park Playground',
      category: PlaceCategory.outdoorPlayground,
      description: 'Inclusive playground with sensory play elements',
      address: '600 E Meadow Dr, Palo Alto',
      rating: 4.7,
      tags: ['Outdoor', 'Inclusive', 'Sensory Elements'],
      imageIcon: Icons.nature,
      color: AppColors.success,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible, SpecialNeed.sensoryProcessing],
    ),
    
    // More Therapists
    Place(
      id: '22',
      name: 'Bloom Pediatric Therapy',
      category: PlaceCategory.therapist,
      description: 'ABA therapy and behavioral support services',
      address: '1550 Bryant St, San Francisco',
      rating: 4.8,
      tags: ['ABA', 'Behavioral', 'Therapy'],
      imageIcon: Icons.psychology_outlined,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    Place(
      id: '23',
      name: 'Sensory Kids SF',
      category: PlaceCategory.therapist,
      description: 'Sensory integration and occupational therapy',
      address: '2255 Post St, San Francisco',
      rating: 4.7,
      tags: ['OT', 'Sensory Integration', 'Pediatric'],
      imageIcon: Icons.self_improvement,
      color: AppColors.secondary,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    Place(
      id: '24',
      name: 'Communication Works',
      category: PlaceCategory.therapist,
      description: 'Speech therapy specializing in AAC devices',
      address: '825 Van Ness Ave, San Francisco',
      rating: 4.6,
      tags: ['Speech', 'AAC', 'Communication'],
      imageIcon: Icons.speaker_phone,
      color: AppColors.tertiary,
      ageGroups: [AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    
    // More Doctors
    Place(
      id: '25',
      name: 'Developmental Pediatrics SF',
      category: PlaceCategory.doctor,
      description: 'Specialized care for developmental disabilities',
      address: '1825 4th St, San Francisco',
      rating: 4.7,
      tags: ['Pediatrics', 'Developmental', 'Medical'],
      imageIcon: Icons.child_care,
      color: AppColors.error,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    Place(
      id: '26',
      name: 'Bay Area Autism Clinic',
      category: PlaceCategory.doctor,
      description: 'Comprehensive autism evaluation and treatment',
      address: '2500 Hospital Dr, Mountain View',
      rating: 4.8,
      tags: ['Autism', 'Evaluation', 'Treatment'],
      imageIcon: Icons.medical_information,
      color: AppColors.primary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // More Education Centers
    Place(
      id: '27',
      name: 'Spectrum Learning Center',
      category: PlaceCategory.education,
      description: 'Specialized education for children on the spectrum',
      address: '1290 Parkmoor Ave, San Jose',
      rating: 4.9,
      tags: ['Special Education', 'Learning', 'Support'],
      imageIcon: Icons.menu_book,
      color: AppColors.quaternary,
      ageGroups: [AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal, SpecialNeed.sensoryProcessing],
    ),
    Place(
      id: '28',
      name: 'Bridges Academy',
      category: PlaceCategory.education,
      description: 'Inclusive preschool with special needs support',
      address: '456 Ellis St, San Francisco',
      rating: 4.6,
      tags: ['Preschool', 'Inclusive', 'Early Education'],
      imageIcon: Icons.abc,
      color: AppColors.info,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible],
    ),
    
    // More After-School Programs
    Place(
      id: '29',
      name: 'Autism Society SF',
      category: PlaceCategory.afterSchool,
      description: 'Social skills groups and after-school programs',
      address: '1901 Mission St, San Francisco',
      rating: 4.5,
      tags: ['Social Skills', 'Group Activities', 'Support'],
      imageIcon: Icons.people,
      color: AppColors.primary,
      ageGroups: [AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.nonverbal],
    ),
    Place(
      id: '30',
      name: 'Special Kids Crusade',
      category: PlaceCategory.afterSchool,
      description: 'Recreational programs for special needs children',
      address: '760 Harrison St, San Francisco',
      rating: 4.7,
      tags: ['Recreation', 'Sports', 'Activities'],
      imageIcon: Icons.sports_soccer,
      color: AppColors.success,
      ageGroups: [AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible, SpecialNeed.sensoryProcessing],
    ),
    
    // More Restaurants
    Place(
      id: '31',
      name: 'Quiet Corner Café',
      category: PlaceCategory.restaurant,
      description: 'Autism-friendly café with visual menus',
      address: '890 Valencia St, San Francisco',
      rating: 4.5,
      tags: ['Café', 'Visual Menus', 'Quiet'],
      imageIcon: Icons.coffee,
      color: AppColors.tertiary,
      ageGroups: [AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens, AgeGroup.adults],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.nonverbal],
    ),
    Place(
      id: '32',
      name: 'Family Table Restaurant',
      category: PlaceCategory.restaurant,
      description: 'Family restaurant with sensory-friendly dining area',
      address: '1200 9th Ave, San Francisco',
      rating: 4.3,
      tags: ['Family Dining', 'Sensory Area', 'Kids Menu'],
      imageIcon: Icons.restaurant_menu,
      color: AppColors.secondary,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // More Dentists
    Place(
      id: '33',
      name: 'Pediatric Dental Specialists',
      category: PlaceCategory.dentist,
      description: 'Special needs dentistry with sedation options',
      address: '3000 California St, San Francisco',
      rating: 4.8,
      tags: ['Pediatric', 'Special Needs', 'Sedation'],
      imageIcon: Icons.clean_hands,
      color: AppColors.info,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing, SpecialNeed.nonverbal],
    ),
    Place(
      id: '34',
      name: 'Comfort Dental Kids',
      category: PlaceCategory.dentist,
      description: 'Sensory-adapted dental care for children',
      address: '1750 Montgomery St, San Francisco',
      rating: 4.6,
      tags: ['Kids Dentist', 'Sensory-Adapted', 'Gentle'],
      imageIcon: Icons.sentiment_satisfied,
      color: AppColors.primary,
      ageGroups: [AgeGroup.infants, AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.sensoryProcessing],
    ),
    
    // Swimming and Water Activities
    Place(
      id: '35',
      name: 'Aqua Abilities Swim',
      category: PlaceCategory.sensoryFriendly,
      description: 'Adaptive swimming lessons for special needs',
      address: '1 Tennis Dr, San Francisco',
      rating: 4.9,
      tags: ['Swimming', 'Adaptive', 'Water Therapy'],
      imageIcon: Icons.pool,
      color: AppColors.info,
      ageGroups: [AgeGroup.toddlers, AgeGroup.preschool, AgeGroup.schoolAge, AgeGroup.teens],
      specialNeeds: [SpecialNeed.autism, SpecialNeed.wheelchairAccessible, SpecialNeed.sensoryProcessing],
    ),
  ];
  
  List<Place> get filteredPlaces {
    var places = _allPlaces;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      places = places.where((place) =>
        place.name.toLowerCase().contains(searchTerm) ||
        place.description.toLowerCase().contains(searchTerm) ||
        place.tags.any((tag) => tag.toLowerCase().contains(searchTerm))
      ).toList();
    }
    
    // Apply category filters
    final hasAnyCategoryFilter = _showSensoryFriendly || _showPlaygrounds || 
        _showIndoorPlaygrounds || _showOutdoorPlaygrounds || _showDoctors || 
        _showDentists || _showTherapists || _showAfterSchool || 
        _showRestaurants || _showEducation;
        
    if (hasAnyCategoryFilter) {
      places = places.where((place) {
        if (_showSensoryFriendly && place.category == PlaceCategory.sensoryFriendly) return true;
        if (_showPlaygrounds && (place.category == PlaceCategory.indoorPlayground || place.category == PlaceCategory.outdoorPlayground)) return true;
        if (_showIndoorPlaygrounds && place.category == PlaceCategory.indoorPlayground) return true;
        if (_showOutdoorPlaygrounds && place.category == PlaceCategory.outdoorPlayground) return true;
        if (_showDoctors && place.category == PlaceCategory.doctor) return true;
        if (_showDentists && place.category == PlaceCategory.dentist) return true;
        if (_showTherapists && place.category == PlaceCategory.therapist) return true;
        if (_showAfterSchool && place.category == PlaceCategory.afterSchool) return true;
        if (_showRestaurants && place.category == PlaceCategory.restaurant) return true;
        if (_showEducation && place.category == PlaceCategory.education) return true;
        return false;
      }).toList();
    }
    
    // Apply age group filters
    final hasAnyAgeFilter = _ageInfants || _ageToddlers || _agePreschool || 
        _ageSchoolAge || _ageTeens || _ageAdults;
        
    if (hasAnyAgeFilter) {
      places = places.where((place) {
        if (_ageInfants && place.ageGroups.contains(AgeGroup.infants)) return true;
        if (_ageToddlers && place.ageGroups.contains(AgeGroup.toddlers)) return true;
        if (_agePreschool && place.ageGroups.contains(AgeGroup.preschool)) return true;
        if (_ageSchoolAge && place.ageGroups.contains(AgeGroup.schoolAge)) return true;
        if (_ageTeens && place.ageGroups.contains(AgeGroup.teens)) return true;
        if (_ageAdults && place.ageGroups.contains(AgeGroup.adults)) return true;
        return false;
      }).toList();
    }
    
    // Apply special needs filters
    final hasAnySpecialNeedsFilter = _autismSpecific || _wheelchairAccessible || 
        _nonverbal || _sensoryProcessing;
        
    if (hasAnySpecialNeedsFilter) {
      places = places.where((place) {
        if (_autismSpecific && place.specialNeeds.contains(SpecialNeed.autism)) return true;
        if (_wheelchairAccessible && place.specialNeeds.contains(SpecialNeed.wheelchairAccessible)) return true;
        if (_nonverbal && place.specialNeeds.contains(SpecialNeed.nonverbal)) return true;
        if (_sensoryProcessing && place.specialNeeds.contains(SpecialNeed.sensoryProcessing)) return true;
        return false;
      }).toList();
    }
    
    return places;
  }
  
  List<Place> get savedPlaces {
    return _allPlaces.where((place) => _savedPlaceIds.contains(place.id)).toList();
  }
  
  Map<PlaceCategory, List<Place>> get savedPlacesByCategory {
    final Map<PlaceCategory, List<Place>> categorized = {};
    for (final place in savedPlaces) {
      categorized.putIfAbsent(place.category, () => []).add(place);
    }
    return categorized;
  }
  
  void _toggleSavePlace(String placeId) {
    setState(() {
      if (_savedPlaceIds.contains(placeId)) {
        _savedPlaceIds.remove(placeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place removed from saved'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _savedPlaceIds.add(placeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place saved!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }
  
  void _getDirections(Place place) {
    // TODO: Open maps app with directions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${place.name}'),
        backgroundColor: AppColors.info,
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                // Clear all filters
                                _showSensoryFriendly = false;
                                _showPlaygrounds = false;
                                _showIndoorPlaygrounds = false;
                                _showOutdoorPlaygrounds = false;
                                _showDoctors = false;
                                _showDentists = false;
                                _showTherapists = false;
                                _showAfterSchool = false;
                                _showRestaurants = false;
                                _showEducation = false;
                                _ageInfants = false;
                                _ageToddlers = false;
                                _agePreschool = false;
                                _ageSchoolAge = false;
                                _ageTeens = false;
                                _ageAdults = false;
                                _autismSpecific = false;
                                _wheelchairAccessible = false;
                                _nonverbal = false;
                                _sensoryProcessing = false;
                              });
                              setState(() {});
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Filter Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories
                            const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Sensory-Friendly'),
                                  selected: _showSensoryFriendly,
                                  onSelected: (value) {
                                    setDialogState(() => _showSensoryFriendly = value);
                                    setState(() => _showSensoryFriendly = value);
                                  },
                                  selectedColor: AppColors.primary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('All Playgrounds'),
                                  selected: _showPlaygrounds,
                                  onSelected: (value) {
                                    setDialogState(() => _showPlaygrounds = value);
                                    setState(() => _showPlaygrounds = value);
                                  },
                                  selectedColor: AppColors.secondary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Indoor Play'),
                                  selected: _showIndoorPlaygrounds,
                                  onSelected: (value) {
                                    setDialogState(() => _showIndoorPlaygrounds = value);
                                    setState(() => _showIndoorPlaygrounds = value);
                                  },
                                  selectedColor: AppColors.quaternary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Outdoor Play'),
                                  selected: _showOutdoorPlaygrounds,
                                  onSelected: (value) {
                                    setDialogState(() => _showOutdoorPlaygrounds = value);
                                    setState(() => _showOutdoorPlaygrounds = value);
                                  },
                                  selectedColor: AppColors.success.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Doctors'),
                                  selected: _showDoctors,
                                  onSelected: (value) {
                                    setDialogState(() => _showDoctors = value);
                                    setState(() => _showDoctors = value);
                                  },
                                  selectedColor: AppColors.error.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Dentists'),
                                  selected: _showDentists,
                                  onSelected: (value) {
                                    setDialogState(() => _showDentists = value);
                                    setState(() => _showDentists = value);
                                  },
                                  selectedColor: AppColors.info.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Therapists'),
                                  selected: _showTherapists,
                                  onSelected: (value) {
                                    setDialogState(() => _showTherapists = value);
                                    setState(() => _showTherapists = value);
                                  },
                                  selectedColor: AppColors.tertiary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('After-School'),
                                  selected: _showAfterSchool,
                                  onSelected: (value) {
                                    setDialogState(() => _showAfterSchool = value);
                                    setState(() => _showAfterSchool = value);
                                  },
                                  selectedColor: AppColors.info.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Education'),
                                  selected: _showEducation,
                                  onSelected: (value) {
                                    setDialogState(() => _showEducation = value);
                                    setState(() => _showEducation = value);
                                  },
                                  selectedColor: AppColors.quaternary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Restaurants'),
                                  selected: _showRestaurants,
                                  onSelected: (value) {
                                    setDialogState(() => _showRestaurants = value);
                                    setState(() => _showRestaurants = value);
                                  },
                                  selectedColor: AppColors.secondary.withOpacity(0.2),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Age Groups
                            const Text(
                              'Age Groups',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Infants (0-2)'),
                                  selected: _ageInfants,
                                  onSelected: (value) {
                                    setDialogState(() => _ageInfants = value);
                                    setState(() => _ageInfants = value);
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Toddlers (2-4)'),
                                  selected: _ageToddlers,
                                  onSelected: (value) {
                                    setDialogState(() => _ageToddlers = value);
                                    setState(() => _ageToddlers = value);
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Preschool (4-6)'),
                                  selected: _agePreschool,
                                  onSelected: (value) {
                                    setDialogState(() => _agePreschool = value);
                                    setState(() => _agePreschool = value);
                                  },
                                ),
                                FilterChip(
                                  label: const Text('School Age (6-12)'),
                                  selected: _ageSchoolAge,
                                  onSelected: (value) {
                                    setDialogState(() => _ageSchoolAge = value);
                                    setState(() => _ageSchoolAge = value);
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Teens (12-18)'),
                                  selected: _ageTeens,
                                  onSelected: (value) {
                                    setDialogState(() => _ageTeens = value);
                                    setState(() => _ageTeens = value);
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Adults (18+)'),
                                  selected: _ageAdults,
                                  onSelected: (value) {
                                    setDialogState(() => _ageAdults = value);
                                    setState(() => _ageAdults = value);
                                  },
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Special Needs
                            const Text(
                              'Special Needs Specific',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Autism Specific'),
                                  selected: _autismSpecific,
                                  onSelected: (value) {
                                    setDialogState(() => _autismSpecific = value);
                                    setState(() => _autismSpecific = value);
                                  },
                                  selectedColor: AppColors.primary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Wheelchair Accessible'),
                                  selected: _wheelchairAccessible,
                                  onSelected: (value) {
                                    setDialogState(() => _wheelchairAccessible = value);
                                    setState(() => _wheelchairAccessible = value);
                                  },
                                  selectedColor: AppColors.secondary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Nonverbal Support'),
                                  selected: _nonverbal,
                                  onSelected: (value) {
                                    setDialogState(() => _nonverbal = value);
                                    setState(() => _nonverbal = value);
                                  },
                                  selectedColor: AppColors.tertiary.withOpacity(0.2),
                                ),
                                FilterChip(
                                  label: const Text('Sensory Processing'),
                                  selected: _sensoryProcessing,
                                  onSelected: (value) {
                                    setDialogState(() => _sensoryProcessing = value);
                                    setState(() => _sensoryProcessing = value);
                                  },
                                  selectedColor: AppColors.quaternary.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Apply Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildPlaceCard(Place place, {bool showRemoveButton = false}) {
    final isSaved = _savedPlaceIds.contains(place.id);
    
    return Container(
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
          // Image/Icon Section
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  place.color.withOpacity(0.1),
                  place.color.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    place.imageIcon,
                    size: 50,
                    color: place.color.withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: isSaved ? place.color : Colors.grey,
                    ),
                    onPressed: () => _toggleSavePlace(place.id),
                  ),
                ),
                if (place.rating > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: place.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: place.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: place.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                
                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _getDirections(place),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (showRemoveButton) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _toggleSavePlace(place.id),
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCatalogTab() {
    return Column(
      children: [
        // Search bar with filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search places...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: activeFilterCount > 0 ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activeFilterCount > 0 ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _showFilterDialog,
                      icon: Icon(
                        Icons.tune,
                        color: activeFilterCount > 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          activeFilterCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Places count
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          alignment: Alignment.centerLeft,
          child: Text(
            '${filteredPlaces.length} Places Found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Places List
        Expanded(
          child: filteredPlaces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No places found',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPlaces.length,
                  itemBuilder: (context, index) => _buildPlaceCard(filteredPlaces[index]),
                ),
        ),
      ],
    );
  }
  
  Widget _buildSavedTab() {
    if (savedPlaces.isEmpty) {
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
              'No saved places yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark places to see them here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...savedPlacesByCategory.entries.map((entry) {
          final category = entry.key;
          final places = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: _getCategoryColor(category),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getCategoryName(category),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        places.length.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...places.map((place) => _buildPlaceCard(place, showRemoveButton: true)),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  String _getCategoryName(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.sensoryFriendly:
        return 'Sensory-Friendly';
      case PlaceCategory.indoorPlayground:
        return 'Indoor Playgrounds';
      case PlaceCategory.outdoorPlayground:
        return 'Outdoor Playgrounds';
      case PlaceCategory.doctor:
        return 'Doctors';
      case PlaceCategory.dentist:
        return 'Dentists';
      case PlaceCategory.therapist:
        return 'Therapists';
      case PlaceCategory.afterSchool:
        return 'After-School';
      case PlaceCategory.education:
        return 'Education';
      case PlaceCategory.restaurant:
        return 'Restaurants';
    }
  }
  
  IconData _getCategoryIcon(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.sensoryFriendly:
        return Icons.spa;
      case PlaceCategory.indoorPlayground:
        return Icons.sports_handball;
      case PlaceCategory.outdoorPlayground:
        return Icons.park;
      case PlaceCategory.doctor:
        return Icons.medical_services;
      case PlaceCategory.dentist:
        return Icons.medical_information;
      case PlaceCategory.therapist:
        return Icons.psychology;
      case PlaceCategory.afterSchool:
        return Icons.school;
      case PlaceCategory.education:
        return Icons.cast_for_education;
      case PlaceCategory.restaurant:
        return Icons.restaurant;
    }
  }
  
  Color _getCategoryColor(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.sensoryFriendly:
        return AppColors.primary;
      case PlaceCategory.indoorPlayground:
        return AppColors.quaternary;
      case PlaceCategory.outdoorPlayground:
        return AppColors.success;
      case PlaceCategory.doctor:
        return AppColors.error;
      case PlaceCategory.dentist:
        return AppColors.info;
      case PlaceCategory.therapist:
        return AppColors.tertiary;
      case PlaceCategory.afterSchool:
        return AppColors.info;
      case PlaceCategory.education:
        return AppColors.quaternary;
      case PlaceCategory.restaurant:
        return AppColors.secondary;
    }
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
                    icon: Icon(Icons.explore, size: 24),
                    text: 'Catalogue',
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
                _buildCatalogTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Place model
class Place {
  final String id;
  final String name;
  final PlaceCategory category;
  final String description;
  final String address;
  final double rating;
  final List<String> tags;
  final IconData imageIcon;
  final Color color;
  final List<AgeGroup> ageGroups;
  final List<SpecialNeed> specialNeeds;
  
  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.rating,
    required this.tags,
    required this.imageIcon,
    required this.color,
    required this.ageGroups,
    required this.specialNeeds,
  });
}

enum PlaceCategory {
  sensoryFriendly,
  indoorPlayground,
  outdoorPlayground,
  doctor,
  dentist,
  therapist,
  afterSchool,
  education,
  restaurant,
}

enum AgeGroup {
  infants, // 0-2
  toddlers, // 2-4
  preschool, // 4-6
  schoolAge, // 6-12
  teens, // 12-18
  adults, // 18+
}

enum SpecialNeed {
  autism,
  wheelchairAccessible,
  nonverbal,
  sensoryProcessing,
}