#pragma once

#include <hyprland/src/config/values/types/FloatValue.hpp>
#include <hyprland/src/config/values/types/IntValue.hpp>
#include <hyprland/src/config/values/types/StringValue.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>

inline HANDLE PHANDLE = nullptr;

// plugin:rice_ornaments:*
//   corner    the top-left corner piece, an SVG (or PNG) file; it is
//             mirrored for the other three ("" = off)
//   size      drawn size of each corner piece, logical px
//   reach     how far the frame's outer corner sits from the piece's
//             outer edge (the piece's own (reach, reach) point)
//   inactive  opacity on unfocused windows
struct SVars {
    SP<Config::Values::CStringValue> corner;
    SP<Config::Values::CIntValue>    size;
    SP<Config::Values::CIntValue>    reach;
    SP<Config::Values::CFloatValue>  inactive;
};

inline SVars vars = {};
