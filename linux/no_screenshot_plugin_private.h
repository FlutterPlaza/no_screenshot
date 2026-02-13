#ifndef NO_SCREENSHOT_PLUGIN_PRIVATE_H_
#define NO_SCREENSHOT_PLUGIN_PRIVATE_H_

#include <flutter_linux/flutter_linux.h>

#include "recording_detection.h"
#include "screenshot_detection.h"
#include "screenshot_prevention.h"
#include "state_persistence.h"

G_BEGIN_DECLS

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
  gboolean is_listening;

  // Event stream
  gchar* last_event_json;
  gboolean has_pending_event;
  guint stream_timer_id;
  FlEventSink* event_sink;

  // Recording detection
  gboolean is_recording_listening;
  gboolean is_screen_recording;

  // Subsystems
  ScreenshotDetection* detection;
  RecordingDetection* recording_detection;
  StatePersistence* persistence;
};

// Build a JSON string matching the Dart ScreenshotSnapshot format.
gchar* build_event_json(gboolean is_screenshot_on,
                        const gchar* screenshot_path,
                        gboolean was_screenshot_taken,
                        gboolean is_screen_recording);

G_END_DECLS

#endif  // NO_SCREENSHOT_PLUGIN_PRIVATE_H_
