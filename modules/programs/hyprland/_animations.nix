# Baseline Hyprland curves and animations. Imported by _settings.nix
# (the generated config) and by the rice Hyprland adapter, which
# re-applies these leaves before a theme's overrides so switching to a
# theme without compositor motion restores them exactly (D-047).
{
  curve = [
    { _args = [ "wind" { type = "bezier"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; } ]; }
    { _args = [ "winIn" { type = "bezier"; points = [ [ 0.1 1.1 ] [ 0.1 1.1 ] ]; } ]; }
    { _args = [ "winOut" { type = "bezier"; points = [ [ 0.3 (-0.3) ] [ 0 1 ] ]; } ]; }
    { _args = [ "liner" { type = "bezier"; points = [ [ 1 1 ] [ 1 1 ] ]; } ]; }
    { _args = [ "overshot" { type = "bezier"; points = [ [ 0.13 0.99 ] [ 0.29 1.1 ] ]; } ]; }
  ];

  animation = [
    { leaf = "windows"; enabled = true; speed = 6; bezier = "wind"; style = "slide"; }
    { leaf = "windowsIn"; enabled = true; speed = 6; bezier = "winIn"; style = "slide"; }
    { leaf = "windowsOut"; enabled = true; speed = 5; bezier = "winOut"; style = "slide"; }
    { leaf = "windowsMove"; enabled = true; speed = 5; bezier = "wind"; style = "slide"; }
    { leaf = "border"; enabled = true; speed = 10; bezier = "liner"; }
    { leaf = "fade"; enabled = true; speed = 10; bezier = "default"; }
    { leaf = "layers"; enabled = true; speed = 4; bezier = "wind"; style = "slide"; }
    { leaf = "layersIn"; enabled = true; speed = 4; bezier = "winIn"; style = "slide"; }
    { leaf = "layersOut"; enabled = true; speed = 3; bezier = "winOut"; style = "fade"; }
    { leaf = "workspaces"; enabled = true; speed = 6; bezier = "overshot"; style = "slidevert"; }
    { leaf = "specialWorkspace"; enabled = true; speed = 6; bezier = "default"; style = "slidevert"; }
  ];
}
