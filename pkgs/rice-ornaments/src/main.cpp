#define WLR_USE_UNSTABLE

#include <algorithm>

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/render/Renderer.hpp>

#include "OrnamentDeco.hpp"
#include "globals.hpp"

// Do NOT change this function.
APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static void decorate(PHLWINDOW window) {
    if (std::ranges::any_of(window->presentation().decorations(), [](const auto& d) { return d->getDisplayName() == "RiceOrnaments"; }))
        return;
    HyprlandAPI::addWindowDecoration(PHANDLE, window, makeShared<COrnamentDeco>(window));
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    if (std::string{__hyprland_api_get_hash()} != std::string{__hyprland_api_get_client_hash()}) {
        HyprlandAPI::addNotification(PHANDLE, "[rice_ornaments] built for another Hyprland; not loaded", CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[rice_ornaments] version mismatch");
    }

    vars.corner   = makeShared<Config::Values::CStringValue>("plugin:rice_ornaments:corner", "Top-left corner piece (SVG or PNG), mirrored for the others", "");
    vars.size     = makeShared<Config::Values::CIntValue>("plugin:rice_ornaments:size", "Corner piece size in px", 48, Config::Values::SIntValueOptions{.min = 8, .max = 256});
    vars.reach    = makeShared<Config::Values::CIntValue>("plugin:rice_ornaments:reach", "Frame corner offset inside the piece", 6, Config::Values::SIntValueOptions{.min = 0, .max = 128});
    vars.inactive = makeShared<Config::Values::CFloatValue>("plugin:rice_ornaments:inactive", "Opacity on unfocused windows", 0.55, Config::Values::SFloatValueOptions{.min = 0.0, .max = 1.0});
    HyprlandAPI::addConfigValueV2(PHANDLE, vars.corner);
    HyprlandAPI::addConfigValueV2(PHANDLE, vars.size);
    HyprlandAPI::addConfigValueV2(PHANDLE, vars.reach);
    HyprlandAPI::addConfigValueV2(PHANDLE, vars.inactive);
    HyprlandAPI::reloadConfig();

    static auto P = Event::bus()->m_events.window.open.listen([](PHLWINDOW w) { decorate(w); });

    for (auto& w : Desktop::windowState()->windows()) {
        if (w->isHidden() || !validMapped(w))
            continue;
        decorate(w);
    }

    return {"rice_ornaments", "Theme corner ornaments on window frames", "rice", "0.1"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_pHyprRenderer->context().m_pass.removeAllOfType("COrnamentPassElement");
}
