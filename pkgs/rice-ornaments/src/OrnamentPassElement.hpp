#pragma once

#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/render/WindowRenderPresentation.hpp>

class COrnamentDeco;

class COrnamentPassElement : public IPassElement {
  public:
    struct SData {
        COrnamentDeco*                    deco = nullptr;
        float                             a    = 1.F;
        Render::SWindowRenderPresentation presentation;
    };

    COrnamentPassElement(const SData& data);
    virtual ~COrnamentPassElement() = default;

    virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override;
    virtual bool                          needsLiveBlur(Render::CRenderContext& ctx) override;
    virtual bool                          needsPrecomputeBlur(Render::CRenderContext& ctx) override;

    virtual const char*                   passName() override {
        return "COrnamentPassElement";
    }

    virtual ePassElementType type() override {
        return EK_CUSTOM;
    }

  private:
    SData m_data;
};
