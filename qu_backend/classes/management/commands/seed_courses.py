"""
Management command to create sample courses and events.
Usage:  python manage.py seed_courses
"""
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from classes.models import Course
from events.models import CalendarEvent


class Command(BaseCommand):
    help = 'Seed the database with sample courses and calendar events'

    def handle(self, *args, **options):
        now = timezone.now()

        # ── Sample Courses ──
        courses_data = [
            {
                'id': 'cmps251',
                'name': 'Data Structures',
                'description': 'Introduction to data structures and algorithms including arrays, linked lists, stacks, queues, trees, and graphs.',
                'instructor': 'Dr. Ahmed Hassan',
                'location': 'Building B, Room 101',
                'class_type': 'official',
                'schedule': ['Sun 10:00-11:30', 'Tue 10:00-11:30', 'Thu 10:00-11:30'],
                'max_students': 60,
                'credits': 3,
                'category': 'academic',
            },
            {
                'id': 'math101',
                'name': 'Calculus I',
                'description': 'Differential and integral calculus of functions of one variable.',
                'instructor': 'Dr. Fatima Al-Zahra',
                'location': 'Building A, Room 205',
                'class_type': 'official',
                'schedule': ['Mon 14:00-15:30', 'Wed 14:00-15:30'],
                'max_students': 80,
                'credits': 4,
                'category': 'academic',
            },
            {
                'id': 'engl110',
                'name': 'Academic Writing',
                'description': 'Development of academic writing skills including research, citation, and argumentation.',
                'instructor': 'Prof. John Smith',
                'location': 'Building C, Room 301',
                'class_type': 'official',
                'schedule': ['Tue 16:00-17:30', 'Thu 16:00-17:30'],
                'max_students': 25,
                'credits': 3,
                'category': 'academic',
            },
            {
                'id': 'phys201',
                'name': 'General Physics',
                'description': 'Mechanics, thermodynamics, and wave motion with laboratory component.',
                'instructor': 'Dr. Omar Khalil',
                'location': 'Physics Lab, Room 150',
                'class_type': 'official',
                'schedule': ['Mon 10:00-12:00', 'Wed 10:00-12:00'],
                'max_students': 40,
                'credits': 4,
                'category': 'academic',
            },
            {
                'id': 'js_study',
                'name': 'JavaScript Study Group',
                'description': 'Weekly study sessions covering modern JavaScript, ES6+, and web development frameworks.',
                'instructor': 'Sarah Al-Mahmoud',
                'location': 'Library, Study Room 201',
                'class_type': 'student_created',
                'schedule': ['Wed 16:00-18:00'],
                'max_students': 20,
                'credits': 0,
                'category': 'academic',
            },
            {
                'id': 'arabic_tutor',
                'name': 'Arabic Tutoring Sessions',
                'description': 'Help with Arabic grammar, literature, and conversation for international students.',
                'instructor': 'Mohammed Al-Rashid',
                'location': 'Student Center, Room 105',
                'class_type': 'student_created',
                'schedule': ['Sat 14:00-16:00', 'Sun 14:00-16:00'],
                'max_students': 15,
                'credits': 0,
                'category': 'academic',
            },
            {
                'id': 'photo_workshop',
                'name': 'Photography Workshop',
                'description': 'Learn digital photography techniques, composition, and photo editing.',
                'instructor': 'Layla Al-Thani',
                'location': 'Art Building, Studio 3',
                'class_type': 'student_created',
                'schedule': ['Fri 15:00-17:00'],
                'max_students': 12,
                'credits': 0,
                'category': 'creative',
            },
            {
                'id': 'fitness_boot',
                'name': 'Fitness Bootcamp',
                'description': 'High-intensity workout sessions to build strength, endurance, and flexibility.',
                'instructor': 'Ahmed Al-Kuwari',
                'location': 'Sports Complex, Gym 2',
                'class_type': 'student_created',
                'schedule': ['Mon 18:00-19:00', 'Thu 18:00-19:00'],
                'max_students': 25,
                'credits': 0,
                'category': 'sports',
            },
        ]

        for data in courses_data:
            obj, created = Course.objects.update_or_create(
                id=data['id'],
                defaults=data,
            )
            status_str = 'CREATED' if created else 'EXISTS'
            self.stdout.write(self.style.SUCCESS(f'  {status_str}  {obj.name}'))

        # ── Sample Events ──
        events_data = [
            {
                'id': 'midterm_cmps251',
                'title': 'CMPS 251 Midterm Exam',
                'description': 'Midterm examination covering chapters 1-5',
                'location': 'Building B, Room 101',
                'start_time': now + timedelta(days=7, hours=10),
                'end_time': now + timedelta(days=7, hours=12),
                'event_type': 'exam',
                'course_id': 'cmps251',
                'category': 'academic',
            },
            {
                'id': 'js_project',
                'title': 'JavaScript Final Project Due',
                'description': 'Submit your final web application project',
                'location': 'Online Submission',
                'start_time': now + timedelta(days=14, hours=23, minutes=59),
                'end_time': now + timedelta(days=14, hours=23, minutes=59),
                'event_type': 'assignment',
                'course_id': 'js_study',
                'category': 'academic',
            },
            {
                'id': 'photo_exhibition',
                'title': 'Photography Exhibition',
                'description': 'Showcase of student photography work from the workshop',
                'location': 'Art Gallery, Main Campus',
                'start_time': now + timedelta(days=21, hours=18),
                'end_time': now + timedelta(days=21, hours=21),
                'event_type': 'campus_event',
                'course_id': 'photo_workshop',
                'category': 'creative',
            },
            {
                'id': 'career_fair_2026',
                'title': 'QU Career Fair 2026',
                'description': 'Annual career fair with employers from across Qatar and the region.',
                'location': 'Student Center, Main Hall',
                'start_time': now + timedelta(days=10, hours=9),
                'end_time': now + timedelta(days=10, hours=16),
                'event_type': 'campus_event',
                'category': 'career',
            },
            {
                'id': 'fitness_competition',
                'title': 'Inter-College Fitness Challenge',
                'description': 'Compete with other colleges in various fitness events.',
                'location': 'Sports Complex',
                'start_time': now + timedelta(days=15, hours=14),
                'end_time': now + timedelta(days=15, hours=18),
                'event_type': 'campus_event',
                'course_id': 'fitness_boot',
                'category': 'sports',
            },
        ]

        for data in events_data:
            # Handle course FK
            course_id = data.pop('course_id', None)
            if course_id:
                try:
                    data['course'] = Course.objects.get(pk=course_id)
                except Course.DoesNotExist:
                    data['course'] = None

            obj, created = CalendarEvent.objects.update_or_create(
                id=data.pop('id') if 'id' in data else data.get('title'),
                defaults=data,
            )
            status_str = 'CREATED' if created else 'EXISTS'
            self.stdout.write(self.style.SUCCESS(f'  {status_str}  {obj.title}'))

        self.stdout.write(self.style.SUCCESS('\nDone! Sample courses and events are ready.'))
