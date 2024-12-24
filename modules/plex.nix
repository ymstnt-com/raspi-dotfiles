{ ... }:

{
  services.plex = {
    enable = true;
    openFirewall = true;
    user = "ymstnt";
    group = "shared";
  };
}
