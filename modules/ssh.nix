{ ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 42727 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };
}
