{ config, gep-dotfiles, pkgs, ... }:

{
  imports = with gep-dotfiles.nixosModules; [
    atuin
    bottom
    chatgpt
    clac
    cli
    git
    hm
    lf
    lsp
    nix
    nvim
    sdk
    starship
    tmux
    zoxide
    zsh
  ];

  age.secrets = {
    openai-token.file = ../secrets/openai-token-gep.age;
  };

  hm-gep.home = {
    sessionVariables = {
      FLAKE = "${config.hm-gep.home.homeDirectory}/raspi-dotfiles";
    };
    packages = with pkgs; [
      nh
    ];
  };

  hm-gep.services.ssh-agent = {
    enable = true;
  };

  users.users.gep = {
    initialPassword = "gep";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "shared"
    ];
    openssh.authorizedKeys.keys = [
      # geptop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDPWyW2tBcCORf4C/Z7iPaKGoiswyLdds3m8ZrNY8OXl gutyina.gergo.2@gmail.com"
      # geppc
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKGW5zKjn01DVf6vTs/D2VV+/awXTNboY1iaCThi2A1v gep@geppc"
      # gepphone
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQXysKutq2b67RAmq46qMH8TDLEYf0D5SYon4vE6efO u0_a483@localhost"
    ];
  };
}
