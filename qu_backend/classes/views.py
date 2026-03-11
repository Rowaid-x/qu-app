from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count, Q

from .models import Course, Enrollment
from .serializers import CourseSerializer, CourseCreateSerializer


class CourseListCreateView(APIView):
    """
    GET  /api/classes/          — list all courses (search, filter by category)
    POST /api/classes/          — create a student class
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        queryset = Course.objects.annotate(enrolled_count=Count('enrollments'))

        # Search
        search = request.query_params.get('search', '')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(instructor__icontains=search) |
                Q(description__icontains=search)
            )

        # Filter by category
        category = request.query_params.get('category', '')
        if category:
            queryset = queryset.filter(category=category)

        serializer = CourseSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        serializer = CourseCreateSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        course = serializer.save()
        return Response(
            CourseSerializer(course, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class CourseDetailView(APIView):
    """
    GET /api/classes/{id}/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            course = Course.objects.annotate(enrolled_count=Count('enrollments')).get(pk=pk)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = CourseSerializer(course, context={'request': request})
        return Response(serializer.data)


class JoinCourseView(APIView):
    """
    POST /api/classes/{id}/join/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            course = Course.objects.get(pk=pk)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)

        if course.enrollments.count() >= course.max_students:
            return Response({'error': 'Course is full.'}, status=status.HTTP_400_BAD_REQUEST)

        _, created = Enrollment.objects.get_or_create(user=request.user, course=course)
        if not created:
            return Response({'error': 'Already joined.'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({'message': f'Joined {course.name}.'})


class LeaveCourseView(APIView):
    """
    POST /api/classes/{id}/leave/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            enrollment = Enrollment.objects.get(user=request.user, course_id=pk)
        except Enrollment.DoesNotExist:
            return Response({'error': 'Not enrolled.'}, status=status.HTTP_400_BAD_REQUEST)

        enrollment.delete()
        return Response({'message': 'Left the course.'})


class ToggleFavoriteView(APIView):
    """
    POST /api/classes/{id}/favorite/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            enrollment = Enrollment.objects.get(user=request.user, course_id=pk)
        except Enrollment.DoesNotExist:
            return Response(
                {'error': 'You must join the class before favoriting it.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        enrollment.is_favorite = not enrollment.is_favorite
        enrollment.save()
        return Response({
            'message': 'Favorite toggled.',
            'is_favorite': enrollment.is_favorite,
        })


class JoinedCoursesView(APIView):
    """
    GET /api/classes/joined/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        course_ids = Enrollment.objects.filter(user=request.user).values_list('course_id', flat=True)
        courses = Course.objects.filter(pk__in=course_ids).annotate(enrolled_count=Count('enrollments'))
        serializer = CourseSerializer(courses, many=True, context={'request': request})
        return Response(serializer.data)


class FavoriteCoursesView(APIView):
    """
    GET /api/classes/favorites/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        course_ids = Enrollment.objects.filter(
            user=request.user, is_favorite=True
        ).values_list('course_id', flat=True)
        courses = Course.objects.filter(pk__in=course_ids).annotate(enrolled_count=Count('enrollments'))
        serializer = CourseSerializer(courses, many=True, context={'request': request})
        return Response(serializer.data)
