from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from authentication.models import CustomUser, TokenBlacklist, PasswordResetToken

@admin.register(CustomUser)
class CustomUserAdmin(BaseUserAdmin):
    list_display = ('email', 'full_name', 'phone_number', 'is_active', 'is_email_verified', 'is_phone_verified', 'created_at')
    list_filter = ('is_active', 'is_email_verified', 'is_phone_verified', 'created_at')
    search_fields = ('email', 'full_name', 'phone_number')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Personal Info', {'fields': ('id', 'email', 'full_name', 'phone_number', 'username')}),
        ('Verification', {'fields': ('is_email_verified', 'is_phone_verified')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Activity', {'fields': ('last_login', 'last_login_ip', 'created_at', 'updated_at')}),
    )
    readonly_fields = ('id', 'created_at', 'updated_at', 'last_login')


@admin.register(TokenBlacklist)
class TokenBlacklistAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'blacklisted_at', 'expires_at')
    list_filter = ('blacklisted_at', 'expires_at')
    search_fields = ('user__email', 'token')
    ordering = ('-blacklisted_at',)
    readonly_fields = ('token', 'blacklisted_at')


@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'created_at', 'expires_at', 'is_used')
    list_filter = ('created_at', 'expires_at', 'is_used')
    search_fields = ('user__email', 'token')
    ordering = ('-created_at',)
readonly_fields = ('token', 'created_at')
