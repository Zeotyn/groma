from django.http import JsonResponse

from .models import Order


def order_count(request):
    return JsonResponse({"orders": Order.objects.count()})
