from django.conf import settings
from django.db import models


class CalendarEvent(models.Model):
    EVENT_TYPE_CHOICES = [
        ('class_session', 'Class Session'),
        ('assignment', 'Assignment'),
        ('exam', 'Exam'),
        ('study_group', 'Study Group'),
        ('campus_event', 'Campus Event'),
        ('social_event', 'Social Event'),
        ('other', 'Other'),
    ]

    CATEGORY_CHOICES = [
        ('academic', 'Academic'),
        ('social', 'Social'),
        ('sports', 'Sports'),
        ('creative', 'Creative'),
        ('career', 'Career'),
        ('food', 'Food'),
        ('other', 'Other'),
    ]

    id = models.CharField(max_length=100, primary_key=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, default='')
    location = models.CharField(max_length=200, blank=True, default='')
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    event_type = models.CharField(max_length=20, choices=EVENT_TYPE_CHOICES, default='other')
    added_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_events',
        null=True, blank=True,
    )
    course = models.ForeignKey(
        'classes.Course',
        on_delete=models.CASCADE,
        related_name='events',
        null=True, blank=True,
    )
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='academic')
    is_public = models.BooleanField(default=True)

    class Meta:
        ordering = ['start_time']

    def __str__(self):
        return f"{self.title} ({self.start_time:%Y-%m-%d %H:%M})"


class EventAttendance(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='event_attendances',
    )
    event = models.ForeignKey(
        CalendarEvent,
        on_delete=models.CASCADE,
        related_name='attendances',
    )

    class Meta:
        unique_together = ('user', 'event')

    def __str__(self):
        return f"{self.user.email} → {self.event.title}"
