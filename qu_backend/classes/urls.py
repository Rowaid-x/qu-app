from django.urls import path
from .views import (
    CourseListCreateView,
    CourseDetailView,
    JoinCourseView,
    LeaveCourseView,
    ToggleFavoriteView,
    JoinedCoursesView,
    FavoriteCoursesView,
)

urlpatterns = [
    path('', CourseListCreateView.as_view(), name='course-list-create'),
    path('joined/', JoinedCoursesView.as_view(), name='joined-courses'),
    path('favorites/', FavoriteCoursesView.as_view(), name='favorite-courses'),
    path('<str:pk>/', CourseDetailView.as_view(), name='course-detail'),
    path('<str:pk>/join/', JoinCourseView.as_view(), name='join-course'),
    path('<str:pk>/leave/', LeaveCourseView.as_view(), name='leave-course'),
    path('<str:pk>/favorite/', ToggleFavoriteView.as_view(), name='toggle-favorite'),
]
