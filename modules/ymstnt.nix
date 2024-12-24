{ config, lib, ymstnt-dotfiles, ... }:

{
  imports = with ymstnt-dotfiles.nixosModules; [
    cli
    hm
    helix
    micro
    starship
    zsh
    git
  ];
  
  users.users.ymstnt = {
    initialPassword = "ymstnt";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "shared"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLWg7uXAd3GfBmXV5b9iLp+EZ9rfu+gRWWCb8YXML4o u0_a557@localhost"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVor+g/31/XFIzuZYQrNK/RIbU1iDaSyOfM8re73eAd ymstnt@cassiopeia"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGx6TyqDxyb74F0rjyCu/9z4QO2pX6tmJdb3m62QrQrg ymstnt@cassiopeia-win"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVxinYyV/gDhWNeSa0LD6kRKwTWhFxXVS23axGO/2sa ymstnt@andromeda"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKV37wsI1w67r267Tq1J4qGlym2eTdcOBs6jtlUpu3UJ ymstnt@andromeda-win"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLQKmZDSyZvpXqaqLigdrQEJzrcu4ry0zGydZipliPZ u0_a293@localhost"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRh9g9ZttYswCxdIE7KYL3xs4JZqhDCUc5BYjDMxFph u0_a355@localhost"
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAuZLBwbD5ZkDy70jKmOPrmtPtqLAddpjFDWS8mTfF/CdFAIwgoU/tMTxIKSx0PRjUqXzcO9JhvI+9/QeswBw27PAFBdmBmMKiJqbrZEPZv3ecL/Qd6KGAsB2GGGWTF82+gL5Vb1Sm3cjJnQUBGJoIz6tam5Ya5VRUUXxe1X52uS70mhA== u0_a355@localhost"
    ];
  };

  home-manager.users.ymstnt = {
    programs.bash = {
      enable = true;
      shellAliases = {
        rebuild = "nh os switch ~/raspi-dotfiles -- --impure";
        update = "(cd $HOME/raspi-dotfiles && nix flake update --commit-lock-file)";
        dotcd = "cd $HOME/raspi-dotfiles";
        bashreload = "source $HOME/.bashrc";
        nrebuild = "(cd $HOME/raspi-dotfiles && sudo nixos-rebuild switch --flake . --impure)";
      };
    };
    programs.zsh = {
      shellAliases = {
        update = lib.mkForce "(cd $HOME/raspi-dotfiles && nix flake update --commit-lock-file)";
        rebuild = lib.mkForce "nh os switch $HOME/raspi-dotfiles -- --impure";
        dotcd = lib.mkForce "cd $HOME/raspi-dotfiles";
        nrebuild = lib.mkForce "(cd $HOME/raspi-dotfiles && sudo nixos-rebuild switch --flake . --impure)";
      };
      sessionVariables = {
        COLORTERM = "truecolor"; # needed for helix themes
      };
    };
    programs.starship = {
      settings = {
        format = lib.mkForce "[](\#AF083A)\$os\$username\[](bg:\#D50A47 fg:\#AF083A)\$directory\[](bg:\#F41C5D fg:\#D50A47)\$git_branch\$git_status\[](bg:\#F75787 fg:\#F41C5D)\$cmd_duration[ ](fg:\#F75787)";

        username = {
          style_user = lib.mkForce "bg:\#AF083A";
          style_root = lib.mkForce "bg:\#AF083A";
        };

        os = {
          format = lib.mkForce "[ ]($style)";
          style = lib.mkForce "bg:\#AF083A";
        };

        directory = {
          style = lib.mkForce "bg:\#D50A47";
        };

        git_branch = {
          style = lib.mkForce "bg:\#F41C5D";
        };

        git_status = {
          style = lib.mkForce "bg:\#F41C5D";
        };

        cmd_duration = {
          style = lib.mkForce "bg:\#F75787";
        };
      };
    };
    
    home.stateVersion = config.system.stateVersion;
  };
}
