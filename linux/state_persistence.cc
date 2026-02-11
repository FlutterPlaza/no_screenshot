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
                            gboolean is_image_overlay_mode) {
  g_autofree gchar* dir = g_path_get_dirname(self->file_path);
  g_mkdir_with_parents(dir, 0700);

  g_autofree gchar* json = g_strdup_printf(
      "{\n"
      "  \"prevent_screenshot\": %s,\n"
      "  \"is_image_overlay_mode\": %s\n"
      "}\n",
      prevent_screenshot ? "true" : "false",
      is_image_overlay_mode ? "true" : "false");

  g_autoptr(GError) error = NULL;
  if (!g_file_set_contents(self->file_path, json, -1, &error)) {
    g_warning("no_screenshot: failed to save state: %s", error->message);
  }
}

PersistedState state_persistence_load(StatePersistence* self) {
  PersistedState state = {FALSE, FALSE};

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

  return state;
}
