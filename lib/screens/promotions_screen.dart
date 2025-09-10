import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Therapy',
    'Activities',
    'Products',
    'Restaurants',
    'Education',
  ];
  
  final List<Promotion> _promotions = [
    // Therapy Promotions
    Promotion(
      id: '1',
      title: '20% Off Speech Therapy Sessions',
      business: 'Speech Therapy SF',
      description: 'New families get 20% off their first month of speech therapy sessions.',
      category: PromotionCategory.therapy,
      discount: '20% OFF',
      validUntil: 'Dec 31, 2024',
      imageIcon: Icons.record_voice_over,
      color: AppColors.primary,
    ),
    Promotion(
      id: '2',
      title: 'Free OT Assessment',
      business: 'Bay Area Occupational Therapy',
      description: 'Complimentary initial assessment for children with sensory processing needs.',
      category: PromotionCategory.therapy,
      discount: 'FREE',
      validUntil: 'Nov 30, 2024',
      imageIcon: Icons.accessibility_new,
      color: AppColors.tertiary,
    ),
    Promotion(
      id: '3',
      title: 'ABA Therapy Package Deal',
      business: 'Spectrum Behavioral Services',
      description: 'Save \$500 on 3-month intensive ABA therapy package.',
      category: PromotionCategory.therapy,
      discount: '\$500 OFF',
      validUntil: 'Jan 15, 2025',
      imageIcon: Icons.psychology,
      color: AppColors.secondary,
    ),
    
    // Activities Promotions
    Promotion(
      id: '4',
      title: 'Museum Sensory Hours',
      business: 'California Academy of Sciences',
      description: 'Free admission during monthly sensory-friendly hours for families.',
      category: PromotionCategory.activities,
      discount: 'FREE ENTRY',
      validUntil: 'Ongoing',
      imageIcon: Icons.museum,
      color: AppColors.quaternary,
    ),
    Promotion(
      id: '5',
      title: 'Swim Lessons Discount',
      business: 'Aqua Kids Swimming',
      description: 'Special needs swim program - 15% off for new students.',
      category: PromotionCategory.activities,
      discount: '15% OFF',
      validUntil: 'Dec 15, 2024',
      imageIcon: Icons.pool,
      color: AppColors.info,
    ),
    Promotion(
      id: '6',
      title: 'Art Class Bundle',
      business: 'Creative Minds Studio',
      description: 'Buy 5 sensory art classes, get 2 free. Small groups, calm environment.',
      category: PromotionCategory.activities,
      discount: '2 FREE',
      validUntil: 'Jan 31, 2025',
      imageIcon: Icons.palette,
      color: AppColors.primary,
    ),
    
    // Products Promotions
    Promotion(
      id: '7',
      title: 'Sensory Tools Sale',
      business: 'Therapy Shoppe',
      description: '30% off weighted blankets, fidget tools, and noise-canceling headphones.',
      category: PromotionCategory.products,
      discount: '30% OFF',
      validUntil: 'Nov 25, 2024',
      imageIcon: Icons.shopping_bag,
      color: AppColors.tertiary,
    ),
    Promotion(
      id: '8',
      title: 'Communication Device Grant',
      business: 'AAC Solutions',
      description: 'Apply for \$1000 grant toward communication devices and apps.',
      category: PromotionCategory.products,
      discount: '\$1000 GRANT',
      validUntil: 'Dec 1, 2024',
      imageIcon: Icons.tablet,
      color: AppColors.secondary,
    ),
    Promotion(
      id: '9',
      title: 'Adaptive Clothing',
      business: 'Comfort Wear Kids',
      description: 'Buy 2 get 1 free on all sensory-friendly clothing items.',
      category: PromotionCategory.products,
      discount: 'BUY 2 GET 1',
      validUntil: 'Jan 10, 2025',
      imageIcon: Icons.checkroom,
      color: AppColors.quaternary,
    ),
    
    // Restaurant Promotions
    Promotion(
      id: '10',
      title: 'Quiet Dining Hours',
      business: 'Family Table Restaurant',
      description: 'Kids eat free during sensory-friendly hours (Tues 4-6pm).',
      category: PromotionCategory.restaurants,
      discount: 'KIDS FREE',
      validUntil: 'Ongoing',
      imageIcon: Icons.restaurant,
      color: AppColors.info,
    ),
    Promotion(
      id: '11',
      title: 'Pizza Night Special',
      business: 'Sensory-Safe Pizza Co.',
      description: '25% off family meals in private sensory room. Pre-order available.',
      category: PromotionCategory.restaurants,
      discount: '25% OFF',
      validUntil: 'Dec 31, 2024',
      imageIcon: Icons.local_pizza,
      color: AppColors.primary,
    ),
    Promotion(
      id: '12',
      title: 'Smoothie Happy Hour',
      business: 'Healthy Blends Café',
      description: 'BOGO smoothies 2-4pm daily. Quiet seating area available.',
      category: PromotionCategory.restaurants,
      discount: 'BOGO',
      validUntil: 'Jan 20, 2025',
      imageIcon: Icons.local_drink,
      color: AppColors.secondary,
    ),
    
    // Education Promotions
    Promotion(
      id: '13',
      title: 'Tutoring Package',
      business: 'Learning Bridge Center',
      description: 'First month 50% off for specialized education support.',
      category: PromotionCategory.education,
      discount: '50% OFF',
      validUntil: 'Dec 20, 2024',
      imageIcon: Icons.school,
      color: AppColors.tertiary,
    ),
    Promotion(
      id: '14',
      title: 'Social Skills Group',
      business: 'Friends Together',
      description: 'Free trial week for social skills development program.',
      category: PromotionCategory.education,
      discount: 'FREE TRIAL',
      validUntil: 'Nov 30, 2024',
      imageIcon: Icons.groups,
      color: AppColors.quaternary,
    ),
    Promotion(
      id: '15',
      title: 'Parent Workshop Series',
      business: 'Autism Support Network',
      description: 'Free admission to monthly parent education workshops.',
      category: PromotionCategory.education,
      discount: 'FREE',
      validUntil: 'Ongoing',
      imageIcon: Icons.family_restroom,
      color: AppColors.info,
    ),
  ];
  
  List<Promotion> get filteredPromotions {
    if (_selectedCategory == 'All') {
      return _promotions;
    }
    
    final category = _getCategoryEnum(_selectedCategory);
    return _promotions.where((p) => p.category == category).toList();
  }
  
  PromotionCategory _getCategoryEnum(String category) {
    switch (category) {
      case 'Therapy':
        return PromotionCategory.therapy;
      case 'Activities':
        return PromotionCategory.activities;
      case 'Products':
        return PromotionCategory.products;
      case 'Restaurants':
        return PromotionCategory.restaurants;
      case 'Education':
        return PromotionCategory.education;
      default:
        return PromotionCategory.therapy;
    }
  }
  
  void _showPromotionDetails(Promotion promotion) {
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
                    color: promotion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    promotion.imageIcon,
                    color: promotion.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.business,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: promotion.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          promotion.discount,
                          style: TextStyle(
                            color: promotion.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Valid until ${promotion.validUntil}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    promotion.description,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved ${promotion.title}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_outline),
                    label: const Text('Save Offer'),
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
                      // TODO: Navigate to business or open website
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Claim Offer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: promotion.color,
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header with Categories
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_offer,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Special Offers',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exclusive deals from autism-friendly businesses',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Category Filter Chips
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          // Promotions List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final promotion = filteredPromotions[index];
                  
                  return GestureDetector(
                    onTap: () => _showPromotionDetails(promotion),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image/Icon Section
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  promotion.color.withOpacity(0.1),
                                  promotion.color.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    promotion.imageIcon,
                                    size: 60,
                                    color: promotion.color.withOpacity(0.3),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: promotion.color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      promotion.discount,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
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
                                  promotion.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  promotion.business,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  promotion.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          promotion.validUntil,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () => _showPromotionDetails(promotion),
                                      child: Row(
                                        children: [
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              color: promotion.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                            color: promotion.color,
                                          ),
                                        ],
                                      ),
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
                childCount: filteredPromotions.length,
              ),
            ),
          ),
          
          // Empty State
          if (filteredPromotions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No promotions in this category',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                      child: const Text('View all promotions'),
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

// Promotion model
class Promotion {
  final String id;
  final String title;
  final String business;
  final String description;
  final PromotionCategory category;
  final String discount;
  final String validUntil;
  final IconData imageIcon;
  final Color color;
  
  Promotion({
    required this.id,
    required this.title,
    required this.business,
    required this.description,
    required this.category,
    required this.discount,
    required this.validUntil,
    required this.imageIcon,
    required this.color,
  });
}

enum PromotionCategory {
  therapy,
  activities,
  products,
  restaurants,
  education,
}