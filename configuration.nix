{ lib, config, pkgs, agenix, ... }:

{
  imports = [
    ./home/gep.nix
    ./home/ymstnt.nix
  ];

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 6 * 1024;
  }];

  console.keyMap = "hu";

  networking = {
    hostName = "raspi-doboz";
    networkmanager.enable = true;
  };

  services.fail2ban.enable = true;

  time.timeZone = "Europe/Budapest";

  services.tailscale = {
    enable = true;
  };

  systemd.tmpfiles.rules = [
    # Type Path                           Mode User   Group   Age Argument
    " d    /var/media                     0755 ymstnt shared"
    " d    /var/media/music               0755 ymstnt shared"
    " d    /var/media/torrents            0755 ymstnt shared"
    " d    /var/media/incomplete-torrents 0755 ymstnt shared"
    " d    /var/media/torrents/Movies     0755 ymstnt shared"
    " d    /var/media/torrents/Shows      0755 ymstnt shared"
    " d    /var/media/torrents/Anime      0755 ymstnt shared"
    " d    /var/media/media-server        0755 ymstnt shared"
    " d    /var/media/media-server/Movies 0755 ymstnt shared"
    " d    /var/media/media-server/Shows  0755 ymstnt shared"
    " d    /var/media/media-server/Anime  0755 ymstnt shared"
    " d    /var/moe                       0750 moe    shared"
    " d    /var/www/ymstnt.com            2770 nginx  shared"
    " d    /var/www/ymstnt.com-generated  0775 shared shared"
  ];

  age.secrets = {
    moe.file = ./secrets/moe.age;
    mysql.file = ./secrets/mysql.age;
    transmission.file = ./secrets/transmission.json.age;
    runner1.file = ./secrets/runner1.age;
    miniflux.file = ./secrets/miniflux.age;
    gotosocial.file = ./secrets/gotosocial.age;
    vikunja.file = ./secrets/vikunja.age;
    borgmatic-raspi.file = ./secrets/borgmatic-raspi.age;
    authelia-jwt = {
      file = ./secrets/authelia-jwt.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    authelia-sekf = {
      file = ./secrets/authelia-sekf.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    authelia-ssf = {
      file = ./secrets/authelia-ssf.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    authelia-hmac = {
      file = ./secrets/authelia-hmac.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    authelia-ipvk = {
      file = ./secrets/authelia-ipvk.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    lldap-jwt = {
      file = ./secrets/lldap-jwt.age;
      mode = "0440";
      group = "lldap";
    };
    lldap-private-key = {
      file = ./secrets/lldap-private-key.age;
      mode = "0440";
      group = "lldap";
    };
    lldap-user-pass = { 
      file = ./secrets/lldap-user-pass.age;
      mode = "0440";
      group = "lldap";
    };
  };

  services.avahi.enable = true;

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "ymstnt";
    group = "shared";
  };

  services.transmission = {
    user = "ymstnt";
    group = "shared";
    enable = true;
    openRPCPort = true;
    openPeerPorts = true;
    settings = {
      download-dir = "/var/media/torrents";
      incomplete-dir = "/var/media/incomplete-torrents";
      rpc-enabled = true;
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = true;
      rpc-authentication-required = true;
      rpc-username = "ymstnt";
      rpc-whitelist = "127.0.0.1,192.168.*.*,100.*.*.*";
      rpc-bind-address = "0.0.0.0";
      umask = 18;
      ratio-limit = 1;
      ratio-limit-enabled = true;
    };
    credentialsFile = config.age.secrets.transmission.path;
  };

  services.github-runners = {
    website = {
      enable = true;
      replace = true;
      user = "shared";
      url = "https://github.com/ymstnt/ymstnt.com";
      tokenFile = config.age.secrets.runner1.path;
      extraPackages = with pkgs; [
        nodejs_20
      ];
      nodeRuntimes = [ "node20" ];
      serviceOverrides = {
        ReadWritePaths = [ "/var/www/ymstnt.com-generated" ];
      };
    };
  };

  services.ntfy-sh = {
    enable = true;
    group = "shared";
    settings = {
      base-url = "https://ntfy.ymstnt.com";
      behind-proxy = true;
      web-root = "disable";
    };
  };

  services.phpfpm.pools.shared = {
    user = "shared";
    settings = {
      pm = "dynamic";
      "listen.owner" = config.services.nginx.user;
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "security.limit_extensions" = ".php .html";
    };
    phpOptions = ''
      upload_max_filesize = 50G
      post_max_size = 50G
    '';
    phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
  };

  services.nginx = {
    enable = true;
    group = "shared";
    appendConfig = ''
      error_log /var/log/nginx/error.log debug;
    '';
    virtualHosts =
      let
        autheliaVirtualHostConfig = ''
          # Basic Authelia Config
          # Verify user authentication and permission.
          auth_request /authelia;
          # Set the `target_url` variable based on the request. It will be used to build the portal
          # URL with the correct redirection parameter.
          auth_request_set $target_url $scheme://$http_host$request_uri;
          # Set the X-Forwarded-User and X-Forwarded-Groups with the headers
          # returned by Authelia for the backends which can consume them.
          # This is not safe, as the backend must make sure that they come from the
          # proxy. In the future, it's gonna be safe to just use OAuth.
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $groups $upstream_http_remote_groups;
          auth_request_set $name $upstream_http_remote_name;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Groups $groups;
          proxy_set_header Remote-Name $name;
          proxy_set_header Remote-Email $email;
          # Authelia -> 401, -> redirect: login portal
          # Authelia -> 200 -> request pass through
          error_page 401 =302 https://auth.ymstnt.com/?rd=$target_url;
        '';
        autheliaLocationConfig = ''
          internal;
          set $upstream_authelia http://127.0.0.1:9091/api/verify;
          proxy_pass_request_body off;
          proxy_pass $upstream_authelia;    
          proxy_set_header Content-Length "";

          # Timeout if the real server is dead
          proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

          # [REQUIRED] Needed by Authelia to check authorizations of the resource.
          # Provide either X-Original-URL and X-Forwarded-Proto or
          # X-Forwarded-Proto, X-Forwarded-Host and X-Forwarded-Uri or both.
          # Those headers will be used by Authelia to deduce the target url of the     user.
          # Basic Proxy Config
          client_body_buffer_size 128k;
          proxy_set_header Host $host;
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $remote_addr; 
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $http_host;
          proxy_set_header X-Forwarded-Uri $request_uri;
          proxy_set_header X-Forwarded-Ssl on;
          proxy_redirect  http://  $scheme://;
          proxy_http_version 1.1;
          proxy_set_header Connection "";
          proxy_cache_bypass $cookie_session;
          proxy_no_cache $cookie_session;
          proxy_buffers 4 32k;

          # Advanced Proxy Config
          send_timeout 5m;
          proxy_read_timeout 240;
          proxy_send_timeout 240;
          proxy_connect_timeout 240;
        '';
      in
      {
      "ymstnt.com" = {
        enableACME = true;
        forceSSL = true;
        root = "/var/www";
        extraConfig = ''
          error_page 404 /ymstnt.com-generated/404.html;
          client_max_body_size 50G;
          fastcgi_read_timeout 24h;
        '';
        locations = { 
          "~ ^([^.\?]*[^/])$".extraConfig = ''
            if (-d $document_root/ymstnt.com-generated$uri) {
              rewrite ^([^.]*[^/])$ $1/ permanent;
            }
            if (-d $document_root/ymstnt.com$uri) {
              rewrite ^([^.]*[^/])$ $1/ permanent;
            }
            try_files _ @entry;
          '';
          "/".extraConfig = ''
            try_files _ @entry;
          '';
          "@entry".extraConfig = ''
            try_files /ymstnt.com-generated$uri /ymstnt.com-generated$uri/index.html @ymstnt.com-rewrite;
          '';
          "@ymstnt.com-rewrite".extraConfig = ''
            if (-f $document_root/ymstnt.com$uri) {
              rewrite ^(.*)$ /ymstnt.com$1 last;
            }
            if (-f $document_root/ymstnt.com$uri/index.html) {
              rewrite ^(.*)$ /ymstnt.com$1/index.html last;
            }
            if (-f $document_root/ymstnt.com$uri/index.php) {
              rewrite ^(.*)$ /ymstnt.com$1/index.php last;
            }
          '';
          "/ymstnt.com/".extraConfig = ''
            alias /var/www/ymstnt.com/;
            location ~ \.(php|html)$ {
              alias /var/www;
              fastcgi_pass unix:${config.services.phpfpm.pools.shared.socket};
            }
          '';
          "/\.git".extraConfig = ''
            deny all;
          '';
          "/.well-known/webfinger".extraConfig = ''
            rewrite ^.*$ https://social.ymstnt.com/.well-known/webfinger permanent;
          '';
          "/.well-known/host-meta".extraConfig = ''
            rewrite ^.*$ https://social.ymstnt.com/.well-known/host-meta permanent;
          '';
          "/.well-known/nodeinfo".extraConfig = ''
            rewrite ^.*$ https://social.ymstnt.com/.well-known/nodeinfo permanent;
          '';
          "^~ /miniflux/" = {
            proxyPass = "http://localhost:${config.services.miniflux.config.PORT}/miniflux/";
            recommendedProxySettings = true;
          };
        };
      };
      "social.ymstnt.com" = {
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
      "tasks.ymstnt.com" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/" = {
            proxyPass = "${config.services.vikunja.frontendScheme}://${config.services.vikunja.frontendHostname}:${toString config.services.vikunja.port}";
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 20M; # Change accordingly to Vikunja's upload size
            '';
          };
        };
      };
      "ntfy.ymstnt.com" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/" = {
            proxyPass = "http://${toString config.services.ntfy-sh.settings.listen-http}";
            recommendedProxySettings = true;
            proxyWebsockets = true;
          };
        };
      };
      "auth.ymstnt.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
          proxyWebsockets = true;
        };
     };
    };
  };

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets.authelia-jwt.path;
      storageEncryptionKeyFile = config.age.secrets.authelia-sekf.path;
      sessionSecretFile = config.age.secrets.authelia-ssf.path;
      # oidcHmacSecretFile = config.age.secrets.authelia-hmac.path;
      # oidcIssuerPrivateKeyFile = config.age.secrets.authelia-ipvk.path;
    };
    settings = {
      theme = "auto";
      default_2fa_method = "totp";
      server = {
        host = "localhost";
      };
      log.level = "info";
      regulation = {
        max_retries = 3;
        find_time = 120;
        ban_time = 300;
      };
      totp.issuer = "authelia.com";
      authentication_backend = {
        password_reset.disable = false;
        refresh_interval = "1m";
        ldap = {
          implementation = "custom";
          url = "ldap://localhost:3890";
          timeout = "5m";
          start_tls = false;
          base_dn = "dc=ymstnt,dc=com";
          username_attribute = "uid";
          additional_users_dn = "people";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          #additional_groupd_dn = "ou=groups";
          groups_filter = "(member={dn})";
          group_name_attribute = "cn";
          mail_attribute = "mail";
          display_name_attribute = "displayName";
          user = "uid=admin,ou=people,dc=ymstnt,dc=com";
          password = config.age.secrets.lldap-user-pass.path;
        };
      };
      access_control = {
        default_policy = "deny";
        networks = [
          {
            name = "localhost";
            networks = [ "127.0.0.1/32" ];
          }
          {
            name = "internal";
            networks = [
              "192.168.0.0/24"
            ];
          }
        ];
        rules = [
          {
            domain = "auth.ymstnt.com";
            policy = "bypass";
          }
          {
            domain = "ymstnt.com";
            policy = "bypass";
          }
        ];
      };
      session = {
        name = "authelia_session";
        expiration = "12h";
        inactivity = "45m";
        remember_me_duration = "1M";
        domain = "ymstnt.com";
      };
      storage = {
        local = {
          path = "/var/lib/authelia-main/db.sqlite3";
        };
      };
      notifier = {
        disable_startup_check = false;
        filesystem = {
          filename = "/var/lib/authelia-main/notifications.txt";
        };
      };
    };
  };

  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "dc=ymstnt,dc=com";
      ldap_user_email = "admin@ymstnt.com";
    };
    environment = {
      LLDAP_JWT_SECRET_FILE = config.age.secrets.lldap-jwt.path;
      LLDAP_KEY_SEED_FILE = config.age.secrets.lldap-private-key.path;
      LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.lldap-user-pass.path;
    };
  };

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.age.secrets.miniflux.path;
    config = {
      PORT = "3327";
      BASE_URL = "http://localhost/miniflux/";
    };
  };

  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "127.0.0.1";
    settings = {
      service = {
        timezone = "Europe/Budapest";
        publicurl = "https://tasks.ymstnt.com";
      };
      migration = {
        trello = {
          enable = true;
        };
      };
      mailer = {
        enabled = true;
        host = "smtp.eu.mailgun.org";
        port = 465;
        authtype = "login";
        forcessl = true;
      };
    };
    environmentFiles = [
      config.age.secrets.vikunja.path
    ]; 
  };

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

  security.acme = {
    acceptTerms = true;
    defaults.email = "ymstnt@mailbox.org";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 17170 ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  services.postgresql = {
    enable = true;
    authentication = ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };

  systemd.services.borgmatic = {
    path = with pkgs; [
      postgresql
      sqlite
    ];
  };
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
        postgresql_databases = [
          {
            name = "miniflux";
            username = "postgres";
            password = "";
          }
        ];
        sqlite_databases = [
          {
            name = "moe";
            path = "/var/moe/storage.db";
          }
          {
            name = "gotosocial";
            path = "/var/lib/gotosocial/database.sqlite";
          }
          {
            name = "vikunja";
            path = "/var/lib/vikunja/vikunja.db";
          }
        ];
        source_directories = [
          "/var/lib/vikunja/files"
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
            frequency = "weekly";
            only_run_on = [
              "Sunday"
            ];
          }
          {
            name = "archives";
            frequency = "weekly";
            only_run_on = [
              "Sunday"
            ];
          }
        ];
      };
    };
  };

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

  environment.shellInit = "umask 002";
  users.users = {
    shared = {
      isSystemUser = true;
      group = "shared";
    };
    borgmatic = {
      isSystemUser = true;
      group = "shared";
    };
    lldap = {
      isSystemUser = true;
      group = "lldap";
      extraGroups = [
        "shared"
      ];
    };
  };

  users.groups = {
    shared = { };
    lldap = { };
  };

  moe = {
    enable = true;
    group = "shared";
    openFirewall = true;
    settings = {
      status-port = 25571;
    };
    credentialsFile = config.age.secrets.moe.path;
  };

  environment.systemPackages = with pkgs; [
    git
    gotosocial
    inotify-tools
    ncdu
    nh
    nix-inspect
    nix-output-monitor
    nvd
    agenix.packages.${pkgs.system}.default
  ];

  # TODO: remove after issue is fixed https://github.com/NixOS/nixpkgs/issues/180175
  #systemd.services.tailscaled.after = ["NetworkManager-wait-online.service"];
  systemd.services.NetworkManager-wait-online.enable = false;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
  ];

  nix.settings.trusted-users = [ "gep" "ymstnt" ];

  home-manager.useGlobalPkgs = true;
}
