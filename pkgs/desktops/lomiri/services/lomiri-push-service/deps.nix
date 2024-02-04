[
  # 1:1 translations from depenencies.tsv
  {
    goPackagePath = "github.com/mattn/go-sqlite3";
    fetch = {
      type = "git";
      url = "https://github.com/mattn/go-sqlite3";
      rev = "4b0af852c17164dce48e6754e3094c55192e4934";
      sha256 = "sha256-UzhJnZ49GUpSCueih0o9eNea4o6qVwHOkFhz1KJJq+M=";
    };
  }
  {
    goPackagePath = "github.com/pborman/uuid";
    fetch = {
      type = "git";
      url = "https://github.com/pborman/uuid";
      rev = "b984ec7fa9ff9e428bd0cf0abf429384dfbe3e37";
      sha256 = "sha256-23cJXQXk6lmBxUT+1TdAfSFQYMqnDj4idrjSPwHrlng=";
    };
  }
  {
    goPackagePath = "launchpad.net/go-dbus/v1";
    fetch = {
      type = "bzr";
      url = "https://launchpad.net/go-dbus/v1";
      rev = "129";
      sha256 = "sha256-o2Bw3ZtG/IhBKObef1z+SrSXewGNd4eqwpO5g6tZkx8=";
    };
  }
  {
    goPackagePath = "launchpad.net/go-xdg/v0";
    fetch = {
      type = "bzr";
      url = "https://launchpad.net/go-xdg/v0";
      rev = "10";
      sha256 = "sha256-zpzbhiKgbHiQmX/jwJBr+PclTNL+WqvetUr23+dEpjk=";
    };
  }

  # Fetching from GitHub instead, gopkg.in doesn't seem to work for bzr
  # Revision matches the date of the original bzr rev
  {
    goPackagePath = "gopkg.in/check.v1";
    fetch = {
      type = "git";
      url = "https://github.com/go-check/check";
      rev = "eb6ee6f84d0a848c7f11b46cd11f28875ba56b1c";
      sha256 = "sha256-2wLlKETI2vt2dDtbKa2QBHmRQiwCmFMC0GuPG3Yng10=";
    };
  }

  # Fetched via Debian packaging
  # Intended revision predates first version, but not pinned since pulled via Debian package
  # Just picking latest version, since upstream doesn't bother with explicitly pinning this
  {
    goPackagePath = "golang.org/x/net";
    fetch = {
      type = "git";
      url = "https://go.googlesource.com/net";
      rev = "v0.20.0";
      sha256 = "sha256-PCttIsWSBQd6fDXL49jepszUAMLnAGAKR//5EDO3XDk=";
    };
  }
]
