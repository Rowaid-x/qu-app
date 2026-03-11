import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/classes_service.dart';
import 'create_class_page.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Course> _allCourses = [];
  List<Course> _joinedCourses = [];
  List<Course> _favoriteCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  EventCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allCourses = await ClassesService.getAllCourses();
      final joinedCourses = await ClassesService.getJoinedCourses();
      final favoriteCourses = await ClassesService.getFavoriteCourses();

      setState(() {
        _allCourses = allCourses;
        _joinedCourses = joinedCourses;
        _favoriteCourses = favoriteCourses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Course> _getFilteredCourses(List<Course> courses) {
    var filtered = courses;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) =>
        course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        course.instructor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        course.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((course) => course.category == _selectedCategory).toList();
    }

    return filtered;
  }

  Future<void> _joinClass(Course course) async {
    final success = await ClassesService.joinClass(course.id);
    if (success) {
      _loadCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${course.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _leaveClass(Course course) async {
    final success = await ClassesService.leaveClass(course.id);
    if (success) {
      _loadCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${course.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Course course) async {
    final success = await ClassesService.toggleFavorite(course.id);
    if (success) {
      _loadCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryMaroon = Color(0xFF8A1538);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: primaryMaroon,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateClassPage()),
              );
              if (result == true) {
                _loadCourses();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Classes', icon: Icon(Icons.school)),
            Tab(text: 'My Classes', icon: Icon(Icons.bookmark)),
            Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search classes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All', null),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Academic', EventCategory.academic),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Creative', EventCategory.creative),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Sports', EventCategory.sports),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Social', EventCategory.social),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Career', EventCategory.career),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryMaroon),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClassesList(_getFilteredCourses(_allCourses)),
                      _buildClassesList(_getFilteredCourses(_joinedCourses)),
                      _buildClassesList(_getFilteredCourses(_favoriteCourses)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, EventCategory? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      selectedColor: const Color(0xFF8A1538).withOpacity(0.2),
      checkmarkColor: const Color(0xFF8A1538),
    );
  }

  Widget _buildClassesList(List<Course> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No classes found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    const Color primaryMaroon = Color(0xFF8A1538);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: course.type == ClassType.official 
                        ? primaryMaroon.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    course.type == ClassType.official 
                        ? Icons.school 
                        : Icons.group,
                    color: course.type == ClassType.official 
                        ? primaryMaroon 
                        : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              course.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: course.isFavorite ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleFavorite(course),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            course.instructor,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              course.description,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Course Details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetailChip(Icons.location_on, course.location),
                _buildDetailChip(Icons.access_time, course.schedule.join(', ')),
                _buildDetailChip(Icons.people, '${course.enrolledCount}/${course.maxStudents}'),
                if (course.credits > 0)
                  _buildDetailChip(Icons.star, '${course.credits} credits'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                // Class Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: course.type == ClassType.official 
                        ? primaryMaroon.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course.type == ClassType.official ? 'Official' : 'Student',
                    style: TextStyle(
                      color: course.type == ClassType.official 
                          ? primaryMaroon 
                          : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Join/Leave Button
                ElevatedButton.icon(
                  onPressed: course.isJoined 
                      ? () => _leaveClass(course)
                      : course.enrolledCount >= course.maxStudents
                          ? null
                          : () => _joinClass(course),
                  icon: Icon(
                    course.isJoined ? Icons.exit_to_app : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    course.isJoined 
                        ? 'Leave' 
                        : course.enrolledCount >= course.maxStudents
                            ? 'Full'
                            : 'Join',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: course.isJoined 
                        ? Colors.orange 
                        : course.enrolledCount >= course.maxStudents
                            ? Colors.grey
                            : primaryMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            
            // Expanded info for joined classes
            if (course.isJoined) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'You\'re enrolled in this class',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to class materials
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Materials feature coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.folder, size: 16),
                            label: const Text('Materials'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to class chat
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chat feature coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Chat'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to classmates
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Classmates feature coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.people, size: 16),
                            label: const Text('People'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}


