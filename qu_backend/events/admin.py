from django.contrib import admin
from .models import CalendarEvent, EventAttendance


@admin.register(CalendarEvent)
class CalendarEventAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'event_type', 'start_time', 'end_time', 'category', 'is_public')
    list_filter = ('event_type', 'category', 'is_public')
    search_fields = ('title', 'description')


@admin.register(EventAttendance)
class EventAttendanceAdmin(admin.ModelAdmin):
    list_display = ('user', 'event')
