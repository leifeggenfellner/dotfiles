{
  nix = {
    settings.substituters = [
      "https://leifeggenfellner.cachix.org"
    ];
    settings.trusted-public-keys = [
      "leifeggenfellner.cachix.org-1:+eB88ym7mLK0BmusC9IXqGNOj4niilnp3EI1T7Yi6fY="
    ];
  };
}
