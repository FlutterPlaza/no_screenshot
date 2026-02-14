#include "include/no_screenshot/no_screenshot_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "no_screenshot_plugin.h"

void NoScreenshotPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  no_screenshot::NoScreenshotPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
