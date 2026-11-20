#pragma once

#define WLR_USE_UNSTABLE

#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/render/WindowRenderPresentation.hpp>

// Corner pieces drawn over a window's frame, in its render pass, at its
// animated position: they move with every frame of a window animation,
// a drag or a resize. Absolute positioning, so no space is reserved.
class COrnamentDeco : public IHyprWindowDecoration {
  public:
    COrnamentDeco(PHLWINDOW);
    virtual ~COrnamentDeco();

    virtual SDecorationPositioningInfo getPositioningInfo() override;
    virtual void                       onPositioningReply(const SDecorationPositioningReply& reply) override;
    virtual void                       draw(Render::CRenderContext& ctx, PHLMONITOR, float const& a, const Render::SWindowRenderPresentation& presentation) override;
    virtual eDecorationType            getDecorationType() override;
    virtual void                       updateWindow(PHLWINDOW) override;
    virtual void                       damageEntire() override;
    virtual eDecorationLayer           getDecorationLayer() override;
    virtual uint64_t                   getDecorationFlags() override;
    virtual std::string                getDisplayName() override;
    virtual void                       onWindowFocus() override;

    void                               drawPass(Render::CRenderContext& ctx, PHLMONITOR, float a, const Render::SWindowRenderPresentation& presentation);

  private:
    double       outset() const;

    PHLWINDOWREF m_window;
    Vector2D     m_lastPos;
    Vector2D     m_lastSize;
};
