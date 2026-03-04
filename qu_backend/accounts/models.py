from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Custom User model for QU Community.
    Extends Django's built-in AbstractUser so we keep all default auth
    functionality (password hashing, permissions, etc.) while adding
    our own fields.
    """

    class UserType(models.TextChoices):
        STUDENT = 'student', 'Student'
        BUS_DRIVER = 'bus_driver', 'Bus Driver'
        ADMIN = 'admin', 'Admin'

    # We use email as the login identifier instead of username
    email = models.EmailField(unique=True)
    user_type = models.CharField(
        max_length=20,
        choices=UserType.choices,
        default=UserType.STUDENT,
    )
    institution = models.CharField(max_length=100, default='Qatar University')

    # Use email to log in instead of username
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']  # username still required by createsuperuser

    def __str__(self):
        return f"{self.email} ({self.get_user_type_display()})"

    @property
    def is_student(self):
        return self.user_type == self.UserType.STUDENT

    @property
    def is_bus_driver(self):
        return self.user_type == self.UserType.BUS_DRIVER

    @property
    def is_admin_user(self):
        return self.user_type == self.UserType.ADMIN
