#include "OrnamentDeco.hpp"

#include <array>
#include <cairo/cairo.h>

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>

#include "OrnamentPassElement.hpp"
#include "globals.hpp"

using namespace Render::GL;

// The four pieces, loaded on first draw (a GL context is current then)
// and again whenever `corner` names another directory.
namespace {
    std::string                       loadedDir;
    std::array<SP<Render::ITexture>, 4> textures;

    bool ensureTextures() {
        const std::string dir = vars.corner->value();
        if (dir.empty())
            return false;
        if (dir == loadedDir)
            return textures[0] != nullptr;

        loadedDir = dir;
        const std::array<const char*, 4> names = {"tl.png", "tr.png", "bl.png", "br.png"};
        for (size_t i = 0; i < 4; ++i) {
            textures[i]       = nullptr;
            const auto path   = dir + "/" + names[i];
            const auto SURFACE = cairo_image_surface_create_from_png(path.c_str());
            if (cairo_surface_status(SURFACE) != CAIRO_STATUS_SUCCESS) {
                cairo_surface_destroy(SURFACE);
                textures = {};
                return false;
            }
            textures[i] = g_pHyprRenderer->createTexture(SURFACE);
            cairo_surface_destroy(SURFACE);
        }
        return true;
    }
}

COrnamentDeco::COrnamentDeco(PHLWINDOW window) : IHyprWindowDecoration(window), m_window(window) {
    m_lastPos  = window->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    m_lastSize = window->size(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
}

COrnamentDeco::~COrnamentDeco() {
    damageEntire();
}

// How far a piece reaches out past the window's edge.
double COrnamentDeco::outset() const {
    const auto WINDOW = m_window.lock();
    return WINDOW ? WINDOW->presentation().borderSize() + vars.reach->value() : 0;
}

SDecorationPositioningInfo COrnamentDeco::getPositioningInfo() {
    SDecorationPositioningInfo info;
    info.policy         = DECORATION_POSITION_ABSOLUTE;
    info.edges          = DECORATION_EDGE_BOTTOM | DECORATION_EDGE_LEFT | DECORATION_EDGE_RIGHT | DECORATION_EDGE_TOP;
    const double OUT    = outset();
    info.desiredExtents = {{OUT, OUT}, {OUT, OUT}};
    return info;
}

void COrnamentDeco::onPositioningReply(const SDecorationPositioningReply&) {
    updateWindow(m_window.lock());
}

uint64_t COrnamentDeco::getDecorationFlags() {
    return DECORATION_NON_SOLID;
}

eDecorationLayer COrnamentDeco::getDecorationLayer() {
    return DECORATION_LAYER_OVER;
}

eDecorationType COrnamentDeco::getDecorationType() {
    return DECORATION_CUSTOM;
}

std::string COrnamentDeco::getDisplayName() {
    return "RiceOrnaments";
}

void COrnamentDeco::updateWindow(PHLWINDOW window) {
    if (!window)
        return;
    damageEntire();
    m_lastPos  = window->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    m_lastSize = window->size(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    damageEntire();
}

// Focus changes the opacity; repaint the old and new focus.
void COrnamentDeco::onWindowFocus() {
    damageEntire();
}

void COrnamentDeco::damageEntire() {
    const double OUT = outset() + 1;
    g_pHyprRenderer->damageBox(CBox{m_lastPos.x - OUT, m_lastPos.y - OUT, m_lastSize.x + 2 * OUT, m_lastSize.y + 2 * OUT});
}

void COrnamentDeco::draw(Render::CRenderContext& ctx, PHLMONITOR, float const& a, const Render::SWindowRenderPresentation& presentation) {
    if (!validMapped(m_window) || vars.corner->value().empty())
        return;

    const auto WINDOW = m_window.lock();
    // Fullscreen and undecorated windows have no border: no ornaments.
    if (WINDOW->presentation().borderSize() == 0)
        return;

    g_pHyprRenderer->addPassElement(ctx, makeUnique<COrnamentPassElement>(COrnamentPassElement::SData{this, a, presentation}));
}

void COrnamentDeco::drawPass(Render::CRenderContext& ctx, PHLMONITOR monitor, float a, const Render::SWindowRenderPresentation& presentation) {
    if (!monitor || !ensureTextures())
        return;

    const auto WINDOW = m_window.lock();
    if (!WINDOW)
        return;

    const double BORDER = WINDOW->presentation().borderSize();
    const double SIZE   = vars.size->value();
    const double REACH  = vars.reach->value();
    const float  ALPHA  = a * (WINDOW == Desktop::focusState()->window() ? 1.F : sc<float>(vars.inactive->value()));

    // The frame's outer box, where the window is drawn this frame.
    CBox frame = {WINDOW->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT), WINDOW->size(Desktop::View::IGeometric::GEOMETRIC_CURRENT)};
    frame.translate(presentation.workspaceOffset + presentation.floatingOffset - monitor->m_position).expand(BORDER);

    const std::array<Vector2D, 4> ORIGINS = {
        Vector2D{frame.x - REACH, frame.y - REACH},
        Vector2D{frame.x + frame.w + REACH - SIZE, frame.y - REACH},
        Vector2D{frame.x - REACH, frame.y + frame.h + REACH - SIZE},
        Vector2D{frame.x + frame.w + REACH - SIZE, frame.y + frame.h + REACH - SIZE},
    };

    g_pHyprOpenGL->scissor(ctx, nullptr);
    for (size_t i = 0; i < 4; ++i) {
        CBox box = {ORIGINS[i], {SIZE, SIZE}};
        box.scale(monitor->m_scale).round();
        g_pHyprOpenGL->renderTexture(ctx, textures[i], box, {.a = ALPHA});
    }
}
