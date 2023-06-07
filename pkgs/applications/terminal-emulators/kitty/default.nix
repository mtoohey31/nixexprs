{ kitty }:

kitty.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./0001-Revert-Use-actual-color-value-comparison-when-detect.patch
    ./0001-Add-E3-terminfo-capability-to-properly-clear-scrollb.patch
  ];
  # regenerate terminfo stuff based on the patch; we could include the updated
  # generated files in the patch, but then the patch won't apply as soon as any
  # upstream changes get made
  postPatch = (oldAttrs.postPatch or "") + ''
    python3 build-terminfo
  '';
})
