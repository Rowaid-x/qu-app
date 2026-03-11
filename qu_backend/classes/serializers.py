from rest_framework import serializers
from .models import Course, Enrollment


class CourseSerializer(serializers.ModelSerializer):
    enrolled_count = serializers.IntegerField(read_only=True)
    is_joined = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    created_by_email = serializers.CharField(source='created_by.email', read_only=True, default='system')

    class Meta:
        model = Course
        fields = [
            'id', 'name', 'description', 'instructor', 'location',
            'created_by_email', 'class_type', 'schedule', 'max_students',
            'credits', 'category', 'created_at',
            'enrolled_count', 'is_joined', 'is_favorite',
        ]

    def get_is_joined(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.enrollments.filter(user=request.user).exists()
        return False

    def get_is_favorite(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.enrollments.filter(user=request.user, is_favorite=True).exists()
        return False


class CourseCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = [
            'name', 'description', 'instructor', 'location',
            'schedule', 'max_students', 'credits', 'category',
        ]

    def create(self, validated_data):
        user = self.context['request'].user
        course_id = str(int(self.context['request'].META.get('REQUEST_TIME', 0) * 1000)) if hasattr(self.context['request'].META, 'REQUEST_TIME') else str(id(validated_data))
        # Use timestamp-based ID
        import time
        course_id = str(int(time.time() * 1000))
        course = Course.objects.create(
            id=course_id,
            created_by=user,
            class_type='student_created',
            **validated_data,
        )
        # Auto-join the creator
        Enrollment.objects.create(user=user, course=course)
        return course
