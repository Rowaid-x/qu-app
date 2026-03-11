import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='BusRoute',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=200)),
                ('description', models.TextField(blank=True, default='')),
                ('stops', models.JSONField(default=list, help_text='Ordered list of stops: [{"name":"...","lat":25.37,"lng":51.49}, ...]')),
                ('is_active', models.BooleanField(default=True)),
            ],
        ),
        migrations.CreateModel(
            name='Bus',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('bus_number', models.CharField(max_length=20, unique=True)),
                ('capacity', models.IntegerField(default=40)),
                ('is_active', models.BooleanField(default=False, help_text='True when a trip is in progress')),
                ('driver', models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='assigned_bus', to=settings.AUTH_USER_MODEL)),
                ('route', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='buses', to='bus.busroute')),
            ],
        ),
        migrations.CreateModel(
            name='BusLocationUpdate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('latitude', models.FloatField()),
                ('longitude', models.FloatField()),
                ('current_stop', models.CharField(blank=True, default='', max_length=200)),
                ('next_stop', models.CharField(blank=True, default='', max_length=200)),
                ('status', models.CharField(choices=[('on_route', 'On Route'), ('at_stop', 'At Stop'), ('waiting', 'Waiting'), ('off_duty', 'Off Duty'), ('completed', 'Completed')], default='on_route', max_length=20)),
                ('occupancy', models.CharField(choices=[('empty', 'Empty'), ('low', 'Low'), ('medium', 'Medium'), ('high', 'High'), ('full', 'Full')], default='empty', max_length=20)),
                ('timestamp', models.DateTimeField(auto_now_add=True)),
                ('bus', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='location_updates', to='bus.bus')),
                ('driver', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='bus_updates', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-timestamp'],
            },
        ),
    ]
