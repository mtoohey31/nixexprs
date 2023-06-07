lib:
{
  filterSupportedPackages = system:
    lib.filterAttrs (_: pkg:
      let
        hasMeta = pkg ? "meta";
        hasPlatforms = pkg.meta ? "platforms";
        containsSystem = lib.any (other: other == system) pkg.meta.platforms;
      in
      !hasMeta || !hasPlatforms || containsSystem);
}
