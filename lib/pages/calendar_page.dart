import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/course.dart';
import '../services/classes_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch server events AND joined courses in parallel
      final results = await Future.wait([
        ClassesService.getMyClassEvents(),
        ClassesService.getJoinedCourses(),
      ]);
      final serverEvents = results[0] as List<CalendarEvent>;
      final joinedCourses = results[1] as List<Course>;

      // Generate recurring class session events from course schedules
      final scheduleEvents = _generateScheduleEvents(joinedCourses);

      setState(() {
        _allEvents = [...serverEvents, ...scheduleEvents];
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Parse schedule strings like "Sunday 08:00-09:30" and generate
  /// CalendarEvent objects for the next 16 weeks.
  List<CalendarEvent> _generateScheduleEvents(List<Course> courses) {
    final List<CalendarEvent> events = [];
    final now = DateTime.now();
    // Generate from start of current week to 16 weeks out
    final start = now.subtract(Duration(days: now.weekday % 7));
    final end = start.add(const Duration(days: 16 * 7));

    const dayMap = {
      'sunday': DateTime.sunday,    'sun': DateTime.sunday,
      'monday': DateTime.monday,    'mon': DateTime.monday,
      'tuesday': DateTime.tuesday,  'tue': DateTime.tuesday,
      'wednesday': DateTime.wednesday, 'wed': DateTime.wednesday,
      'thursday': DateTime.thursday,'thu': DateTime.thursday,
      'friday': DateTime.friday,    'fri': DateTime.friday,
      'saturday': DateTime.saturday,'sat': DateTime.saturday,
    };

    for (final course in courses) {
      for (final slot in course.schedule) {
        // Expected format: "Sunday 08:00-09:30"
        final parts = slot.trim().split(' ');
        if (parts.length < 2) continue;

        final dayName = parts[0].toLowerCase();
        final targetDay = dayMap[dayName];
        if (targetDay == null) continue;

        final timeParts = parts[1].split('-');
        if (timeParts.length != 2) continue;

        final startParts = timeParts[0].split(':');
        final endParts = timeParts[1].split(':');
        if (startParts.length != 2 || endParts.length != 2) continue;

        final startHour = int.tryParse(startParts[0]) ?? 0;
        final startMin = int.tryParse(startParts[1]) ?? 0;
        final endHour = int.tryParse(endParts[0]) ?? 0;
        final endMin = int.tryParse(endParts[1]) ?? 0;

        // Walk each week and place the event on the right day
        var cursor = start;
        while (cursor.isBefore(end)) {
          if (cursor.weekday == targetDay) {
            final eventStart = DateTime(
              cursor.year, cursor.month, cursor.day, startHour, startMin,
            );
            final eventEnd = DateTime(
              cursor.year, cursor.month, cursor.day, endHour, endMin,
            );
            events.add(CalendarEvent(
              id: 'sched_${course.id}_${cursor.millisecondsSinceEpoch}',
              title: course.name,
              description: '${course.instructor} — ${slot}',
              location: course.location,
              startTime: eventStart,
              endTime: eventEnd,
              type: EventType.classSession,
              addedBy: course.instructor,
              classId: course.id,
              category: course.category,
            ));
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      }
    }
    return events;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  Future<void> _showAddEventDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddEventDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
        onEventAdded: () {
          _loadEvents();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryMaroon = Color(0xFF8A1538);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: primaryMaroon,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddEventDialog,
            tooltip: 'Add Event',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryMaroon),
              ),
            )
          : Column(
              children: [
                // Calendar Widget
                TableCalendar<CalendarEvent>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    selectedDecoration: BoxDecoration(
                      color: primaryMaroon,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: primaryMaroon.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: primaryMaroon,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                const SizedBox(height: 8.0),

                // Events List
                Expanded(
                  child: ValueListenableBuilder<List<CalendarEvent>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      return Column(
                        children: [
                          // Date Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey[50],
                            child: Row(
                              children: [
                                Icon(Icons.event, color: primaryMaroon),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDay != null
                                      ? '${_getMonthName(_selectedDay!.month)} ${_selectedDay!.day}, ${_selectedDay!.year}'
                                      : 'Select a date',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (value.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryMaroon,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${value.length} event${value.length != 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Events List
                          Expanded(
                            child: value.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_available,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No events for this day',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: _showAddEventDialog,
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Event'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: value.length,
                                    itemBuilder: (context, index) {
                                      final event = value[index];
                                      return _buildEventCard(event);
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    const Color primaryMaroon = Color(0xFF8A1538);
    
    Color eventColor;
    IconData eventIcon;
    
    switch (event.type) {
      case EventType.classSession:
        eventColor = primaryMaroon;
        eventIcon = Icons.school;
        break;
      case EventType.exam:
        eventColor = Colors.red;
        eventIcon = Icons.quiz;
        break;
      case EventType.assignment:
        eventColor = Colors.orange;
        eventIcon = Icons.assignment;
        break;
      case EventType.studyGroup:
        eventColor = Colors.blue;
        eventIcon = Icons.group_work;
        break;
      case EventType.campusEvent:
        eventColor = Colors.green;
        eventIcon = Icons.event;
        break;
      case EventType.socialEvent:
        eventColor = Colors.purple;
        eventIcon = Icons.celebration;
        break;
      default:
        eventColor = Colors.grey;
        eventIcon = Icons.event_note;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: eventColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    eventIcon,
                    color: eventColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.attendeeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendeeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                event.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            ],
            
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                // Event Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEventTypeLabel(event.type),
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // RSVP Button
                if (event.isPublic && event.type != EventType.classSession)
                  TextButton.icon(
                    onPressed: () async {
                      await ClassesService.toggleEventAttendance(event.id);
                      _loadEvents();
                    },
                    icon: Icon(
                      event.isGoing ? Icons.check_circle : Icons.add_circle_outline,
                      size: 16,
                    ),
                    label: Text(
                      event.isGoing ? 'Going' : 'Join',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.classSession:
        return 'Class';
      case EventType.exam:
        return 'Exam';
      case EventType.assignment:
        return 'Assignment';
      case EventType.studyGroup:
        return 'Study Group';
      case EventType.campusEvent:
        return 'Campus Event';
      case EventType.socialEvent:
        return 'Social';
      default:
        return 'Event';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

class _AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onEventAdded;

  const _AddEventDialog({
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  EventType _selectedType = EventType.socialEvent;
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final success = await ClassesService.addEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        eventType: CalendarEvent.eventTypeToString(_selectedType),
        category: 'social',
      );

      if (success) {
        widget.onEventAdded();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add event. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add event. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryMaroon = Color(0xFF8A1538);

    return AlertDialog(
      title: const Text('Add Community Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'e.g., Study Group, Gaming Night',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What\'s this event about?',
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Where will it happen?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<EventType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Event Type'),
                items: [
                  EventType.socialEvent,
                  EventType.studyGroup,
                  EventType.campusEvent,
                  EventType.other,
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getEventTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        child: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Time'),
                        child: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryMaroon,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Event'),
        ),
      ],
    );
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.socialEvent:
        return 'Social Event';
      case EventType.studyGroup:
        return 'Study Group';
      case EventType.campusEvent:
        return 'Campus Event';
      case EventType.other:
        return 'Other';
      default:
        return 'Event';
    }
  }
}
