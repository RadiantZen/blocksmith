{ config, lib, ... }:

let
  rootZfsModule =
    with lib.types;
    submodule {
      options = {
        rootPool = lib.mkOption { type = with lib.types; str; };
        rootPrefixDataset = lib.mkOption { type = with lib.types; str; };
        zfsDatasetList = lib.mkOption { type = with lib.types; listOf str; };
        persistentDatasets = lib.mkOption { type = with lib.types; listOf str; };
      };
    };
in
{
  options.blocksmith = {
    enable = lib.mkEnableOption "blocksmith";
    rootZfs = lib.mkOption { type = rootZfsModule; };
  };

  config = lib.mkIf config.blocksmith.enable {
    boot.initrd.systemd.services.rollback = {
      name = "rollback.zfs.root";
      description = "Rollback ZFS datasets to a pristine state";
      wantedBy = [ "initrd.target" ];
      after = [ "zfs-import-${config.blocksmith.rootZfs.rootPool}.service" ];
      before = [ "sysroot.mount" ];
      path = [ config.boot.zfs.package ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        zfs rollback -r ${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPrefixDataset}/root@blank && echo "rollback: /"
        zfs rollback -r ${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPrefixDataset}/etc@blank && echo "rollback: /etc"
        zfs rollback -r ${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPrefixDataset}/tmp@blank && echo "rollback: /tmp"
        zfs rollback -r ${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPrefixDataset}/var@blank && echo "rollback: /var"
        zfs rollback -r ${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPrefixDataset}/var/lib@blank && echo "rollback: /var/lib"

        echo ">> >> rollback complete << <<"
      '';
    };

    fileSystems =
      lib.mergeAttrs
        {
          "/" = {
            device = "${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPrefixDataset}/root";
            fsType = "zfs";
            options = [ "zfsutil" ];
          };
        }
        (
          lib.mergeAttrs
            (lib.attrsets.mergeAttrsList (
              builtins.map (dir: {
                ${dir} = {
                  device = "${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPool}${dir}";
                  fsType = "zfs";
                  options = [ "zfsutil" ];
                };
              }) config.blocksmith.rootZfs.zfsDatasetList
            ))
            (
              lib.attrsets.mergeAttrsList (
                builtins.map (dir: {
                  ${dir} = {
                    device = "${config.blocksmith.rootZfs.rootPool}/${config.blocksmith.rootZfs.rootPool}${dir}";
                    fsType = "zfs";
                    options = [ "zfsutil" ];
                    neededForBoot = true;
                  };
                }) config.blocksmith.rootZfs.persistentDatasets
              )
            )
        );
  };
}
