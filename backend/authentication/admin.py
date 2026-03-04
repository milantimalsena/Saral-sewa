from django.contrib import admin
from authentication.models import ClerkUser


@admin.register(ClerkUser)
class ClerkUserAdmin(admin.ModelAdmin):
    list_display = ('email', 'full_name', 'clerk_user_id', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('email', 'full_name', 'clerk_user_id')
    ordering = ('-created_at',)
    readonly_fields = ('id', 'clerk_user_id', 'created_at', 'updated_at')
