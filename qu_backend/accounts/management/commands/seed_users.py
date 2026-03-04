"""
Management command to create test users for development.
Usage:  python manage.py seed_users

Creates:
  1. Admin user     – admin / 123
  2. Bus driver     – driver@gmail.com / 123456
  3. Student        – student@qu.edu.qa / 123456
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed the database with test users (admin, bus driver, student)'

    def handle(self, *args, **options):
        users = [
            {
                'email': 'admin@qu.edu.qa',
                'username': 'admin',
                'password': '123',
                'user_type': User.UserType.ADMIN,
                'is_staff': True,
                'is_superuser': True,
            },
            {
                'email': 'driver@gmail.com',
                'username': 'driver',
                'password': '123456',
                'user_type': User.UserType.BUS_DRIVER,
            },
            {
                'email': 'student@qu.edu.qa',
                'username': 'student',
                'password': '123456',
                'user_type': User.UserType.STUDENT,
            },
        ]

        for u in users:
            email = u.pop('email')
            username = u.pop('username')
            password = u.pop('password')

            if User.objects.filter(email=email).exists():
                self.stdout.write(self.style.WARNING(
                    f'  SKIP  {email} (already exists)'
                ))
                continue

            user = User.objects.create_user(
                email=email,
                username=username,
                password=password,
                **u,
            )
            self.stdout.write(self.style.SUCCESS(
                f'  OK    {user.email}  (type={user.user_type})'
            ))

        self.stdout.write(self.style.SUCCESS('\nDone! Test users are ready.'))
