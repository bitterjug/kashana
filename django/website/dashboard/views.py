from django.shortcuts import get_object_or_404
from django.views.generic import TemplateView
from django.views.generic.base import RedirectView
from django.views.generic.list import ListView

from braces.views import LoginRequiredMixin

from logframe.mixins import AptivateDataBaseMixin
from logframe.models import LogFrame
from .mixins import OverviewMixin, update_last_viewed_logframe


class Home(LoginRequiredMixin, OverviewMixin, RedirectView):
    permanent = False
    pattern_name = 'dashboard'


class DashboardView(LoginRequiredMixin,
                    OverviewMixin, AptivateDataBaseMixin, TemplateView):

    def __init__(self, template_name='dashboard/dashboard_base.html'):
            self.template_name = template_name


class SwitchLogframes(LoginRequiredMixin, RedirectView):
    permanent = False
    pattern_name = 'logframe-dashboard'

    def post(self, request, *args, **kwargs):
        self.object = get_object_or_404(LogFrame, pk=self.request.POST['logframe'])
        update_last_viewed_logframe(self.request.user, self.object)
        return self.get(request, slug=self.object.slug)


class DashboardLogframeSelection(LoginRequiredMixin, ListView):
    model = LogFrame
    context_object_name = 'logframe_list'
    template_name = 'dashboard/dashboard_logframe_list.html'
