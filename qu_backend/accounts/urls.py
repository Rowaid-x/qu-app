from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    StudentSignupView,
    StudentLoginView,
    BusDriverLoginView,
    AdminLoginView,
    LogoutView,
    MeView,
)

urlpatterns = [
    # Signup
    path('signup/', StudentSignupView.as_view(), name='signup'),

    # Login (one endpoint per user type – matches Flutter app logic)
    path('login/student/', StudentLoginView.as_view(), name='login-student'),
    path('login/bus-driver/', BusDriverLoginView.as_view(), name='login-bus-driver'),
    path('login/admin/', AdminLoginView.as_view(), name='login-admin'),

    # Logout
    path('logout/', LogoutView.as_view(), name='logout'),

    # Token refresh (client sends expired access + valid refresh → gets new pair)
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # Current user profile
    path('me/', MeView.as_view(), name='me'),
]
