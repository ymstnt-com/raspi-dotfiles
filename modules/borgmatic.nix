{ config, pkgs, ... }:

{
  services.borgmatic = {
    enable = true;
    configurations = {
      "raspi" = {
        repositories = [
          {
            label = "borgmatic";
            path = "ssh://khrfjql1@khrfjql1.repo.borgbase.com/./repo";
          }
        ];
        exclude_patterns = [
          "*cache*"
          "*Cache*"
          "*.tmp"
          "*.log"
        ];
        exclude_if_present = [
          ".nobackup"
        ];
        encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.borgmatic-raspi.path}";
        ssh_command = "${pkgs.openssh}/bin/ssh -i /etc/ssh/borg";
        relocated_repo_access_is_ok = true;
        compression = "auto,zstd";
        archive_name_format = "{hostname}-{now:%Y-%m-%d-%H%M%S}";
        retries = 5;
        retry_wait = 30;
        keep_hourly = 1;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        checks = [
          {
            name = "repository";
            frequency = "1 week";
            only_run_on = [
              "Sunday"
            ];
          }
          {
            name = "archives";
            frequency = "1 week";
            only_run_on = [
              "Sunday"
            ];
          }
        ];
      };
    };
  };

  systemd.services.borgmatic = {
    path = with pkgs; [
      postgresql
      sqlite
    ];
  };

  age.secrets = {
    borgmatic-raspi.file = ../secrets/borgmatic-raspi.age;
  };

  users.users.borgmatic = {
    isSystemUser = true;
    group = "shared";
  };
}
