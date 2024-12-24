{ pkgs, ... }:

{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  age.secrets = {
    mysql.file = ../secrets/mysql.age;
  };
}
