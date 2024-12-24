# Read all files and folders in the current directory and return an attrset containing the modules
# A utility function to import everything except some specified modules is also included
# Example output:
# {
#   moe = import /nix/store/xxxx-source/modules/moe.nix;
#   miniflux = import /nix/store/xxxx-source/modules/miniflux.nix;
#   allModulesExcept = <LAMBDA [ "transmission" ] -> [ import .../moe ]>;
# }

let
  modulesDir = builtins.toString ./.;

  filesAndDirectories = builtins.attrNames (
    builtins.removeAttrs (builtins.readDir modulesDir) [ "default.nix" ]
  );

  allModules = builtins.listToAttrs (
    map (name: {
      name = builtins.replaceStrings [ ".nix" ] [ "" ] name;
      value = import "${modulesDir}/${name}";
    }) filesAndDirectories
  );

  allModulesExcept = exceptions: builtins.attrValues (builtins.removeAttrs allModules exceptions);
in
allModules
// {
  inherit allModulesExcept;
}
