from django.contrib import admin
from .models import Course, Enrollment


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'instructor', 'class_type', 'category', 'max_students', 'created_at')
    list_filter = ('class_type', 'category')
    search_fields = ('name', 'instructor', 'description')


@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'course', 'is_favorite', 'joined_at')
    list_filter = ('is_favorite',)
