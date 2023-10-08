{ pkgs, tfPreHook, tfExtraPkgs, binName, terraformBin, cliData, useOpenTofu }:

# terraform command on a root
let
  cmd = if useOpenTofu then "tofu" else "terraform";
in
pkgs.writeShellApplication {
  name = binName;
  runtimeInputs = [ terraformBin pkgs.jq pkgs.coreutils ] ++ tfExtraPkgs;
  text = ''
    tf_configs="${cliData.roots}"
    all_configs=$(cat "${cliData.all-roots-order}")

    usage()
    {
      echo "Usage: nix run .#tf -- [ -a | --all ] [ -e | --env ] [ -r | --root ] [ -b | --build ] <action>"
      echo "  -a | --all: Run all roots"
      echo "  -e | --env: Run a specific environment. If not specified, runs dev"
      echo "  -r | --root: One of the available roots: $all_configs"
      echo "  -b | --build: Build the config.json file - will output the file to stdout, and do nothing else"
      echo "  actions: command to run - plan, apply, will be passed to ${cmd}"
      exit 2
    }

    # Parse command line args
    ARG_RUN_ALL=false
    ARG_ENV="dev"
    ARG_ACTION=( "plan" )
    ARG_ROOT=""
    ARG_BUILD=false

    parsed_arguments=$(getopt -n tf -o har:e:b -l help,all,root:env:build -- "$@")
    valid_arguments=$?
    if [ "$valid_arguments" != "0" ]; then
      usage
    fi

    eval set -- "$parsed_arguments"
    while :
    do
      case "$1" in
        -h | --help) usage ;;
        -a | --all) ARG_RUN_ALL=true ; shift ;;
        -e | --env) ARG_ENV="$2" ; shift 2 ;;
        -r | --root) ARG_ROOT="$2" ; shift 2 ;;
        -b | --build) ARG_BUILD=true ; shift ;;
        --) shift ; ARG_ACTION=( "$@" ) ; break ;;
        *) echo "❌ Unexpected option: $1 - this should not happen." ; usage ;;
      esac
    done

    if [[ ''${#ARG_ACTION[@]} -eq 0 ]] && [[ "$ARG_BUILD" != "true" ]]; then
      echo "❌ Error: No action specified"
      usage
    fi

    if [[ "$ARG_RUN_ALL" != "true" ]] && [[ -z "$ARG_ROOT" ]]; then
      echo "❌ Error: No root specified"
      usage
    fi

    run_tf()
    {
      root="$1"
      config=$(jq -r --arg root "$root" --arg env "$ARG_ENV" '.[$root].configs[$env]' "$tf_configs")

      # skip if no config
      if [[ "$config" == 'null' ]]; then
        echo "⚠️  No config for root \"$root\" and env \"$ARG_ENV\""
        return
      fi

      if [[ "$ARG_BUILD" == "true" ]]; then
        echo "🔧 Building config for root \"$root\""
        cp "$config" "$(pwd)/$root.tf.json"
        return
      fi

      actual_workdir=$(pwd)
      tfplan="$actual_workdir/$root.$ARG_ENV.tfplan"

      workdir=$(mktemp -d)
      pushd "$workdir" > /dev/null
      trap 'rm -rf "$workdir"' TERM EXIT

      if [[ -f "$tfplan" ]]; then
        echo "ℹ️ $tfplan was found, copying it to ${cmd} workdir"
        echo "  ℹ️ it will be available to ${cmd} as 'tfplan'"
        cp "$tfplan" tfplan
      fi

      cp "$config" config.tf.json
      ${tfPreHook}

      echo "🔧 Running ${cmd} init for root \"$root\""
      ${cmd} init -input=false > /dev/null
      echo "🚀 Running ${cmd} ''${ARG_ACTION[*]} for root \"$root\""
      ${cmd} "''${ARG_ACTION[@]}"
      echo "✅ Done running ${cmd} ''${ARG_ACTION[*]} for root \"$root\""

      # If a tfplan file was generated, copy it to working directory of the user
      # This is useful for CI setups to ie. save the plan as an artifact
      if [[ -f "tfplan" ]]; then
        echo "ℹ️ tfplan file found, copying it to $tfplan"
        cp "tfplan" "$tfplan"
        echo "  ℹ️ also creating a json representation of the plan"
        ${cmd} show -json "tfplan" > "$tfplan.json"
      fi

      popd > /dev/null
      rm -rf "$workdir" > /dev/null
    }

    if [[ "$ARG_RUN_ALL" == "true" ]]; then
      counter=1
      length=$(echo "$all_configs" | wc -w)

      echo "🚀 Running all roots"
      for root in $all_configs; do
        echo "ℹ️  Root [$counter/$length] - \"$root\""
        run_tf "$root"
        counter=$((counter+1))
      done
      echo "✅ Done running all roots"
    else
      run_tf "$ARG_ROOT"
    fi
  '';
}
