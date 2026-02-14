#include "screenshot_detection.h"

#include <gio/gio.h>

#include <string.h>

#define MAX_MONITORS 4
#define DEBOUNCE_SECONDS 2

struct _ScreenshotDetection {
  ScreenshotDetectedCallback callback;
  gpointer user_data;

  GFileMonitor* monitors[MAX_MONITORS];
  int monitor_count;

  gint64 last_detection_time;  // monotonic microseconds
};

static gboolean is_screenshot_filename(const gchar* basename) {
  // Common screenshot tool naming patterns on Linux.
  static const gchar* const prefixes[] = {
      "Screenshot",  // GNOME Screenshot, generic
      "screenshot",  // lowercase variant
      "Spectacle",   // KDE Spectacle
      "spectacle",
      "flameshot",   // Flameshot
      "Flameshot",
      "scrot",       // scrot
      "shutter",     // Shutter
      "maim",        // maim
      NULL,
  };

  for (int i = 0; prefixes[i] != NULL; i++) {
    if (g_str_has_prefix(basename, prefixes[i])) return TRUE;
  }

  // Also match filenames that contain "screenshot" anywhere (case-insensitive).
  g_autofree gchar* lower = g_ascii_strdown(basename, -1);
  if (strstr(lower, "screenshot") != NULL) return TRUE;

  return FALSE;
}

static const gchar* infer_source_app(const gchar* basename) {
  if (g_str_has_prefix(basename, "Screenshot") ||
      g_str_has_prefix(basename, "screenshot")) {
    return "GNOME Screenshot";
  }
  if (g_str_has_prefix(basename, "Spectacle") ||
      g_str_has_prefix(basename, "spectacle")) {
    return "KDE Spectacle";
  }
  if (g_str_has_prefix(basename, "flameshot") ||
      g_str_has_prefix(basename, "Flameshot")) {
    return "Flameshot";
  }
  if (g_str_has_prefix(basename, "scrot")) {
    return "scrot";
  }
  if (g_str_has_prefix(basename, "shutter")) {
    return "Shutter";
  }
  if (g_str_has_prefix(basename, "maim")) {
    return "maim";
  }
  return "";
}

static void on_file_changed(GFileMonitor* monitor,
                            GFile* file,
                            GFile* other_file,
                            GFileMonitorEvent event_type,
                            gpointer user_data) {
  if (event_type != G_FILE_MONITOR_EVENT_CREATED) return;

  ScreenshotDetection* self = (ScreenshotDetection*)user_data;

  g_autofree gchar* basename = g_file_get_basename(file);
  if (basename == NULL || !is_screenshot_filename(basename)) return;

  // Debounce: ignore events within DEBOUNCE_SECONDS of the last detection.
  gint64 now = g_get_monotonic_time();
  if ((now - self->last_detection_time) < (DEBOUNCE_SECONDS * G_USEC_PER_SEC))
    return;
  self->last_detection_time = now;

  g_autofree gchar* path = g_file_get_path(file);
  if (path != NULL && self->callback != NULL) {
    // Get file modification time as best approximation of creation time.
    gint64 timestamp_ms = 0;
    g_autoptr(GError) error = NULL;
    g_autoptr(GFileInfo) info = g_file_query_info(
        file, G_FILE_ATTRIBUTE_TIME_MODIFIED, G_FILE_QUERY_INFO_NONE, NULL,
        &error);
    if (info != NULL) {
      guint64 mtime = g_file_info_get_attribute_uint64(
          info, G_FILE_ATTRIBUTE_TIME_MODIFIED);
      timestamp_ms = (gint64)mtime * 1000;
    }
    if (timestamp_ms <= 0) {
      // Fallback to wall clock.
      timestamp_ms = g_get_real_time() / 1000;
    }

    const gchar* source_app = infer_source_app(basename);
    self->callback(path, timestamp_ms, source_app, self->user_data);
  }
}

static void add_monitor(ScreenshotDetection* self, const gchar* dir_path) {
  if (dir_path == NULL || self->monitor_count >= MAX_MONITORS) return;

  // Only monitor directories that exist.
  if (!g_file_test(dir_path, G_FILE_TEST_IS_DIR)) return;

  g_autoptr(GFile) dir = g_file_new_for_path(dir_path);
  g_autoptr(GError) error = NULL;

  GFileMonitor* monitor =
      g_file_monitor_directory(dir, G_FILE_MONITOR_NONE, NULL, &error);
  if (monitor == NULL) {
    g_warning("no_screenshot: failed to monitor %s: %s", dir_path,
              error->message);
    return;
  }

  g_signal_connect(monitor, "changed", G_CALLBACK(on_file_changed), self);
  self->monitors[self->monitor_count++] = monitor;
  g_message("no_screenshot: monitoring %s", dir_path);
}

ScreenshotDetection* screenshot_detection_new(ScreenshotDetectedCallback cb,
                                              gpointer user_data) {
  ScreenshotDetection* self = g_new0(ScreenshotDetection, 1);
  self->callback = cb;
  self->user_data = user_data;
  self->last_detection_time = 0;
  return self;
}

void screenshot_detection_free(ScreenshotDetection* self) {
  if (self == NULL) return;
  screenshot_detection_stop(self);
  g_free(self);
}

void screenshot_detection_start(ScreenshotDetection* self) {
  if (self->monitor_count > 0) return;  // Already started.

  const gchar* home = g_get_home_dir();

  // ~/Pictures/Screenshots/ (GNOME, many tools)
  g_autofree gchar* screenshots_dir =
      g_build_filename(home, "Pictures", "Screenshots", NULL);
  add_monitor(self, screenshots_dir);

  // ~/Pictures/ (fallback — some tools save directly here)
  g_autofree gchar* pictures_dir = g_build_filename(home, "Pictures", NULL);
  add_monitor(self, pictures_dir);

  // XDG pictures directory (if different from ~/Pictures)
  const gchar* xdg_pictures =
      g_get_user_special_dir(G_USER_DIRECTORY_PICTURES);
  if (xdg_pictures != NULL && g_strcmp0(xdg_pictures, pictures_dir) != 0) {
    add_monitor(self, xdg_pictures);
  }
}

void screenshot_detection_stop(ScreenshotDetection* self) {
  for (int i = 0; i < self->monitor_count; i++) {
    g_file_monitor_cancel(self->monitors[i]);
    g_object_unref(self->monitors[i]);
    self->monitors[i] = NULL;
  }
  self->monitor_count = 0;
}
