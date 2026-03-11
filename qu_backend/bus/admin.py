from django.contrib import admin
from .models import BusRoute, Bus, BusLocationUpdate


@admin.register(BusRoute)
class BusRouteAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'is_active')
    list_filter = ('is_active',)


@admin.register(Bus)
class BusAdmin(admin.ModelAdmin):
    list_display = ('bus_number', 'route', 'driver', 'capacity', 'is_active')
    list_filter = ('is_active', 'route')


@admin.register(BusLocationUpdate)
class BusLocationUpdateAdmin(admin.ModelAdmin):
    list_display = ('bus', 'status', 'current_stop', 'next_stop', 'occupancy', 'timestamp')
    list_filter = ('status', 'occupancy')
    ordering = ('-timestamp',)
