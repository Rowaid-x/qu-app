from rest_framework import serializers
from .models import BusRoute, Bus, BusLocationUpdate


class BusRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusRoute
        fields = ['id', 'name', 'description', 'stops', 'is_active']


class BusLocationUpdateSerializer(serializers.ModelSerializer):
    driver_email = serializers.CharField(source='driver.email', read_only=True)

    class Meta:
        model = BusLocationUpdate
        fields = [
            'id', 'latitude', 'longitude', 'current_stop', 'next_stop',
            'status', 'occupancy', 'timestamp', 'driver_email',
        ]


class BusSerializer(serializers.ModelSerializer):
    route = BusRouteSerializer(read_only=True)
    latest_location = BusLocationUpdateSerializer(read_only=True)
    driver_email = serializers.CharField(source='driver.email', read_only=True, default=None)

    class Meta:
        model = Bus
        fields = [
            'id', 'bus_number', 'route', 'driver_email',
            'capacity', 'is_active', 'latest_location',
        ]


class UpdateLocationSerializer(serializers.Serializer):
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    current_stop = serializers.CharField(required=False, default='', allow_blank=True)
    next_stop = serializers.CharField(required=False, default='', allow_blank=True)
    status = serializers.ChoiceField(
        choices=BusLocationUpdate.STATUS_CHOICES,
        default='on_route',
    )
    occupancy = serializers.ChoiceField(
        choices=BusLocationUpdate.OCCUPANCY_CHOICES,
        default='empty',
    )
