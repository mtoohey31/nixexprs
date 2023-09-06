{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.18";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "9qaGPmrBA/VdXF9D4eSfjZ3xYBSbPKpwG9t2q37sq3I=";
  };
  vendorSha256 = "uDZCeIdyx60XJ3Cu2M4HocfDysOu5Edp81/eUf45NcE=";
}
