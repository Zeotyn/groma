from django.contrib import admin

from .models import Order, Product


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
	list_display = ("name", "price")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
	list_display = ("created_at",)
