from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate, get_user_model

from .serializers import (
    UserSerializer,
    StudentSignupSerializer,
    StudentLoginSerializer,
    BusDriverLoginSerializer,
    AdminLoginSerializer,
)

User = get_user_model()


def _get_tokens_for_user(user):
    """Helper – generate JWT access + refresh pair for a user."""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


# ─────────────────────────────────────────────
# SIGNUP  (students only)
# ─────────────────────────────────────────────
class StudentSignupView(APIView):
    """
    POST /api/auth/signup/
    Body: { email, password, confirm_password }
    Creates a student account and returns JWT tokens.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = StudentSignupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        tokens = _get_tokens_for_user(user)
        return Response({
            'message': 'Account created successfully.',
            'user': UserSerializer(user).data,
            'tokens': tokens,
        }, status=status.HTTP_201_CREATED)


# ─────────────────────────────────────────────
# LOGIN – Student
# ─────────────────────────────────────────────
class StudentLoginView(APIView):
    """
    POST /api/auth/login/student/
    Body: { email, password }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = StudentLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, email=email, password=password)
        if user is None:
            return Response(
                {'error': 'Invalid email or password.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if user.user_type != User.UserType.STUDENT:
            return Response(
                {'error': 'This account is not a student account.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        tokens = _get_tokens_for_user(user)
        return Response({
            'message': 'Login successful.',
            'user': UserSerializer(user).data,
            'tokens': tokens,
        })


# ─────────────────────────────────────────────
# LOGIN – Bus Driver
# ─────────────────────────────────────────────
class BusDriverLoginView(APIView):
    """
    POST /api/auth/login/bus-driver/
    Body: { email, password }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = BusDriverLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, email=email, password=password)
        if user is None:
            return Response(
                {'error': 'Invalid email or password.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if user.user_type != User.UserType.BUS_DRIVER:
            return Response(
                {'error': 'This account is not a bus driver account.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        tokens = _get_tokens_for_user(user)
        return Response({
            'message': 'Login successful.',
            'user': UserSerializer(user).data,
            'tokens': tokens,
        })


# ─────────────────────────────────────────────
# LOGIN – Admin
# ─────────────────────────────────────────────
class AdminLoginView(APIView):
    """
    POST /api/auth/login/admin/
    Body: { username, password }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = AdminLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        username = serializer.validated_data['username']
        password = serializer.validated_data['password']

        # Admin logs in with username; look up the email first
        try:
            user_obj = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response(
                {'error': 'Invalid admin credentials.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        user = authenticate(request, email=user_obj.email, password=password)
        if user is None:
            return Response(
                {'error': 'Invalid admin credentials.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if user.user_type != User.UserType.ADMIN:
            return Response(
                {'error': 'This account is not an admin account.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        tokens = _get_tokens_for_user(user)
        return Response({
            'message': 'Login successful.',
            'user': UserSerializer(user).data,
            'tokens': tokens,
        })


# ─────────────────────────────────────────────
# LOGOUT  (blacklist the refresh token)
# ─────────────────────────────────────────────
class LogoutView(APIView):
    """
    POST /api/auth/logout/
    Body: { refresh }
    Blacklists the refresh token so it can't be reused.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if not refresh_token:
                return Response(
                    {'error': 'Refresh token is required.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully.'})
        except Exception:
            return Response(
                {'error': 'Invalid or expired token.'},
                status=status.HTTP_400_BAD_REQUEST,
            )


# ─────────────────────────────────────────────
# ME  (get current user profile)
# ─────────────────────────────────────────────
class MeView(APIView):
    """
    GET /api/auth/me/
    Returns the profile of the currently authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({
            'user': UserSerializer(request.user).data,
        })
