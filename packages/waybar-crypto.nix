{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "waybar-crypto";
  version = "1.6.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "chadsr";
    repo = "waybar-crypto";
    rev = "v${version}";
    hash = "sha256-YvIyhnQkoyUelWCr4T0XXlsQe+6Mw7VS3I19ImhQqSA=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = [ python3Packages.requests ];

  meta = {
    description = "Waybar module for displaying cryptocurrency market information from CoinMarketCap";
    homepage = "https://github.com/chadsr/waybar-crypto";
    license = lib.licenses.mit;
    mainProgram = "waybar-crypto";
  };
}
