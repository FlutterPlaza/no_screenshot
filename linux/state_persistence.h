#ifndef STATE_PERSISTENCE_H_
#define STATE_PERSISTENCE_H_

#include <glib.h>

G_BEGIN_DECLS

typedef struct {
  gboolean prevent_screenshot;
  gboolean independent_prevention;
  // Whether the independent_prevention key was present in the file —
  // absent on files written by older versions (used for migration).
  gboolean has_independent_prevention;
  gboolean is_image_overlay_mode;
  gboolean is_blur_overlay_mode;
  gboolean is_color_overlay_mode;
  gdouble blur_radius;
  gint color_value;
} PersistedState;

typedef struct _StatePersistence StatePersistence;

StatePersistence* state_persistence_new();
void state_persistence_free(StatePersistence* self);

void state_persistence_save(StatePersistence* self,
                            gboolean prevent_screenshot,
                            gboolean independent_prevention,
                            gboolean is_image_overlay_mode,
                            gboolean is_blur_overlay_mode,
                            gboolean is_color_overlay_mode,
                            gdouble blur_radius,
                            gint color_value);

PersistedState state_persistence_load(StatePersistence* self);

G_END_DECLS

#endif  // STATE_PERSISTENCE_H_
