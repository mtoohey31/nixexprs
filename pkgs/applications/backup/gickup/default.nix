{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.27";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "ExSTvIq5u5Zmep/tipAJOHcXMxtESLQlEVMWnD8/rSI=";
  };
  vendorHash = "sha256-riRFDhVOMdqwgGd6wowSDNgt8lZPzagCvKPWTHSqm6U=";
}
