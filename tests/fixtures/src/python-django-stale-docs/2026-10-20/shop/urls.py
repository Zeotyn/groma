from django.urls import path

from . import views

urlpatterns = [
	path("orders/count/", views.order_count),
]
