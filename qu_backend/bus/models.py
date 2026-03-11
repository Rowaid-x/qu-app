from django.conf import settings
from django.db import models


class BusRoute(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default='')
    stops = models.JSONField(default=list, help_text='Ordered list of stops: [{"name":"...","lat":25.37,"lng":51.49}, ...]')
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class Bus(models.Model):
    bus_number = models.CharField(max_length=20, unique=True)
    route = models.ForeignKey(
        BusRoute, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='buses',
    )
    driver = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='assigned_bus',
    )
    capacity = models.IntegerField(default=40)
    is_active = models.BooleanField(default=False, help_text='True when a trip is in progress')

    def __str__(self):
        return f"{self.bus_number} ({self.route or 'No route'})"

    @property
    def latest_location(self):
        return self.location_updates.order_by('-timestamp').first()


class BusLocationUpdate(models.Model):
    STATUS_CHOICES = [
        ('on_route', 'On Route'),
        ('at_stop', 'At Stop'),
        ('waiting', 'Waiting'),
        ('off_duty', 'Off Duty'),
        ('completed', 'Completed'),
    ]

    OCCUPANCY_CHOICES = [
        ('empty', 'Empty'),
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('full', 'Full'),
    ]

    bus = models.ForeignKey(Bus, on_delete=models.CASCADE, related_name='location_updates')
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='bus_updates',
    )
    latitude = models.FloatField()
    longitude = models.FloatField()
    current_stop = models.CharField(max_length=200, blank=True, default='')
    next_stop = models.CharField(max_length=200, blank=True, default='')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='on_route')
    occupancy = models.CharField(max_length=20, choices=OCCUPANCY_CHOICES, default='empty')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.bus.bus_number} @ {self.timestamp:%H:%M:%S}"
