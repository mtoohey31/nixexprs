{ archiver }:

archiver.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./Revert-Add-support-for-wildcard-characters-for-archi.patch
  ];
})
