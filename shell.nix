let
  pkgs = import <nixpkgs> { };
in
with pkgs;
let
  pythonWithPackages = python3.withPackages (
    ps: with ps; [
      black
      flake8
      graphviz
      numpy
      z3
    ]
  );
  binName = "python";

  PROJECT_ROOT = builtins.getEnv "PWD";

  curl = ''${pkgs.curl}/bin/curl -f --cookie "session=$sessionToken"'';
  rg = "${ripgrep}/bin/rg --color never";

  noSessionToken = ''
    echo -e "\033[0;31m.---------------------------.\033[0m"
    echo -e "\033[0;31m|                           |\033[0m"
    echo -e "\033[0;31m| Session Token is not set! |\033[0m"
    echo -e "\033[0;31m|                           |\033[0m"
    echo -e "\033[0;31m'---------------------------'\033[0m"
    exit 1
  '';

  initDayScript = writeShellScriptBin "initday" ''
    yearDirname=$(basename $(pwd))

    # Error if not a year dir
    [[ ! $(echo $yearDirname | ${rg} "\d{4}") ]] && echo "Not a year dir" && exit 1
    year=''${yearDirname:0}

    ${getDayScriptPart "initday"}

    mkdir -p ${PROJECT_ROOT}/$yearDirname/$day
    cat ${PROJECT_ROOT}/templates/template.py \
      | sed "s/%DAYNUM%/$day/g" \
      > ${PROJECT_ROOT}/$yearDirname/$day/$day.py
    
    cd ${PROJECT_ROOT}/$yearDirname/$day
    ${waitForInput}/bin/waitforinput
  '';

  # TODO actually wait
  waitForInput = writeShellScriptBin "waitforinput" ''
    dayDirname=$(basename $(pwd))

    # Error if not a solution dir
    [[ ! $(echo $dayDirname | ${rg} "\d{2}") ]] && echo "Not a day solution dir" && exit 1
    day=''${dayDirname:0}

    # assumes we are in the yyyy/dd/ folder
    yearDirname=$(basename $(dirname $(pwd)))

    # Error if not a year dir
    [[ ! $(echo $yearDirname | ${rg} "\d{4}") ]] && echo "Not a year dir" && exit 1
    year=''${yearDirname:0}

    [[ -f $day.txt ]] && less $day.txt && exit 0

    if [[ -f ${PROJECT_ROOT}/.session_token ]]; then
      dayTruncated=$day
      [[ $(echo "$day < 10" | ${bc}/bin/bc) == "1" ]] && dayTruncated=''${day:1}
      sessionToken=$(cat ${PROJECT_ROOT}/.session_token)
      echo "Running: ${curl} --output $day.txt https://adventofcode.com/$year/day/$dayTruncated/input"
      ${curl} --output $day.txt https://adventofcode.com/$year/day/$dayTruncated/input
    else
      ${noSessionToken}
    fi

    less $day.txt
  '';

  printStatsScript = writeShellScriptBin "printstats" ''
    yearDirname=$(basename $(pwd))

    # Skip if not a year dir
    [[ ! $(echo $yearDirname | ${rg} "\d{4}") ]] && exit 0
    year=''${yearDirname:0}

    if [[ -f ${PROJECT_ROOT}/.session_token ]]; then
      sessionToken=$(cat ${PROJECT_ROOT}/.session_token)
      ${curl} -s https://adventofcode.com/$year/leaderboard/self |
        ${html-xml-utils}/bin/hxselect -c pre |
        ${gnused}/bin/sed "s/<[^>]*>//g" |
        ${rg} "^\s*(Day\s+Time|-+Part|\d+\s+(&gt;24h|\d{2}:\d{2}:\d{2}))" |
        ${gnused}/bin/sed "s/&gt;/>/g"
    else
      ${noSessionToken}
    fi
  '';

  getDayScriptPart = scriptName: ''
    # Check that day is passed in.
    [[ $1 == "" ]] && echo "Usage: ${scriptName} <day>" && exit 1
    day=$1

    # Error if no day
    [[ ! $(echo $day | ${rg} "\d+") ]] && echo "Not a valid day" && exit 1

    # Zero-pad day
    [[ $(echo "$1 < 10" | ${bc}/bin/bc) == "1" ]] && day="0$day"
  '';

  runScript = writeShellScriptBin "run" ''
    ${getDayScriptPart "run"}

    ${watchexec}/bin/watchexec -r "${pythonWithPackages}/bin/${binName} ./$day.py"
  '';

  debugRunScript = writeShellScriptBin "drun" ''
    ${getDayScriptPart "drun"}

    ${watchexec}/bin/watchexec -r "${pythonWithPackages}/bin/${binName} ./$day.py --debug"
  '';

  # Single run, don't watchexec
  singleRunScript = writeShellScriptBin "srun" ''
    ${getDayScriptPart "srun"}

    ${pythonWithPackages}/bin/${binName} ./$day.py
  '';

  debugSingleRunScript = writeShellScriptBin "dsrun" ''
    ${getDayScriptPart "dsrun"}

    ${pythonWithPackages}/bin/${binName} ./$day.py --debug
  '';

  # Write a test file
  mkTestScript = writeShellScriptBin "mktest" ''
    ${getDayScriptPart "mktest"}
    if [[ -z "$WAYLAND_DISPLAY" ]]; then
      ${xsel}/bin/xsel --output > inputs/$day.test.txt
    else
      ${wl-clipboard}/bin/wl-paste -p > inputs/$day.test.txt
    fi
  '';

  # Run with --notest flag
  runNoTestScript = writeShellScriptBin "rntest" ''
    ${getDayScriptPart "rntest"}
    ${pythonWithPackages}/bin/${binName} ./$day.py --notest
  '';

  debugRunNoTestScript = writeShellScriptBin "drntest" ''
    ${getDayScriptPart "druntest"}
    ${pythonWithPackages}/bin/${binName} ./$day.py --notest --debug
  '';

  # Run with --stdin and --notest flags
  runStdinScript = writeShellScriptBin "runstdin" ''
    ${getDayScriptPart "runstdin"}
    ${pythonWithPackages}/bin/${binName} ./$day.py --stdin --notest
  '';

  # Run with --stdin and --notest flags, and pull from clipboard.
  runStdinClipScript = writeShellScriptBin "runstdinclip" ''
    ${getDayScriptPart "runstdin"}
    ${xsel}/bin/xsel --output | ${pythonWithPackages}/bin/${binName} ./$day.py --stdin --notest
  '';

in
mkShell {
  shellHook = ''
  '';

  POST_CD_COMMAND = "${printStatsScript}/bin/printstats";

  buildInputs = [
    # Core
    coreutils
    gnumake
    rnix-lsp
    sloccount
    tokei

    # Python
    pythonWithPackages.pkgs.black
    pythonWithPackages.pkgs.flake8
    pythonWithPackages
    pypy3

    # Utilities
    initDayScript
    debugRunScript
    debugRunNoTestScript
    debugSingleRunScript
    waitForInput
    mkTestScript
    printStatsScript
    runScript
    runStdinClipScript
    runStdinScript
    runNoTestScript
    singleRunScript
  ];
}