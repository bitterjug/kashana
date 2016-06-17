from django.conf.urls import url
from .views import (
    Home, DashboardView, DashboardLogframeSelection, SwitchLogframes
)

urlpatterns = [
    url(r'^dashboard/$', DashboardLogframeSelection.as_view(), name='dashboard'),
    url(r'logframes/switch$', SwitchLogframes.as_view(), name='switch-logframes'),
    url(r'^dashboard/(?P<slug>[\w\d_-]+)/$', DashboardView.as_view(), name='logframe-dashboard'),
    url(r'^dashboard-elm/(?P<slug>[\w\d_-]+)/$', DashboardView.as_view(template_name="dashboard/dashboard_base_elm.html"), name='logframe-dashboard-elm'),
    url(r'', Home.as_view(), name='home'),
]
