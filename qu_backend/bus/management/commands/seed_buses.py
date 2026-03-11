"""
Management command to create sample bus routes and buses.
Usage:  python manage.py seed_buses

Creates 3 QU campus bus routes with real GPS coordinates and 3 buses.
Assigns the seeded bus driver user to BUS-01 if it exists.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from bus.models import BusRoute, Bus

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed the database with sample bus routes and buses'

    def handle(self, *args, **options):
        # ── Routes with real QU campus GPS coordinates ──
        routes_data = [
            {
                'name': 'Route A — Main Gate Loop',
                'description': 'Circular route connecting the Main Gate to central campus buildings.',
                'stops': [
                    {'name': 'Main Gate', 'lat': 25.3755, 'lng': 51.4906},
                    {'name': 'College of Engineering', 'lat': 25.3762, 'lng': 51.4880},
                    {'name': 'Central Library', 'lat': 25.3770, 'lng': 51.4865},
                    {'name': 'Student Center', 'lat': 25.3778, 'lng': 51.4850},
                    {'name': 'College of Science', 'lat': 25.3785, 'lng': 51.4838},
                    {'name': 'Main Gate', 'lat': 25.3755, 'lng': 51.4906},
                ],
            },
            {
                'name': 'Route B — Residence Loop',
                'description': 'Connects student residences to the academic core.',
                'stops': [
                    {'name': 'Male Residence', 'lat': 25.3740, 'lng': 51.4920},
                    {'name': 'Female Residence', 'lat': 25.3735, 'lng': 51.4895},
                    {'name': 'Sports Complex', 'lat': 25.3750, 'lng': 51.4870},
                    {'name': 'Student Center', 'lat': 25.3778, 'lng': 51.4850},
                    {'name': 'Central Library', 'lat': 25.3770, 'lng': 51.4865},
                    {'name': 'Male Residence', 'lat': 25.3740, 'lng': 51.4920},
                ],
            },
            {
                'name': 'Route C — Express North',
                'description': 'Express service from the North Gate to key buildings.',
                'stops': [
                    {'name': 'North Gate', 'lat': 25.3800, 'lng': 51.4910},
                    {'name': 'College of Business', 'lat': 25.3790, 'lng': 51.4885},
                    {'name': 'College of Arts', 'lat': 25.3775, 'lng': 51.4875},
                    {'name': 'Student Center', 'lat': 25.3778, 'lng': 51.4850},
                    {'name': 'North Gate', 'lat': 25.3800, 'lng': 51.4910},
                ],
            },
        ]

        created_routes = []
        for data in routes_data:
            route, created = BusRoute.objects.update_or_create(
                name=data['name'],
                defaults=data,
            )
            created_routes.append(route)
            tag = 'CREATED' if created else 'EXISTS'
            self.stdout.write(self.style.SUCCESS(f'  {tag}  Route: {route.name}'))

        # ── Buses ──
        buses_data = [
            {'bus_number': 'BUS-01', 'route': created_routes[0], 'capacity': 40},
            {'bus_number': 'BUS-02', 'route': created_routes[1], 'capacity': 35},
            {'bus_number': 'BUS-03', 'route': created_routes[2], 'capacity': 30},
        ]

        for data in buses_data:
            bus, created = Bus.objects.update_or_create(
                bus_number=data['bus_number'],
                defaults={
                    'route': data['route'],
                    'capacity': data['capacity'],
                },
            )
            tag = 'CREATED' if created else 'EXISTS'
            self.stdout.write(self.style.SUCCESS(f'  {tag}  Bus: {bus.bus_number}'))

        # Assign the seeded bus driver to BUS-01
        try:
            driver = User.objects.get(email='driver@gmail.com')
            bus01 = Bus.objects.get(bus_number='BUS-01')
            if bus01.driver != driver:
                bus01.driver = driver
                bus01.save()
                self.stdout.write(self.style.SUCCESS(f'  ASSIGNED  driver@gmail.com → BUS-01'))
            else:
                self.stdout.write(self.style.SUCCESS(f'  ALREADY   driver@gmail.com → BUS-01'))
        except (User.DoesNotExist, Bus.DoesNotExist):
            self.stdout.write(self.style.WARNING(
                '  SKIP  Could not assign driver (run seed_users first)'
            ))

        self.stdout.write(self.style.SUCCESS('\nDone! Bus routes and buses are ready.'))
