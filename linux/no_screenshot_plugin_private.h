#ifndef NO_SCREENSHOT_PLUGIN_PRIVATE_H_
#define NO_SCREENSHOT_PLUGIN_PRIVATE_H_

#include <flutter_linux/flutter_linux.h>

#include "recording_detection.h"
#include "screenshot_detection.h"
#include "screenshot_prevention.h"
#include "state_persistence.h"

G_BEGIN_DECLS

// Forward typedefs required by G_DEFINE_TYPE.
typedef struct _NoScreenshotPlugin NoScreenshotPlugin;
typedef struct _NoScreenshotPluginClass NoScreenshotPluginClass;

struct _NoScreenshotPluginClass {
  GObjectClass parent_class;
};

// Internal plugin struct — fields accessible from no_screenshot_plugin.cc.
struct _NoScreenshotPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;
  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;

  // State
  gboolean prevent_screenshot;
  gboolean is_image_overlay_mode;
  gboolean is_blur_overlay_mode;
  gboolean is_color_overlay_mode;
  gdouble blur_radius;
  gint color_value;
  gboolean is_listening;

  // Event stream
  gchar* last_event_json;
  gboolean has_pending_event;
  guint stream_timer_id;
  gboolean stream_active;

  // Recording detection
  gboolean is_recording_listening;
  gboolean is_screen_recording;

  // P8 metadata
  gint64 last_timestamp_ms;
  gchar* last_source_app;

  // Subsystems
  ScreenshotDetection* detection;
  RecordingDetection* recording_detection;
  StatePersistence* persistence;
};

// Build a JSON string matching the Dart ScreenshotSnapshot format.
gchar* build_event_json(gboolean is_screenshot_on,
                        const gchar* screenshot_path,
                        gboolean was_screenshot_taken,
                        gboolean is_screen_recording,
                        gint64 timestamp_ms,
                        const gchar* source_app);

G_END_DECLS

#endif  // NO_SCREENSHOT_PLUGIN_PRIVATE_H_
