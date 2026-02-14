#include "include/no_screenshot/no_screenshot_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include "no_screenshot_plugin_private.h"
#include "screenshot_detection.h"
#include "screenshot_prevention.h"
#include "state_persistence.h"

#define NO_SCREENSHOT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), no_screenshot_plugin_get_type(), \
                              NoScreenshotPlugin))

static const char kMethodChannelName[] =
    "com.flutterplaza.no_screenshot_methods";
static const char kEventChannelName[] =
    "com.flutterplaza.no_screenshot_streams";

G_DEFINE_TYPE(NoScreenshotPlugin, no_screenshot_plugin, g_object_get_type())

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

gchar* build_event_json(gboolean is_screenshot_on,
                        const gchar* screenshot_path,
                        gboolean was_screenshot_taken,
                        gboolean is_screen_recording,
                        gint64 timestamp_ms,
                        const gchar* source_app) {
  // Hand-build JSON to avoid extra dependencies.
  return g_strdup_printf(
      "{\"is_screenshot_on\":%s,\"screenshot_path\":\"%s\","
      "\"was_screenshot_taken\":%s,\"is_screen_recording\":%s,"
      "\"timestamp\":%" G_GINT64_FORMAT ",\"source_app\":\"%s\"}",
      is_screenshot_on ? "true" : "false",
      screenshot_path ? screenshot_path : "",
      was_screenshot_taken ? "true" : "false",
      is_screen_recording ? "true" : "false",
      timestamp_ms,
      source_app ? source_app : "");
}

static void update_shared_state(NoScreenshotPlugin* self,
                                const gchar* screenshot_path) {
  gboolean was_taken = (screenshot_path != NULL && screenshot_path[0] != '\0');

  g_autofree gchar* json =
      build_event_json(self->prevent_screenshot, screenshot_path, was_taken,
                       self->is_screen_recording, self->last_timestamp_ms,
                       self->last_source_app);

  if (g_strcmp0(json, self->last_event_json) != 0) {
    g_free(self->last_event_json);
    self->last_event_json = g_strdup(json);
    self->has_pending_event = TRUE;
  }
}

static void persist_state(NoScreenshotPlugin* self) {
  state_persistence_save(self->persistence, self->prevent_screenshot,
                         self->is_image_overlay_mode,
                         self->is_blur_overlay_mode,
                         self->is_color_overlay_mode,
                         self->blur_radius,
                         self->color_value);
  update_shared_state(self, "");
}

// ---------------------------------------------------------------------------
// Screenshot detection callback
// ---------------------------------------------------------------------------

static void on_screenshot_detected(const gchar* file_path,
                                   gint64 timestamp_ms,
                                   const gchar* source_app,
                                   gpointer user_data) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(user_data);
  self->last_timestamp_ms = timestamp_ms;
  g_free(self->last_source_app);
  self->last_source_app = g_strdup(source_app ? source_app : "");
  update_shared_state(self, file_path);
}

// ---------------------------------------------------------------------------
// Recording detection callback
// ---------------------------------------------------------------------------

static void on_recording_state_changed(gboolean is_recording,
                                       const gchar* process_name,
                                       gpointer user_data) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(user_data);
  self->is_screen_recording = is_recording;
  self->last_timestamp_ms = g_get_real_time() / 1000;
  g_free(self->last_source_app);
  self->last_source_app = g_strdup(process_name ? process_name : "");
  update_shared_state(self, "");
}

// ---------------------------------------------------------------------------
// Method channel handler
// ---------------------------------------------------------------------------

