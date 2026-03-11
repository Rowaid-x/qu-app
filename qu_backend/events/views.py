from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone

from .models import CalendarEvent, EventAttendance
from .serializers import CalendarEventSerializer, CalendarEventCreateSerializer
from classes.models import Enrollment


class EventListCreateView(APIView):
    """
    GET  /api/events/          — list all events (filter by date, course)
    POST /api/events/          — create an event
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        queryset = CalendarEvent.objects.all()

        # Filter by date (YYYY-MM-DD)
        date = request.query_params.get('date', '')
        if date:
            queryset = queryset.filter(start_time__date=date)

        # Filter by course
        course_id = request.query_params.get('course', '')
        if course_id:
            queryset = queryset.filter(course_id=course_id)

        serializer = CalendarEventSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        serializer = CalendarEventCreateSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        event = serializer.save()
        return Response(
            CalendarEventSerializer(event, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class ToggleAttendanceView(APIView):
    """
    POST /api/events/{id}/attend/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            event = CalendarEvent.objects.get(pk=pk)
        except CalendarEvent.DoesNotExist:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        attendance, created = EventAttendance.objects.get_or_create(
            user=request.user, event=event
        )
        if not created:
            attendance.delete()
            return Response({'message': 'Attendance removed.', 'is_going': False})

        return Response({'message': 'Attending.', 'is_going': True})


class TodayEventsView(APIView):
    """
    GET /api/events/today/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = timezone.localdate()
        events = CalendarEvent.objects.filter(start_time__date=today)
        serializer = CalendarEventSerializer(events, many=True, context={'request': request})
        return Response(serializer.data)


class MyClassEventsView(APIView):
    """
    GET /api/events/my-classes/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        joined_course_ids = Enrollment.objects.filter(
            user=request.user
        ).values_list('course_id', flat=True)
        events = CalendarEvent.objects.filter(course_id__in=joined_course_ids)
        serializer = CalendarEventSerializer(events, many=True, context={'request': request})
        return Response(serializer.data)
