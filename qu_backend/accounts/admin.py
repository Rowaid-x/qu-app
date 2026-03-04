from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('email', 'username', 'user_type', 'is_active', 'date_joined')
    list_filter = ('user_type', 'is_active')
    search_fields = ('email', 'username')
    ordering = ('-date_joined',)

    # Add user_type to the fieldsets so it appears in the admin form
    fieldsets = BaseUserAdmin.fieldsets + (
        ('QU Community', {'fields': ('user_type', 'institution')}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('QU Community', {'fields': ('email', 'user_type', 'institution')}),
    )
