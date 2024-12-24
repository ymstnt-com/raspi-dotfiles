{ config, ... }:

{
  moe = {
    enable = true;
    group = "shared";
    openFirewall = true;
    settings = {
      status-port = 25571;
    };
    credentialsFile = config.age.secrets.moe.path;
  };

  age.secrets = {
    moe.file = ../secrets/moe.age;
  };

  systemd.tmpfiles.rules = [
    # Type Path                           Mode User   Group   Age Argument
    " d    /var/moe                       0750 moe    shared"
  ];

  services.borgmatic.configurations.raspi = {
    sqlite_databases = [
      {
        name = "moe";
        path = "/var/moe/storage.db";
      }
    ];
  };
}
