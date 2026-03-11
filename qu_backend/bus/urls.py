from django.urls import path
from .views import (
    BusRouteListView,
    ActiveBusesView,
    BusDetailView,
    MyBusView,
    StartTripView,
    EndTripView,
    UpdateLocationView,
)

urlpatterns = [
    path('routes/', BusRouteListView.as_view(), name='bus-routes'),
    path('active/', ActiveBusesView.as_view(), name='active-buses'),
    path('my-bus/', MyBusView.as_view(), name='my-bus'),
    path('start-trip/', StartTripView.as_view(), name='start-trip'),
    path('end-trip/', EndTripView.as_view(), name='end-trip'),
    path('update-location/', UpdateLocationView.as_view(), name='update-location'),
    path('<int:pk>/', BusDetailView.as_view(), name='bus-detail'),
]
