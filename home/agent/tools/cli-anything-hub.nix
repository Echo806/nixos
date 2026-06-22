{ lib
, python3Packages
, fetchurl
}:

python3Packages.buildPythonApplication rec {
  pname = "cli-anything-hub";
  version = "0.3.0";
  pyproject = true;

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/64/1d/bee957acb19850d175ff3b2c48344ebc0678071b20d5ca1bf013b09d78a1/cli_anything_hub-0.3.0.tar.gz";
    hash = "sha256-d60dHprp+oCnkdG1R6/dN4Z8xBJJiOH6vNOALkysOR8=";
  };

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    click
    requests
  ];

  pythonImportsCheck = [ "cli_hub" ];

  meta = {
    description = "Package manager for CLI-Anything agent-friendly CLI harnesses";
    homepage = "https://clianything.cc";
    license = lib.licenses.mit;
    mainProgram = "cli-hub";
    platforms = lib.platforms.unix;
  };
}
