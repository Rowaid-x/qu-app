from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model

User = get_user_model()


class DashboardView(APIView):
    """
    GET /api/dashboard/
    Returns a summary for the currently logged-in user.
    This is the first thing the Flutter app can call after login to
    populate the home / profile screen.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        data = {
            'user': {
                'id': user.id,
                'email': user.email,
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'user_type': user.user_type,
                'institution': user.institution,
                'date_joined': user.date_joined,
            },
            'stats': {
                'total_users': User.objects.count(),
                'total_students': User.objects.filter(
                    user_type=User.UserType.STUDENT
                ).count(),
                'total_bus_drivers': User.objects.filter(
                    user_type=User.UserType.BUS_DRIVER
                ).count(),
            },
        }
        return Response(data)
