{ inputs, ... }:
{
  # Re-export nixpkgs+home-manager lib for convenience
  flake.lib = inputs.nixpkgs.lib // inputs.home-manager.lib;
}
