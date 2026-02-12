#include "recording_detection.h"

#include <dirent.h>
#include <stdio.h>
#include <string.h>

#define POLL_INTERVAL_SECONDS 2

static const gchar* const kKnownRecordingProcessNames[] = {
    "ffmpeg",
    "obs",
    "simplescreenrecorder",
    "kazam",
    "peek",
    "recordmydesktop",
    "vokoscreen",
    "gtk-recordmydesktop",
    NULL,
};

struct _RecordingDetection {
  RecordingStateChangedCallback callback;
  gpointer user_data;

  guint poll_timer_id;
  gboolean is_recording;
};

static gboolean is_known_recording_process(const gchar* comm) {
  for (int i = 0; kKnownRecordingProcessNames[i] != NULL; i++) {
    if (g_strcmp0(comm, kKnownRecordingProcessNames[i]) == 0) return TRUE;
  }
  return FALSE;
}

static gboolean check_recording_processes(gpointer user_data) {
  RecordingDetection* self = (RecordingDetection*)user_data;

  gboolean found = FALSE;
  DIR* proc_dir = opendir("/proc");
  if (proc_dir == NULL) return G_SOURCE_CONTINUE;

  struct dirent* entry;
  while ((entry = readdir(proc_dir)) != NULL) {
    // Only consider numeric directories (PIDs).
    if (entry->d_name[0] < '0' || entry->d_name[0] > '9') continue;

    gchar comm_path[256];
    g_snprintf(comm_path, sizeof(comm_path), "/proc/%s/comm", entry->d_name);

    FILE* fp = fopen(comm_path, "r");
    if (fp == NULL) continue;

    gchar comm[256];
    if (fgets(comm, sizeof(comm), fp) != NULL) {
      // Strip trailing newline.
      gsize len = strlen(comm);
      if (len > 0 && comm[len - 1] == '\n') comm[len - 1] = '\0';

      if (is_known_recording_process(comm)) {
        found = TRUE;
        fclose(fp);
        break;
      }
    }
    fclose(fp);
  }
  closedir(proc_dir);

  // Fire callback only on state transitions.
  if (found != self->is_recording) {
    self->is_recording = found;
    if (self->callback != NULL) {
      self->callback(self->is_recording, self->user_data);
    }
  }

  return G_SOURCE_CONTINUE;
}

RecordingDetection* recording_detection_new(RecordingStateChangedCallback cb,
                                            gpointer user_data) {
  RecordingDetection* self = g_new0(RecordingDetection, 1);
  self->callback = cb;
  self->user_data = user_data;
  self->poll_timer_id = 0;
  self->is_recording = FALSE;
  return self;
}

void recording_detection_free(RecordingDetection* self) {
  if (self == NULL) return;
  recording_detection_stop(self);
  g_free(self);
}

void recording_detection_start(RecordingDetection* self) {
  if (self->poll_timer_id != 0) return;  // Already started.

  // Do an initial check immediately.
  check_recording_processes(self);

  self->poll_timer_id =
      g_timeout_add_seconds(POLL_INTERVAL_SECONDS, check_recording_processes, self);
}

void recording_detection_stop(RecordingDetection* self) {
  if (self->poll_timer_id != 0) {
    g_source_remove(self->poll_timer_id);
    self->poll_timer_id = 0;
  }
  self->is_recording = FALSE;
}

gboolean recording_detection_is_recording(RecordingDetection* self) {
  return self->is_recording;
}
