#include "OrnamentDeco.hpp"

#include <array>
#include <cairo/cairo.h>
#include <hyprgraphics/image/Image.hpp>

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>

#include "OrnamentPassElement.hpp"
#include "globals.hpp"

using namespace Render::GL;

// The four pieces, rendered on first draw (a GL context is current then)
// and again whenever `corner` or `size` changes: the corner art at twice
// its drawn size, mirrored for the other three corners.
namespace {
    std::string                         loadedPath;
    int                                 loadedSize = 0;
    std::array<SP<Render::ITexture>, 4> textures;

    bool ensureTextures() {
        const std::string path = vars.corner->value();
        const int         px   = sc<int>(vars.size->value()) * 2;
        if (path.empty())
            return false;
        if (path == loadedPath && px == loadedSize)
            return textures[0] != nullptr;

        loadedPath = path;
        loadedSize = px;
        textures   = {};

        Hyprgraphics::CImage image(path, Vector2D{sc<double>(px), sc<double>(px)});
        if (!image.success())
            return false;
        const auto SOURCE = image.cairoSurface();
        const auto SIZE   = SOURCE->size();

        // tl, tr, bl, br: scale (x, y) = (1, 1), (-1, 1), (1, -1), (-1, -1).
        const std::array<std::pair<double, double>, 4> FLIPS = {{{1, 1}, {-1, 1}, {1, -1}, {-1, -1}}};
        for (size_t i = 0; i < 4; ++i) {
            const auto SURFACE = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, px, px);
            const auto CR      = cairo_create(SURFACE);
            cairo_translate(CR, FLIPS[i].first < 0 ? px : 0, FLIPS[i].second < 0 ? px : 0);
            cairo_scale(CR, FLIPS[i].first * px / SIZE.x, FLIPS[i].second * px / SIZE.y);
            cairo_set_source_surface(CR, SOURCE->cairo(), 0, 0);
            cairo_paint(CR);
            cairo_destroy(CR);
            cairo_surface_flush(SURFACE);
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
