{ exa }:

exa.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./0001-Replace-obsolete-icons.patch
  ];
})
