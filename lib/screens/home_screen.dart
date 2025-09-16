import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: AppColors.cardBorderStyle,
                  boxShadow: [AppColors.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back, Alex!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What special activities should we plan today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Hottest Promotions Section
              const Text(
                'Hottest Promotions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPromotionCard(
                      title: '50% Off Sensory Toys',
                      store: 'Learning Express',
                      discount: '50%',
                      color: AppColors.accent1,
                    ),
                    const SizedBox(width: 12),
                    _buildPromotionCard(
                      title: 'Free Therapy Session',
                      store: 'Wellness Center',
                      discount: 'FREE',
                      color: AppColors.quaternary,
                    ),
                    const SizedBox(width: 12),
                    _buildPromotionCard(
                      title: 'Buy 1 Get 1 Books',
                      store: 'Barnes & Noble',
                      discount: 'BOGO',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    _buildPromotionCard(
                      title: '30% Off Art Supplies',
                      store: 'Creative Kids',
                      discount: '30%',
                      color: AppColors.tertiary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Popular Places Section
              const Text(
                'Popular Places',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              _buildPlaceCard(
                name: 'Sensory Garden Park',
                address: '123 Oak Street',
                distance: '0.5 miles',
              ),
              const SizedBox(height: 12),
              _buildPlaceCard(
                name: 'Quiet Library Zone',
                address: '456 Main Avenue',
                distance: '1.2 miles',
              ),
              const SizedBox(height: 12),
              _buildPlaceCard(
                name: 'Therapy Center',
                address: '789 Wellness Blvd',
                distance: '2.0 miles',
              ),
              
              const SizedBox(height: 25),
              
              // Upcoming Events
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              _buildEventCard(
                title: 'Parent Support Group',
                time: '10:00 AM',
                location: 'Community Center',
                category: 'Support',
              ),
              const SizedBox(height: 12),
              _buildEventCard(
                title: 'Art Therapy Session',
                time: '2:00 PM',
                location: 'Creative Studio',
                category: 'Therapy',
              ),
              
              const SizedBox(height: 25),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(
                    child: _buildResourceCard(
                      icon: Icons.support_agent,
                      label: 'Support',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResourceCard(
                      icon: Icons.lightbulb_outline,
                      label: 'Suggest',
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResourceCard(
                      icon: Icons.language,
                      label: 'Website',
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromotionCard({
    required String title,
    required String store,
    required String discount,
    required Color color,
  }) {
    return Container(
      width: 160,
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AppColors.cardBorderStyle,
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  discount,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Text(
            store,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard({
    required String name,
    required String address,
    required String distance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AppColors.cardBorderStyle,
        boxShadow: [AppColors.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.place,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  distance,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get directions',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventCard({
    required String title,
    required String time,
    required String location,
    required String category,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AppColors.cardBorderStyle,
        boxShadow: [AppColors.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResourceCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AppColors.cardBorderStyle,
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}