{
  config,
  lib,
  ...
}:

let
  rootZfsModule =
    with lib.types;
    submodule {
      options = {
        rootPool = lib.mkOptions { type = with lib.types; str; };
        zfsDatasetsList = lib.mkOptions { type = with lib.types; listOf str; };
      };
    };
in
{
  options.blocksmith = {
    enable = lib.mkEnableOption "blocksmith";
    rootZfs = lib.mkOption { type = rootZfsModule; };
  };

  config = lib.mkIf config.blocksmith.enable {
    fileSystems = (
      lib.attrsets.mergeAttrsList (
        builtins.map (dir: {
          ${dir} = {
            device = "${config.blocksmith.rootZfs.rootPool}${dir}";
            fsType = "zfs";
            options = [ "zfsutil" ];
          };
        }) config.blocksmith.rootZfs.zfsDatasetsList
      )
    );
  };
}
