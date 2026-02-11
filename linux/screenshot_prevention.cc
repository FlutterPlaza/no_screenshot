#include "screenshot_prevention.h"

#include <gdk/gdk.h>

#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

static const gchar* detect_display_server() {
  GdkDisplay* display = gdk_display_get_default();
  if (display == NULL) return "unknown";

#ifdef GDK_WINDOWING_WAYLAND
  if (GDK_IS_WAYLAND_DISPLAY(display)) return "wayland";
#endif
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_DISPLAY(display)) return "x11";
#endif

  return "unknown";
}

void prevention_activate() {
  const gchar* server = detect_display_server();
  g_message(
      "no_screenshot: screenshot prevention activated (best-effort on Linux, "
      "display server: %s). Linux compositors do not expose a "
      "FLAG_SECURE-equivalent API.",
      server);
}

void prevention_deactivate() {
  const gchar* server = detect_display_server();
  g_message(
      "no_screenshot: screenshot prevention deactivated (display server: %s).",
      server);
}
