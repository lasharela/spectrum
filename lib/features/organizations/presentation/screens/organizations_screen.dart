import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  
  final List<String> _filters = [
    'All',
    'Healthcare',
    'Dentistry',
    'Hair Salon',
    'Recreation',
    'Education',
    'Therapy',
    'Restaurant',
  ];

  final List<Map<String, dynamic>> _organizations = [
    // Healthcare
    {
      'name': 'Stanford Children\'s Health - Autism Center',
      'type': 'Healthcare',
      'address': '700 Welch Road, Palo Alto, CA 94304',
      'phone': '(650) 723-5281',
      'rating': 4.8,
      'certified': true,
      'features': ['Sensory-friendly rooms', 'Visual schedules', 'Trained staff'],
      'description': 'Comprehensive autism diagnostic and treatment center with specialized pediatric care.',
      'icon': Icons.local_hospital,
      'color': AppColors.cyan,
    },
    {
      'name': 'UCSF Benioff Children\'s Hospital',
      'type': 'Healthcare',
      'address': '1825 4th Street, San Francisco, CA 94158',
      'phone': '(415) 476-1000',
      'rating': 4.7,
      'certified': true,
      'features': ['Quiet waiting areas', 'Flexible scheduling', 'Autism specialists'],
      'description': 'Leading pediatric hospital with dedicated autism and neurodevelopmental program.',
      'icon': Icons.local_hospital,
      'color': AppColors.cyan,
    },
    {
      'name': 'Kaiser Permanente Autism Center',
      'type': 'Healthcare',
      'address': '2350 Geary Blvd, San Francisco, CA 94115',
      'phone': '(415) 833-2000',
      'rating': 4.5,
      'certified': true,
      'features': ['Early intervention', 'Family support', 'Multidisciplinary team'],
      'description': 'Integrated autism services including diagnosis, therapy, and family resources.',
      'icon': Icons.local_hospital,
      'color': AppColors.cyan,
    },
    
    // Dentistry
    {
      'name': 'Smile Builders Pediatric Dentistry',
      'type': 'Dentistry',
      'address': '1241 Woodland Ave, San Carlos, CA 94070',
      'phone': '(650) 593-5437',
      'rating': 5.0,
      'certified': true,
      'features': ['Sensory-adapted environment', 'Pre-visit tours', 'Calming techniques'],
      'description': 'Autism-friendly dental practice specializing in children with special needs.',
      'icon': Icons.medical_services,
      'color': AppColors.coral,
    },
    {
      'name': 'Peninsula Pediatric Dentistry',
      'type': 'Dentistry',
      'address': '897 Independence Ave, Mountain View, CA 94043',
      'phone': '(650) 965-1838',
      'rating': 4.9,
      'certified': true,
      'features': ['Quiet hours', 'Visual supports', 'Sensory tools'],
      'description': 'Certified autism-friendly dental office with specially trained staff.',
      'icon': Icons.medical_services,
      'color': AppColors.coral,
    },
    {
      'name': 'Special Care Dentistry',
      'type': 'Dentistry',
      'address': '2299 Post St, San Francisco, CA 94115',
      'phone': '(415) 929-6400',
      'rating': 4.8,
      'certified': true,
      'features': ['Hospital dentistry option', 'Sedation available', 'Special needs expertise'],
      'description': 'Specialized dental care for patients with autism and developmental disabilities.',
      'icon': Icons.medical_services,
      'color': AppColors.coral,
    },
    
    // Hair Salons
    {
      'name': 'Snip-its Haircuts for Kids',
      'type': 'Hair Salon',
      'address': '1622 El Camino Real, Redwood City, CA 94063',
      'phone': '(650) 365-7647',
      'rating': 4.7,
      'certified': true,
      'features': ['Sensory-friendly cuts', 'Quiet appointments', 'Patient stylists'],
      'description': 'Children\'s salon with autism awareness training and sensory accommodations.',
      'icon': Icons.content_cut,
      'color': AppColors.yellow,
    },
    {
      'name': 'The Spectrum Salon',
      'type': 'Hair Salon',
      'address': '425 California St, Palo Alto, CA 94301',
      'phone': '(650) 321-1234',
      'rating': 5.0,
      'certified': true,
      'features': ['Private rooms', 'Flexible timing', 'Sensory breaks'],
      'description': 'Dedicated autism-friendly salon with quiet hours and trained stylists.',
      'icon': Icons.content_cut,
      'color': AppColors.yellow,
    },
    
    // Recreation
    {
      'name': 'Bay Area Discovery Museum',
      'type': 'Recreation',
      'address': '557 McReynolds Rd, Sausalito, CA 94965',
      'phone': '(415) 339-3900',
      'rating': 4.6,
      'certified': true,
      'features': ['Sensory-friendly hours', 'Quiet spaces', 'Visual guides'],
      'description': 'Children\'s museum with monthly autism-friendly mornings and accommodations.',
      'icon': Icons.museum,
      'color': AppColors.navy,
    },
    {
      'name': 'Happy Hollow Park & Zoo',
      'type': 'Recreation',
      'address': '1300 Senter Rd, San Jose, CA 95112',
      'phone': '(408) 794-6400',
      'rating': 4.5,
      'certified': true,
      'features': ['Sensory map', 'Quiet zones', 'Early entry options'],
      'description': 'Zoo and amusement park with autism-friendly programs and sensory accommodations.',
      'icon': Icons.pets,
      'color': AppColors.navy,
    },
    {
      'name': 'We Rock the Spectrum - San Jose',
      'type': 'Recreation',
      'address': '1425 S Winchester Blvd, San Jose, CA 95128',
      'phone': '(408) 684-9825',
      'rating': 4.9,
      'certified': true,
      'features': ['Sensory gym', 'Inclusive play', 'Trained staff'],
      'description': 'Indoor playground designed specifically for children with autism and special needs.',
      'icon': Icons.sports_handball,
      'color': AppColors.navy,
    },
    
    // Education
    {
      'name': 'The Espin Foundation Learning Center',
      'type': 'Education',
      'address': '1730 S Amphlett Blvd, San Mateo, CA 94402',
      'phone': '(650) 312-1343',
      'rating': 4.8,
      'certified': true,
      'features': ['ABA therapy', 'Social skills groups', 'Parent training'],
      'description': 'Comprehensive learning center for children with autism spectrum disorders.',
      'icon': Icons.school,
      'color': AppColors.orange,
    },
    {
      'name': 'Morgan Autism Center',
      'type': 'Education',
      'address': '300 Curtner Ave, San Jose, CA 95125',
      'phone': '(408) 241-8161',
      'rating': 4.9,
      'certified': true,
      'features': ['Day programs', 'Adult services', 'Family support'],
      'description': 'Non-profit serving children and adults with autism through education and therapy.',
      'icon': Icons.school,
      'color': AppColors.orange,
    },
    
    // Therapy Centers
    {
      'name': 'Autism Therapy Group',
      'type': 'Therapy',
      'address': '3636 N Laughlin Rd, Santa Rosa, CA 95403',
      'phone': '(707) 575-1468',
      'rating': 4.7,
      'certified': true,
      'features': ['Speech therapy', 'OT services', 'Social groups'],
      'description': 'Multi-disciplinary therapy center specializing in autism intervention.',
      'icon': Icons.psychology,
      'color': AppColors.purple,
    },
    {
      'name': 'Children\'s Health Council',
      'type': 'Therapy',
      'address': '650 Clark Way, Palo Alto, CA 94304',
      'phone': '(650) 326-5530',
      'rating': 4.8,
      'certified': true,
      'features': ['Diagnostic services', 'Behavioral therapy', 'Parent education'],
      'description': 'Comprehensive mental health and developmental services for children with autism.',
      'icon': Icons.psychology,
      'color': AppColors.purple,
    },
    
    // Restaurants
    {
      'name': 'Chuck E. Cheese - Sensory Sensitive Sundays',
      'type': 'Restaurant',
      'address': 'Multiple Bay Area Locations',
      'phone': '(408) 371-2515',
      'rating': 4.3,
      'certified': true,
      'features': ['Reduced lights/sounds', 'Early hours', 'Trained staff'],
      'description': 'Monthly sensory-friendly events with reduced stimulation and trained staff.',
      'icon': Icons.restaurant,
      'color': AppColors.success,
    },
  ];

  List<Map<String, dynamic>> get filteredOrganizations {
    var filtered = _organizations;
    
    if (_selectedFilter != 'All') {
      filtered = filtered.where((org) => org['type'] == _selectedFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((org) {
        final name = org['name'].toString().toLowerCase();
        final type = org['type'].toString().toLowerCase();
        final features = (org['features'] as List).join(' ').toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || 
               type.contains(query) || 
               features.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        elevation: 0,
        title: Text(
          'Autism Friendly Organizations',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search organizations...',
                hintStyle: TextStyle(color: AppColors.textGray),
                icon: Icon(Icons.search, color: AppColors.textGray),
              ),
            ),
          ),
          
          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppColors.cyan,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${filteredOrganizations.length} organizations found',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.verified,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Certified Autism-Friendly',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Organizations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredOrganizations.length,
              itemBuilder: (context, index) {
                final org = filteredOrganizations[index];
                
                return GestureDetector(
                  onTap: () => _showOrganizationDetails(context, org),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (org['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            org['icon'] as IconData,
                            color: org['color'] as Color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      org['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  if (org['certified'] as bool)
                                    Icon(
                                      Icons.verified,
                                      size: 18,
                                      color: AppColors.success,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                org['type'],
                                style: TextStyle(
                                  color: org['color'] as Color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppColors.yellow,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${org['rating']}',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      org['address'],
                                      style: TextStyle(
                                        color: AppColors.textGray,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textGray,
                        ),
                      ],
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

  void _showOrganizationDetails(BuildContext context, Map<String, dynamic> org) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: (org['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            org['icon'] as IconData,
                            color: org['color'] as Color,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                org['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (org['color'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      org['type'],
                                      style: TextStyle(
                                        color: org['color'] as Color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (org['certified'] as bool)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 12,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Certified',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.star, size: 18, color: AppColors.yellow),
                        const SizedBox(width: 4),
                        Text(
                          '${org['rating']} Rating',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'About',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      org['description'],
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Autism-Friendly Features',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(org['features'] as List).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    const SizedBox(height: 20),
                    Text(
                      'Contact Information',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on, color: AppColors.cyan),
                      title: Text(org['address']),
                      trailing: IconButton(
                        icon: Icon(Icons.directions, color: AppColors.cyan),
                        onPressed: () {},
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.phone, color: AppColors.cyan),
                      title: Text(org['phone']),
                      trailing: IconButton(
                        icon: Icon(Icons.call, color: AppColors.cyan),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cyan,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cyan,
                              side: BorderSide(color: AppColors.cyan),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}