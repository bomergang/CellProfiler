# coding=utf-8

import logging
import platform

import raven
import raven.conf
import raven.handlers.logging
import raven.transport.threaded_requests
import wx
import wx.lib.inspection

import cellprofiler.gui.dialog
import cellprofiler_core.preferences
import cellprofiler_core.utilities.java

logger = logging.getLogger(__name__)

transport = raven.transport.threaded_requests.ThreadedRequestsHTTPTransport

dsn = "https://c0b47db2a1b34f12b33ca8e78067617e:3cee11601374464dadd4b44da8a22dbd@sentry.io/152399"

sentry = raven.Client(dsn=dsn, transport=transport, install_sys_hook=False)

sentry.user_context(
    {
        "machine": platform.machine(),
        "processor": platform.processor(),
        "python_implementation": platform.python_implementation(),
        "python_version": platform.python_version(),
        "release": platform.release(),
        "system": platform.system(),
        "version": platform.version(),
    }
)


class App(wx.App):
    def __init__(self, *args, **kwargs):
        self.abort_initialization = False

        self.frame = None

        self.pipeline_path = kwargs.pop("pipeline_path", None)

        self.workspace_path = kwargs.pop("workspace_path", None)

        cellprofiler_core.utilities.java.start_java()

        super(App, self).__init__(*args, **kwargs)

    def OnInit(self):
        import cellprofiler.gui.cpframe

        # wx.lib.inspection.InspectionTool().Show()

        self.SetAppName("CellProfiler{0:s}".format(cellprofiler.__version__))

        self.frame = cellprofiler.gui.cpframe.CPFrame(None, -1, "CellProfiler")

        self.frame.start(self.workspace_path, self.pipeline_path)

        if self.abort_initialization:
            return False

        self.SetTopWindow(self.frame)

        self.frame.Show()

        if cellprofiler_core.preferences.get_telemetry_prompt():
            telemetry = cellprofiler.gui.dialog.Telemetry()

            if telemetry.status == wx.ID_YES:
                cellprofiler_core.preferences.set_telemetry(True)
            else:
                cellprofiler_core.preferences.set_telemetry(False)

            cellprofiler_core.preferences.set_telemetry_prompt(False)

        if cellprofiler_core.preferences.get_telemetry():
            sentry_handler = raven.handlers.logging.SentryHandler(sentry)

            sentry_handler.setLevel(logging.ERROR)

            raven.conf.setup_logging(sentry_handler)

        if self.frame.startup_blurb_frame.IsShownOnScreen():
            self.frame.startup_blurb_frame.Raise()

        return True

    def OnExit(self):
        cellprofiler_core.utilities.java.stop_java()

        return 0


if __name__ == "__main__":
    app = App(False)

    app.MainLoop()
