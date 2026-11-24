//
//  ChromiumHelperMain.mm
//  AgenticDeveloperHubSDKChromium
//
//  The executable of every Chromium helper process: renderer, GPU, network,
//  plugin and alerts. Chromium starts the app's `<App> Helper` bundles with a
//  `--type=` switch and this hands control straight back to it.
//
//  Not part of the framework target: `tools/apple/cef.py embed` compiles it
//  against the CEF distribution and builds the five helper bundles into the
//  app's Frameworks folder, beside Chromium Embedded Framework.framework.
//

#include "include/cef_app.h"
#include "include/cef_sandbox_mac.h"
#include "include/wrapper/cef_library_loader.h"

int main(int argc, char* argv[]) {
  // The sandbox goes on before the framework is loaded, as CEF requires.
  CefScopedSandboxContext sandbox_context;
  if (!sandbox_context.Initialize(argc, argv)) {
    return 1;
  }
  // The framework is three levels up: Helper.app/Contents/MacOS → Frameworks.
  CefScopedLibraryLoader library_loader;
  if (!library_loader.LoadInHelper()) {
    return 1;
  }
  CefMainArgs main_args(argc, argv);
  return CefExecuteProcess(main_args, nullptr, nullptr);
}
