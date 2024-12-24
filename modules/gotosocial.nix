{ config, pkgs, ... }:

{
  services.gotosocial = {
    enable = true;
    settings = {
      bind-address = "127.0.0.1";
      port = 3333;
      host = "social.ymstnt.com";
      account-domain = "ymstnt.com";
      db-type = "sqlite";
      db-address = "/var/lib/gotosocial/database.sqlite";
      protocol = "https";
      storage-local-base-path = "/var/lib/gotosocial/storage";
    };
    environmentFile = config.age.secrets.gotosocial.path;
  };

  age.secrets = {
    gotosocial.file = ../secrets/gotosocial.age;
  };

  services.nginx.virtualHosts."social.ymstnt.com" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.gotosocial.settings.port}";

        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 40M;
        '';
      };
    };
  };

  services.nginx.virtualHosts."ymstnt.com".locations = {
    "/.well-known/webfinger".extraConfig = ''
      rewrite ^.*$ https://social.ymstnt.com/.well-known/webfinger permanent;
    '';
    "/.well-known/host-meta".extraConfig = ''
      rewrite ^.*$ https://social.ymstnt.com/.well-known/host-meta permanent;
    '';
    "/.well-known/nodeinfo".extraConfig = ''
      rewrite ^.*$ https://social.ymstnt.com/.well-known/nodeinfo permanent;
    '';
  };

  services.borgmatic.configurations.raspi = {
    sqlite_databases = [
      {
        name = "gotosocial";
        path = "/var/lib/gotosocial/database.sqlite";
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    gotosocial
  ];
}