static void handle_method_call(FlMethodChannel* channel,
                               FlMethodCall* method_call,
                               gpointer user_data) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = NULL;

  if (g_strcmp0(method, "screenshotOff") == 0) {
    self->prevent_screenshot = TRUE;
    prevention_activate();
    persist_state(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));

  } else if (g_strcmp0(method, "screenshotOn") == 0) {
    self->prevent_screenshot = FALSE;
    prevention_deactivate();
    persist_state(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));

  } else if (g_strcmp0(method, "toggleScreenshot") == 0) {
    if (self->prevent_screenshot) {
      self->prevent_screenshot = FALSE;
      prevention_deactivate();
    } else {
      self->prevent_screenshot = TRUE;
      prevention_activate();
    }
    persist_state(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));

  } else if (g_strcmp0(method, "toggleScreenshotWithImage") == 0) {
    self->is_image_overlay_mode = !self->is_image_overlay_mode;
    if (self->is_image_overlay_mode) {
      // Deactivate blur and color modes if active (mutual exclusivity)
      if (self->is_blur_overlay_mode) {
        self->is_blur_overlay_mode = FALSE;
      }
      if (self->is_color_overlay_mode) {
        self->is_color_overlay_mode = FALSE;
      }
      self->prevent_screenshot = TRUE;
      prevention_activate();
    } else {
      self->prevent_screenshot = FALSE;
      prevention_deactivate();
    }
    g_message(
        "no_screenshot: toggleScreenshotWithImage → %s (overlay is "
        "best-effort on Linux — compositors control task switcher "
        "thumbnails).",
        self->is_image_overlay_mode ? "ON" : "OFF");
    persist_state(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(self->is_image_overlay_mode)));

  } else if (g_strcmp0(method, "toggleScreenshotWithBlur") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != NULL && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* radius_val = fl_value_lookup_string(args, "radius");
      if (radius_val != NULL &&
          fl_value_get_type(radius_val) == FL_VALUE_TYPE_FLOAT) {
        self->blur_radius = fl_value_get_float(radius_val);
      }
    }
    self->is_blur_overlay_mode = !self->is_blur_overlay_mode;
    if (self->is_blur_overlay_mode) {
      // Deactivate image and color modes if active (mutual exclusivity)
      if (self->is_image_overlay_mode) {
        self->is_image_overlay_mode = FALSE;
      }
      if (self->is_color_overlay_mode) {
        self->is_color_overlay_mode = FALSE;
      }
      self->prevent_screenshot = TRUE;
      prevention_activate();
    } else {
      self->prevent_screenshot = FALSE;
      prevention_deactivate();
    }
    g_message(
        "no_screenshot: toggleScreenshotWithBlur → %s (radius=%.1f, blur is "
        "best-effort on Linux — compositors control task switcher "
        "thumbnails).",
        self->is_blur_overlay_mode ? "ON" : "OFF", self->blur_radius);
    persist_state(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(self->is_blur_overlay_mode)));

  } else if (g_strcmp0(method, "toggleScreenshotWithColor") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != NULL && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* color_val = fl_value_lookup_string(args, "color");
      if (color_val != NULL &&
          fl_value_get_type(color_val) == FL_VALUE_TYPE_INT) {
        self->color_value = (gint)fl_value_get_int(color_val);
      }
    }
    self->is_color_overlay_mode = !self->is_color_overlay_mode;
    if (self->is_color_overlay_mode) {
      // Deactivate image and blur modes if active (mutual exclusivity)
      if (self->is_image_overlay_mode) {
        self->is_image_overlay_mode = FALSE;
      }
      if (self->is_blur_overlay_mode) {
        self->is_blur_overlay_mode = FALSE;
      }
      self->prevent_screenshot = TRUE;
      prevention_activate();
    } else {
      self->prevent_screenshot = FALSE;
      prevention_deactivate();
    }
    g_message(
        "no_screenshot: toggleScreenshotWithColor → %s (color=0x%08X, "
        "color overlay is best-effort on Linux — compositors control task "
        "switcher thumbnails).",
        self->is_color_overlay_mode ? "ON" : "OFF", self->color_value);
    persist_state(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(self->is_color_overlay_mode)));

  } else if (g_strcmp0(method, "screenshotWithImage") == 0) {
    self->is_image_overlay_mode = TRUE;
    if (self->is_blur_overlay_mode) {
      self->is_blur_overlay_mode = FALSE;
    }
    if (self->is_color_overlay_mode) {
      self->is_color_overlay_mode = FALSE;
    }
    self->prevent_screenshot = TRUE;
    prevention_activate();
    persist_state(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));

  } else if (g_strcmp0(method, "screenshotWithBlur") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != NULL && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* radius_val = fl_value_lookup_string(args, "radius");
      if (radius_val != NULL &&
          fl_value_get_type(radius_val) == FL_VALUE_TYPE_FLOAT) {
        self->blur_radius = fl_value_get_float(radius_val);
      }
    }
    self->is_blur_overlay_mode = TRUE;
    if (self->is_image_overlay_mode) {
      self->is_image_overlay_mode = FALSE;
    }
    if (self->is_color_overlay_mode) {
      self->is_color_overlay_mode = FALSE;
    }
    self->prevent_screenshot = TRUE;
    prevention_activate();
    persist_state(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));

  } else if (g_strcmp0(method, "screenshotWithColor") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != NULL && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* color_val = fl_value_lookup_string(args, "color");
      if (color_val != NULL &&
          fl_value_get_type(color_val) == FL_VALUE_TYPE_INT) {
        self->color_value = (gint)fl_value_get_int(color_val);
      }
    }
    self->is_color_overlay_mode = TRUE;
    if (self->is_image_overlay_mode) {
      self->is_image_overlay_mode = FALSE;
    }
    if (self->is_blur_overlay_mode) {
      self->is_blur_overlay_mode = FALSE;
    }
    self->prevent_screenshot = TRUE;
    prevention_activate();
    persist_state(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));

  } else if (g_strcmp0(method, "startScreenshotListening") == 0) {
    if (!self->is_listening) {
      self->is_listening = TRUE;
      screenshot_detection_start(self->detection);
      persist_state(self);
    }
    g_autoptr(FlValue) msg = fl_value_new_string("Listening started");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(msg));

  } else if (g_strcmp0(method, "stopScreenshotListening") == 0) {
    if (self->is_listening) {
      self->is_listening = FALSE;
      screenshot_detection_stop(self->detection);
      persist_state(self);
    }
    g_autoptr(FlValue) msg = fl_value_new_string("Listening stopped");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(msg));

  } else if (g_strcmp0(method, "startScreenRecordingListening") == 0) {
    if (!self->is_recording_listening) {
      self->is_recording_listening = TRUE;
      recording_detection_start(self->recording_detection);
      update_shared_state(self, "");
    }
    g_autoptr(FlValue) msg = fl_value_new_string("Recording listening started");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(msg));

  } else if (g_strcmp0(method, "stopScreenRecordingListening") == 0) {
    if (self->is_recording_listening) {
      self->is_recording_listening = FALSE;
      recording_detection_stop(self->recording_detection);
      self->is_screen_recording = FALSE;
      update_shared_state(self, "");
    }
    g_autoptr(FlValue) msg =
        fl_value_new_string("Recording listening stopped");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(msg));

  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, NULL);
}

