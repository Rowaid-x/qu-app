from rest_framework import serializers
from .models import CalendarEvent, EventAttendance


class CalendarEventSerializer(serializers.ModelSerializer):
    attendee_count = serializers.SerializerMethodField()
    is_going = serializers.SerializerMethodField()
    added_by_email = serializers.CharField(source='added_by.email', read_only=True, default='system')
    course_id = serializers.CharField(source='course.id', read_only=True, default=None)

    class Meta:
        model = CalendarEvent
        fields = [
            'id', 'title', 'description', 'location',
            'start_time', 'end_time', 'event_type',
            'added_by_email', 'course_id', 'category',
            'is_public', 'attendee_count', 'is_going',
        ]

    def get_attendee_count(self, obj):
        return obj.attendances.count()

    def get_is_going(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.attendances.filter(user=request.user).exists()
        return False


class CalendarEventCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200)
    description = serializers.CharField(required=False, default='', allow_blank=True)
    location = serializers.CharField(max_length=200, required=False, default='', allow_blank=True)
    start_time = serializers.DateTimeField()
    end_time = serializers.DateTimeField()
    event_type = serializers.ChoiceField(
        choices=CalendarEvent.EVENT_TYPE_CHOICES,
        default='other',
    )
    course_id = serializers.CharField(required=False, default=None, allow_null=True)
    category = serializers.ChoiceField(
        choices=CalendarEvent.CATEGORY_CHOICES,
        default='academic',
    )
    is_public = serializers.BooleanField(default=True)

    def create(self, validated_data):
        import time
        from classes.models import Course

        course_id = validated_data.pop('course_id', None)
        course = None
        if course_id:
            try:
                course = Course.objects.get(pk=course_id)
            except Course.DoesNotExist:
                pass

        event = CalendarEvent.objects.create(
            id=str(int(time.time() * 1000)),
            added_by=self.context['request'].user,
            course=course,
            **validated_data,
        )
        return event
