#include "OrnamentPassElement.hpp"
#include <hyprland/src/render/Renderer.hpp>
#include "OrnamentDeco.hpp"

COrnamentPassElement::COrnamentPassElement(const SData& data) : m_data(data) {
    ;
}

std::vector<UP<IPassElement>> COrnamentPassElement::draw(Render::CRenderContext& ctx) {
    m_data.deco->drawPass(ctx, ctx.m_data.pMonitor.lock(), m_data.a, m_data.presentation);
    return {};
}

bool COrnamentPassElement::needsLiveBlur(Render::CRenderContext&) {
    return false;
}

bool COrnamentPassElement::needsPrecomputeBlur(Render::CRenderContext&) {
    return false;
}