// ---------------------------------------------------------------------------
// Event channel (stream) handler
// ---------------------------------------------------------------------------

static gboolean stream_tick(gpointer user_data) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(user_data);

  if (self->has_pending_event && self->stream_active &&
      self->event_channel != NULL) {
    g_autoptr(FlValue) value = fl_value_new_string(self->last_event_json);
    fl_event_channel_send(self->event_channel, value, NULL, NULL);
    self->has_pending_event = FALSE;
  }

  return G_SOURCE_CONTINUE;
}

static FlMethodErrorResponse* on_listen(FlEventChannel* channel,
                                        FlValue* args,
                                        gpointer user_data) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(user_data);
  self->stream_active = TRUE;

  if (self->stream_timer_id == 0) {
    self->stream_timer_id = g_timeout_add(1000, stream_tick, self);
  }

  return NULL;
}

static FlMethodErrorResponse* on_cancel(FlEventChannel* channel,
                                        FlValue* args,
                                        gpointer user_data) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(user_data);
  self->stream_active = FALSE;

  if (self->stream_timer_id != 0) {
    g_source_remove(self->stream_timer_id);
    self->stream_timer_id = 0;
  }

  return NULL;
}

// ---------------------------------------------------------------------------
// GObject lifecycle
// ---------------------------------------------------------------------------

