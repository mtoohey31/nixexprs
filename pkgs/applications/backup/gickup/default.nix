{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.17";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "tiQmb7bBWb99k23lS+d+YR14y4YeYPWqccl/2DLv7Dk=";
  };
  vendorSha256 = "DWGrs/ZKMKgVfwU7W+dktLELbW9Co7cmDy9pWVP5p2w=";
}
