from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import BusRoute, Bus, BusLocationUpdate
from .serializers import (
    BusRouteSerializer, BusSerializer,
    BusLocationUpdateSerializer, UpdateLocationSerializer,
)


class BusRouteListView(APIView):
    """GET /api/bus/routes/ — list all active routes"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        routes = BusRoute.objects.filter(is_active=True)
        serializer = BusRouteSerializer(routes, many=True)
        return Response(serializer.data)


class ActiveBusesView(APIView):
    """GET /api/bus/active/ — all active buses with latest location"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        buses = Bus.objects.filter(is_active=True).select_related('route', 'driver')
        serializer = BusSerializer(buses, many=True)
        return Response(serializer.data)


class BusDetailView(APIView):
    """GET /api/bus/<id>/ — single bus detail"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            bus = Bus.objects.select_related('route', 'driver').get(pk=pk)
        except Bus.DoesNotExist:
            return Response({'error': 'Bus not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = BusSerializer(bus)
        return Response(serializer.data)


class MyBusView(APIView):
    """GET /api/bus/my-bus/ — driver's assigned bus"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.user_type != 'bus_driver':
            return Response(
                {'error': 'Only bus drivers can access this endpoint.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            bus = Bus.objects.select_related('route').get(driver=request.user)
        except Bus.DoesNotExist:
            return Response(
                {'error': 'No bus assigned to you. Contact admin.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        serializer = BusSerializer(bus)
        return Response(serializer.data)


class StartTripView(APIView):
    """POST /api/bus/start-trip/ — driver starts a trip"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.user_type != 'bus_driver':
            return Response(
                {'error': 'Only bus drivers can start trips.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            bus = Bus.objects.get(driver=request.user)
        except Bus.DoesNotExist:
            return Response(
                {'error': 'No bus assigned to you.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if bus.is_active:
            return Response(
                {'error': 'Trip already in progress.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        bus.is_active = True
        bus.save()
        return Response({'message': 'Trip started.', 'bus': BusSerializer(bus).data})


class EndTripView(APIView):
    """POST /api/bus/end-trip/ — driver ends current trip"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.user_type != 'bus_driver':
            return Response(
                {'error': 'Only bus drivers can end trips.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            bus = Bus.objects.get(driver=request.user)
        except Bus.DoesNotExist:
            return Response(
                {'error': 'No bus assigned to you.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not bus.is_active:
            return Response(
                {'error': 'No active trip to end.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        bus.is_active = False
        bus.save()

        # Mark the last update as completed
        last = bus.location_updates.first()
        if last:
            last.status = 'completed'
            last.save()

        return Response({'message': 'Trip ended.', 'bus': BusSerializer(bus).data})


class UpdateLocationView(APIView):
    """POST /api/bus/update-location/ — driver posts GPS + status"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.user_type != 'bus_driver':
            return Response(
                {'error': 'Only bus drivers can update location.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            bus = Bus.objects.get(driver=request.user)
        except Bus.DoesNotExist:
            return Response(
                {'error': 'No bus assigned to you.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not bus.is_active:
            return Response(
                {'error': 'Start a trip before updating location.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = UpdateLocationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        update = BusLocationUpdate.objects.create(
            bus=bus,
            driver=request.user,
            **serializer.validated_data,
        )
        return Response(
            BusLocationUpdateSerializer(update).data,
            status=status.HTTP_201_CREATED,
        )
