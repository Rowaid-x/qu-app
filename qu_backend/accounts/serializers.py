from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """
    Read-only serializer that returns user profile data.
    Used by the /me/ endpoint and anywhere we need to show user info.
    """

    class Meta:
        model = User
        fields = [
            'id', 'email', 'username', 'first_name', 'last_name',
            'user_type', 'institution', 'date_joined', 'is_active',
        ]
        read_only_fields = fields


class StudentSignupSerializer(serializers.Serializer):
    """
    Handles student registration.
    Enforces: @qu.edu.qa email, password >= 6 chars, passwords must match.
    """
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)
    confirm_password = serializers.CharField(min_length=6, write_only=True)

    def validate_email(self, value):
        value = value.lower().strip()
        if not value.endswith('@qu.edu.qa'):
            raise serializers.ValidationError(
                'Only @qu.edu.qa emails are allowed for students.'
            )
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data

    def create(self, validated_data):
        email = validated_data['email']
        # Derive username from email (part before @)
        username = email.split('@')[0]
        user = User.objects.create_user(
            email=email,
            username=username,
            password=validated_data['password'],
            user_type=User.UserType.STUDENT,
        )
        return user


class StudentLoginSerializer(serializers.Serializer):
    """Login for students – requires @qu.edu.qa email."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate_email(self, value):
        value = value.lower().strip()
        if not value.endswith('@qu.edu.qa'):
            raise serializers.ValidationError(
                'Please use a valid @qu.edu.qa email address.'
            )
        return value


class BusDriverLoginSerializer(serializers.Serializer):
    """Login for bus drivers – any valid email."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class AdminLoginSerializer(serializers.Serializer):
    """Login for admin – uses username + password."""
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)
