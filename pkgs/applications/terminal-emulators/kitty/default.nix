{ kitty }:

kitty.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./0001-Enable-E3-terminfo-capability-to-properly-clear-scro.patch
    ./0001-Increase-fallback-fonts-limit.patch
  ];
  # regenerate terminfo stuff based on the patch; we could include the updated
  # generated files in the patch, but then the patch won't apply as soon as any
  # upstream changes get made
  postBuild = (oldAttrs.postBuild or "") + ''
    python3 build-terminfo
  '';
})
