lib: {
  callModules = { moduleListPath, inputs, selfName }:
    let
      inputsWithRenamedSelf =
        builtins.removeAttrs inputs [ "self" ] // { ${selfName} = inputs.self; };
      fromModulePath = modulePath: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf modulePath);
        # deadnix: skip
        value = { config, lib, pkgs, ... }@moduleInputs:
          import modulePath (
            inputsWithRenamedSelf //
            moduleInputs
          );
      };
      moduleList = map fromModulePath (import moduleListPath);
    in
    builtins.listToAttrs moduleList;

  filterSupportedPackages = system:
    lib.filterAttrs (_: pkg:
      let
        hasMeta = pkg ? "meta";
        hasPlatforms = pkg.meta ? "platforms";
        containsSystem = lib.any (other: other == system) pkg.meta.platforms;
      in
      !hasMeta || !hasPlatforms || containsSystem);
}
