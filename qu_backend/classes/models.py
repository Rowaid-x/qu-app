from django.conf import settings
from django.db import models


class Course(models.Model):
    CLASS_TYPE_CHOICES = [
        ('official', 'Official'),
        ('student_created', 'Student Created'),
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
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default='')
    instructor = models.CharField(max_length=200)
    location = models.CharField(max_length=200)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_courses',
        null=True, blank=True,
    )
    class_type = models.CharField(max_length=20, choices=CLASS_TYPE_CHOICES, default='official')
    schedule = models.JSONField(default=list)
    max_students = models.IntegerField(default=60)
    credits = models.IntegerField(default=3)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='academic')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class Enrollment(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='enrollments',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='enrollments',
    )
    is_favorite = models.BooleanField(default=False)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'course')

    def __str__(self):
        return f"{self.user.email} → {self.course.name}"
