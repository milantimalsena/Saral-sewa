from django.contrib import admin
from .models import User, Document, Application, Notification, Service, ShareChecklist

admin.site.register(User)
admin.site.register(Document)
admin.site.register(Application)
admin.site.register(Notification)
admin.site.register(Service)
admin.site.register(ShareChecklist)
