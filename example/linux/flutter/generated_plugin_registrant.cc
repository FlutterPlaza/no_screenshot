//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <no_screenshot/no_screenshot_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) no_screenshot_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NoScreenshotPlugin");
  no_screenshot_plugin_register_with_registrar(no_screenshot_registrar);
}
