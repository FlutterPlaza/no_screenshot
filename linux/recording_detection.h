#ifndef RECORDING_DETECTION_H_
#define RECORDING_DETECTION_H_

#include <glib.h>

G_BEGIN_DECLS

typedef struct _RecordingDetection RecordingDetection;

// Callback invoked when the recording state changes.
typedef void (*RecordingStateChangedCallback)(gboolean is_recording,
                                              const gchar* process_name,
                                              gpointer user_data);

RecordingDetection* recording_detection_new(RecordingStateChangedCallback cb,
                                            gpointer user_data);
void recording_detection_free(RecordingDetection* self);

void recording_detection_start(RecordingDetection* self);
void recording_detection_stop(RecordingDetection* self);

gboolean recording_detection_is_recording(RecordingDetection* self);

G_END_DECLS

#endif  // RECORDING_DETECTION_H_
