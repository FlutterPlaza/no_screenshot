#include "state_persistence.h"

#include <gio/gio.h>

struct _StatePersistence {
  gchar* file_path;
};

static gchar* get_state_file_path() {
  return g_build_filename(g_get_user_data_dir(), "no_screenshot", "state.json",
                          NULL);
}

StatePersistence* state_persistence_new() {
  StatePersistence* self = g_new0(StatePersistence, 1);
  self->file_path = get_state_file_path();
  return self;
}

void state_persistence_free(StatePersistence* self) {
  if (self == NULL) return;
  g_free(self->file_path);
  g_free(self);
}

void state_persistence_save(StatePersistence* self,
                            gboolean prevent_screenshot,
                            gboolean is_image_overlay_mode,
                            gboolean is_blur_overlay_mode,
                            gboolean is_color_overlay_mode,
                            gdouble blur_radius,
                            gint color_value) {
  g_autofree gchar* dir = g_path_get_dirname(self->file_path);
  g_mkdir_with_parents(dir, 0700);

  g_autofree gchar* json = g_strdup_printf(
      "{\n"
      "  \"prevent_screenshot\": %s,\n"
      "  \"is_image_overlay_mode\": %s,\n"
      "  \"is_blur_overlay_mode\": %s,\n"
      "  \"is_color_overlay_mode\": %s,\n"
      "  \"blur_radius\": %.1f,\n"
      "  \"color_value\": %d\n"
      "}\n",
      prevent_screenshot ? "true" : "false",
      is_image_overlay_mode ? "true" : "false",
      is_blur_overlay_mode ? "true" : "false",
      is_color_overlay_mode ? "true" : "false",
      blur_radius,
      color_value);

  g_autoptr(GError) error = NULL;
  if (!g_file_set_contents(self->file_path, json, -1, &error)) {
    g_warning("no_screenshot: failed to save state: %s", error->message);
  }
}

PersistedState state_persistence_load(StatePersistence* self) {
  PersistedState state = {FALSE, FALSE, FALSE, FALSE, 30.0, (gint)0xFF000000};

  g_autofree gchar* contents = NULL;
  g_autoptr(GError) error = NULL;

  if (!g_file_get_contents(self->file_path, &contents, NULL, &error)) {
    // File doesn't exist yet — return defaults.
    return state;
  }

  // Simple string search — avoids pulling in a full JSON parser.
  if (g_strstr_len(contents, -1, "\"prevent_screenshot\": true") != NULL) {
    state.prevent_screenshot = TRUE;
  }
  if (g_strstr_len(contents, -1, "\"is_image_overlay_mode\": true") != NULL) {
    state.is_image_overlay_mode = TRUE;
  }
  if (g_strstr_len(contents, -1, "\"is_blur_overlay_mode\": true") != NULL) {
    state.is_blur_overlay_mode = TRUE;
  }
  if (g_strstr_len(contents, -1, "\"is_color_overlay_mode\": true") != NULL) {
    state.is_color_overlay_mode = TRUE;
  }

  // Extract blur_radius (simple parse after key)
  const gchar* radius_key = "\"blur_radius\": ";
  const gchar* radius_pos = g_strstr_len(contents, -1, radius_key);
  if (radius_pos != NULL) {
    state.blur_radius = g_ascii_strtod(radius_pos + strlen(radius_key), NULL);
    if (state.blur_radius <= 0) state.blur_radius = 30.0;
  }

  // Extract color_value (simple parse after key)
  const gchar* color_key = "\"color_value\": ";
  const gchar* color_pos = g_strstr_len(contents, -1, color_key);
  if (color_pos != NULL) {
    state.color_value = (gint)g_ascii_strtoll(color_pos + strlen(color_key),
                                              NULL, 10);
  }

  return state;
}
