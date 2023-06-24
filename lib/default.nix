lib: {
  callModules = { moduleListPath, inputs, selfName }:
    let
      inputsWithRenamedSelf =
        builtins.removeAttrs inputs [ "self" ] // { ${selfName} = inputs.self; };
      fromModulePath = modulePath: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf modulePath);
        # TODO: create a function that requires all the arguments of the inner
        # module so that it gets everything it asks for even if the caller is
        # using custom module inputs via another mechanism too
        value = { config, lib, pkgs, ... }@moduleInputs:
          import modulePath (
            inputsWithRenamedSelf //
            { inherit config lib pkgs; } // # this is here to please deadnix
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
