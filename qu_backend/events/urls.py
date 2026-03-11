from django.urls import path
from .views import (
    EventListCreateView,
    ToggleAttendanceView,
    TodayEventsView,
    MyClassEventsView,
)

urlpatterns = [
    path('', EventListCreateView.as_view(), name='event-list-create'),
    path('today/', TodayEventsView.as_view(), name='today-events'),
    path('my-classes/', MyClassEventsView.as_view(), name='my-class-events'),
    path('<str:pk>/attend/', ToggleAttendanceView.as_view(), name='toggle-attendance'),
]