static void no_screenshot_plugin_dispose(GObject* object) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(object);

  if (self->stream_timer_id != 0) {
    g_source_remove(self->stream_timer_id);
    self->stream_timer_id = 0;
  }

  g_clear_object(&self->method_channel);
  g_clear_object(&self->event_channel);

  screenshot_detection_free(self->detection);
  self->detection = NULL;

  recording_detection_free(self->recording_detection);
  self->recording_detection = NULL;

  state_persistence_free(self->persistence);
  self->persistence = NULL;

  g_free(self->last_event_json);
  self->last_event_json = NULL;

  g_free(self->last_source_app);
  self->last_source_app = NULL;

  G_OBJECT_CLASS(no_screenshot_plugin_parent_class)->dispose(object);
}

static void no_screenshot_plugin_class_init(NoScreenshotPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = no_screenshot_plugin_dispose;
}

static void no_screenshot_plugin_init(NoScreenshotPlugin* self) {
  self->prevent_screenshot = FALSE;
  self->is_image_overlay_mode = FALSE;
  self->is_blur_overlay_mode = FALSE;
  self->is_color_overlay_mode = FALSE;
  self->blur_radius = 30.0;
  self->color_value = (gint)0xFF000000;
  self->is_listening = FALSE;
  self->is_recording_listening = FALSE;
  self->is_screen_recording = FALSE;
  self->last_event_json = NULL;
  self->has_pending_event = FALSE;
  self->stream_timer_id = 0;
  self->stream_active = FALSE;
  self->detection = NULL;
  self->recording_detection = NULL;
  self->persistence = NULL;
  self->last_timestamp_ms = 0;
  self->last_source_app = NULL;
}

// ---------------------------------------------------------------------------
// Plugin registration
// ---------------------------------------------------------------------------

void no_screenshot_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  NoScreenshotPlugin* self = NO_SCREENSHOT_PLUGIN(
      g_object_new(no_screenshot_plugin_get_type(), NULL));

  self->registrar = registrar;

  // Subsystems
  self->persistence = state_persistence_new();
  self->detection =
      screenshot_detection_new(on_screenshot_detected, self);
  self->recording_detection =
      recording_detection_new(on_recording_state_changed, self);

  // Load persisted state
  PersistedState state = state_persistence_load(self->persistence);
  self->prevent_screenshot = state.prevent_screenshot;
  self->is_image_overlay_mode = state.is_image_overlay_mode;
  self->is_blur_overlay_mode = state.is_blur_overlay_mode;
  self->is_color_overlay_mode = state.is_color_overlay_mode;
  self->blur_radius = state.blur_radius;
  self->color_value = state.color_value;

  if (self->prevent_screenshot) {
    prevention_activate();
  }

  // Method channel
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), kMethodChannelName,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->method_channel, handle_method_call, g_object_ref(self),
      g_object_unref);

  // Event channel
  g_autoptr(FlStandardMethodCodec) event_codec =
      fl_standard_method_codec_new();
  self->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar), kEventChannelName,
      FL_METHOD_CODEC(event_codec));
  fl_event_channel_set_stream_handlers(self->event_channel, on_listen,
                                       on_cancel, g_object_ref(self),
                                       g_object_unref);

  // Initial state push
  update_shared_state(self, "");

  g_object_unref(self);
}
