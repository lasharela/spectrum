import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/catalog/domain/place.dart';
import 'package:spectrum_app/shared/domain/author.dart';
import 'package:spectrum_app/shared/domain/paginated_result.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

class CatalogRepository {
  // --- Mock Filter Options ---

  Future<List<FilterOption>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Sensory-Friendly', icon: 'spa'),
      FilterOption(id: '2', name: 'Indoor Playground', icon: 'sports_handball'),
      FilterOption(id: '3', name: 'Outdoor Playground', icon: 'park'),
      FilterOption(id: '4', name: 'Doctor', icon: 'medical_services'),
      FilterOption(id: '5', name: 'Dentist', icon: 'medical_information'),
      FilterOption(id: '6', name: 'Therapist', icon: 'psychology'),
      FilterOption(id: '7', name: 'After-School', icon: 'school'),
      FilterOption(id: '8', name: 'Education', icon: 'cast_for_education'),
      FilterOption(id: '9', name: 'Restaurant', icon: 'restaurant'),
    ];
  }

  Future<List<FilterOption>> getAgeGroups() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Infants (0-2)'),
      FilterOption(id: '2', name: 'Toddlers (2-4)'),
      FilterOption(id: '3', name: 'Preschool (4-6)'),
      FilterOption(id: '4', name: 'School Age (6-12)'),
      FilterOption(id: '5', name: 'Teens (12-18)'),
      FilterOption(id: '6', name: 'Adults (18+)'),
    ];
  }

  Future<List<FilterOption>> getSpecialNeeds() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Autism Specific'),
      FilterOption(id: '2', name: 'Wheelchair Accessible'),
      FilterOption(id: '3', name: 'Nonverbal Support'),
      FilterOption(id: '4', name: 'Sensory Processing'),
    ];
  }

  // --- Mock Places ---

  static final _mockAuthor = Author(
    id: 'owner-1',
    name: 'Spectrum Admin',
    userType: 'professional',
  );

  static final _mockPlaces = [
    Place(
      id: '1',
      name: 'Bay Area Discovery Museum',
      description: 'Interactive museum with sensory-friendly hours every Saturday morning. Quiet spaces available.',
      category: 'Sensory-Friendly',
      address: '557 McReynolds Rd, Sausalito, CA',
      averageRating: 4.7,
      ratingCount: 23,
      tags: ['museum', 'sensory-friendly', 'kids'],
      ageGroups: ['Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Autism Specific', 'Sensory Processing'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Place(
      id: '2',
      name: 'Golden Gate Park Playground',
      description: 'Accessible playground with rubber surfacing and sensory garden nearby.',
      category: 'Outdoor Playground',
      address: '320 Bowling Green Dr, San Francisco, CA',
      averageRating: 4.5,
      ratingCount: 41,
      tags: ['playground', 'outdoor', 'accessible'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Wheelchair Accessible', 'Autism Specific'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Place(
      id: '3',
      name: 'Dr. Sarah Chen — Developmental Pediatrics',
      description: 'Specializing in autism spectrum evaluation and support for children ages 2-18.',
      category: 'Doctor',
      address: '1200 El Camino Real, Suite 200, Palo Alto, CA',
      averageRating: 4.9,
      ratingCount: 67,
      tags: ['doctor', 'pediatrics', 'autism evaluation'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)', 'Teens (12-18)'],
      specialNeeds: ['Autism Specific'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Place(
      id: '4',
      name: 'Bright Futures ABA Therapy',
      description: 'Evidence-based ABA therapy center with individualized programs and parent training.',
      category: 'Therapist',
      address: '890 Market St, Suite 400, San Francisco, CA',
      averageRating: 4.6,
      ratingCount: 35,
      tags: ['therapy', 'ABA', 'parent training'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Autism Specific', 'Nonverbal Support'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Place(
      id: '5',
      name: 'The Sensory Caf\u00e9',
      description: 'Quiet dining environment with dim lighting, noise-canceling headphones available, and a picture menu.',
      category: 'Restaurant',
      address: '456 Valencia St, San Francisco, CA',
      averageRating: 4.3,
      ratingCount: 18,
      tags: ['restaurant', 'quiet dining', 'sensory-friendly'],
      ageGroups: ['Preschool (4-6)', 'School Age (6-12)', 'Teens (12-18)', 'Adults (18+)'],
      specialNeeds: ['Autism Specific', 'Sensory Processing'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Place(
      id: '6',
      name: 'Jump & Play Indoor Park',
      description: 'Sensory-friendly play sessions on Tuesday mornings. Trampolines, ball pits, and climbing walls.',
      category: 'Indoor Playground',
      address: '200 Industrial Way, San Carlos, CA',
      averageRating: 4.4,
      ratingCount: 29,
      tags: ['indoor', 'trampoline', 'sensory sessions'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Autism Specific', 'Sensory Processing'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Future<PaginatedResult<Place>> getPlaces({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
    Set<String>? ageGroups,
    Set<String>? specialNeeds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = List<Place>.from(_mockPlaces);

    // Text search
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false) ||
        p.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }

    // Category filter
    if (categories != null && categories.isNotEmpty) {
      filtered = filtered.where((p) => categories.contains(p.category)).toList();
    }

    // Age group filter
    if (ageGroups != null && ageGroups.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.ageGroups.any((ag) => ageGroups.contains(ag))
      ).toList();
    }

    // Special needs filter
    if (specialNeeds != null && specialNeeds.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.specialNeeds.any((sn) => specialNeeds.contains(sn))
      ).toList();
    }

    return PaginatedResult(items: filtered, nextCursor: null);
  }

  Future<Place?> getPlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockPlaces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> ratePlace(String id, int score) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op. Real API will upsert rating.
  }

  Future<void> savePlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op
  }

  Future<void> unsavePlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op
  }

  Future<List<Place>> getSavedPlaces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: return first 2 places as "saved"
    return _mockPlaces.take(2).map((p) => Place(
      id: p.id,
      name: p.name,
      description: p.description,
      category: p.category,
      address: p.address,
      imageUrl: p.imageUrl,
      averageRating: p.averageRating,
      ratingCount: p.ratingCount,
      tags: p.tags,
      ageGroups: p.ageGroups,
      specialNeeds: p.specialNeeds,
      ownerId: p.ownerId,
      owner: p.owner,
      saved: true,
      createdAt: p.createdAt,
    )).toList();
  }
}
