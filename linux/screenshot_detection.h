#ifndef SCREENSHOT_DETECTION_H_
#define SCREENSHOT_DETECTION_H_

#include <glib.h>

G_BEGIN_DECLS

typedef struct _ScreenshotDetection ScreenshotDetection;

// Callback invoked when a new screenshot file is detected.
typedef void (*ScreenshotDetectedCallback)(const gchar* file_path,
                                           gint64 timestamp_ms,
                                           const gchar* source_app,
                                           gpointer user_data);

ScreenshotDetection* screenshot_detection_new(ScreenshotDetectedCallback cb,
                                              gpointer user_data);
void screenshot_detection_free(ScreenshotDetection* self);

void screenshot_detection_start(ScreenshotDetection* self);
void screenshot_detection_stop(ScreenshotDetection* self);

G_END_DECLS

#endif  // SCREENSHOT_DETECTION_H_
