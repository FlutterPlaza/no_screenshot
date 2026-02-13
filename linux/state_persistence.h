#ifndef STATE_PERSISTENCE_H_
#define STATE_PERSISTENCE_H_

#include <glib.h>

G_BEGIN_DECLS

typedef struct {
  gboolean prevent_screenshot;
  gboolean is_image_overlay_mode;
  gboolean is_blur_overlay_mode;
} PersistedState;

typedef struct _StatePersistence StatePersistence;

StatePersistence* state_persistence_new();
void state_persistence_free(StatePersistence* self);

void state_persistence_save(StatePersistence* self,
                            gboolean prevent_screenshot,
                            gboolean is_image_overlay_mode,
                            gboolean is_blur_overlay_mode);

PersistedState state_persistence_load(StatePersistence* self);

G_END_DECLS

#endif  // STATE_PERSISTENCE_H_
