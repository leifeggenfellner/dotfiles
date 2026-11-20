project('rice_ornaments', 'cpp',
  version: '0.1',
  default_options: ['buildtype=release', 'cpp_std=c++26'],
)

add_project_arguments(['-Wno-narrowing'], language: 'cpp')

shared_module(meson.project_name(),
  ['main.cpp', 'OrnamentDeco.cpp', 'OrnamentPassElement.cpp'],
  dependencies: [
    dependency('hyprland'),
    dependency('pixman-1'),
    dependency('libdrm'),
    dependency('libinput'),
    dependency('libudev'),
    dependency('wayland-server'),
    dependency('xkbcommon'),
    dependency('cairo'),
    dependency('hyprgraphics'),
  ],
  install: true,
)
