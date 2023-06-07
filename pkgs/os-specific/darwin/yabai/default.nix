{ yabai }:

yabai.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [ ./0001-mouse-follows-swap.patch ];
})
