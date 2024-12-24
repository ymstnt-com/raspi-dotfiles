{ config, ... }:

{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.age.secrets.miniflux.path;
    config = {
      PORT = "3327";
      BASE_URL = "http://localhost/miniflux/";
    };
  };

  age.secrets = {
    miniflux.file = ../secrets/miniflux.age;
  };

  services.nginx.virtualHosts."ymstnt.com".locations = {
    "^~ /miniflux/" = {
      proxyPass = "http://localhost:${config.services.miniflux.config.PORT}/miniflux/";
      recommendedProxySettings = true;
    };
  };

  services.borgmatic.configurations.raspi = {
    postgresql_databases = [
      {
        name = "miniflux";
        username = "postgres";
        password = "";
      }
    ];
  };
}
