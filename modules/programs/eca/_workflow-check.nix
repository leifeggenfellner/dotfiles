{ pkgs }:
let
  hooks = import ./_hooks.nix { inherit pkgs; };
  check = pkgs.writeShellApplication {
    name = "eca-workflow-hooks-check";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.gnugrep ];
    text = ''
      set -euo pipefail
      root="$TMPDIR/eca-workflow-hooks-$PPID"
      mkdir -p "$root"

      run_record() {
        local runtime="$1" input="$2"
        printf '%s' "$input" | XDG_RUNTIME_DIR="$runtime" ${hooks.record}/bin/eca-lead-workflow-record
      }

      run_verify() {
        local runtime="$1" input="$2"
        printf '%s' "$input" | XDG_RUNTIME_DIR="$runtime" ${hooks.verify}/bin/eca-lead-workflow-verify
      }

      lead='{"agent":"lead","session_id":"s","chat_id":"c"}'
      impl='{"agent":"lead","session_id":"s","chat_id":"c","tool_input":{"agent":"nix-home-manager","task":"Workflow tier: fast"}}'
      verifier='{"agent":"lead","session_id":"s","chat_id":"c","tool_input":{"agent":"verifier","task":"Security review: not-required"}}'
      reviewer='{"agent":"lead","session_id":"s","chat_id":"c","tool_input":{"agent":"reviewer","task":""}}'

      fresh() {
        local name="$1"
        mkdir -p "$root/$name"
        printf '%s' "$root/$name"
      }

      expect_followup() {
        local output="$1" expected="$2"
        test -n "$output"
        printf '%s' "$output" | jq -e --arg expected "$expected" '.followUp | contains($expected)' >/dev/null
      }

      expect_none() { test -z "$1"; }

      runtime=$(fresh fast)
      run_record "$runtime" "$impl"
      run_record "$runtime" "$verifier"
      output=$(run_verify "$runtime" "$lead" || true)
      expect_none "$output"

      runtime=$(fresh full)
      full_impl=''${impl/Workflow tier: fast/Workflow tier: full}
      run_record "$runtime" "$full_impl"
      run_record "$runtime" "$verifier"
      output=$(run_verify "$runtime" "$lead")
      expect_followup "$output" reviewer

      runtime=$(fresh missing-tier)
      missing_impl=''${impl/Workflow tier: fast/}
      run_record "$runtime" "$missing_impl"
      run_record "$runtime" "$verifier"
      output=$(run_verify "$runtime" "$lead")
      expect_followup "$output" reviewer

      runtime=$(fresh security-required)
      run_record "$runtime" "$impl"
      required_verifier=''${verifier/Security review: not-required/Security review: required}
      run_record "$runtime" "$required_verifier"
      output=$(run_verify "$runtime" "$lead")
      expect_followup "$output" reviewer
      run_record "$runtime" "$reviewer"
      output=$(run_verify "$runtime" "$lead")
      expect_followup "$output" security

      runtime=$(fresh security-not-required)
      run_record "$runtime" "$full_impl"
      run_record "$runtime" "$verifier"
      run_record "$runtime" "$reviewer"
      expect_none "$(run_verify "$runtime" "$lead" || true)"

      runtime=$(fresh security-missing)
      run_record "$runtime" "$full_impl"
      missing_security=''${verifier/Security review: not-required/}
      run_record "$runtime" "$missing_security"
      run_record "$runtime" "$reviewer"
      output=$(run_verify "$runtime" "$lead")
      expect_followup "$output" security

      runtime=$(fresh escalated)
      run_record "$runtime" "$impl"
      run_record "$runtime" "$full_impl"
      run_record "$runtime" "$verifier"
      expect_followup "$(run_verify "$runtime" "$lead")" reviewer

      runtime=$(fresh reset)
      run_record "$runtime" "$full_impl"
      run_record "$runtime" "$verifier"
      run_record "$runtime" "$reviewer"
      second_impl=''${full_impl/Workflow tier: full/Workflow tier: full second}
      run_record "$runtime" "$second_impl"
      expect_followup "$(run_verify "$runtime" "$lead")" verifier

      runtime=$(fresh non-lead)
      run_record "$runtime" "$impl"
      run_record "$runtime" "$verifier"
      non_lead=$(printf '%s' "$lead" | jq '.agent = "other"')
      expect_none "$(run_verify "$runtime" "$non_lead" || true)"

      runtime=$(fresh follow-up-active)
      run_record "$runtime" "$impl"
      run_record "$runtime" "$verifier"
      active=$(printf '%s' "$lead" | jq '.follow_up_active = true')
      expect_none "$(run_verify "$runtime" "$active" || true)"

      if ${hooks.verify}/bin/eca-lead-workflow-verify <<< "$lead" | grep -F 'All required gate invocations are present'; then
        exit 1
      fi
      echo 'All workflow hook cases passed.'
    '';
  };
in
pkgs.runCommand "eca-workflow-hooks-check" { nativeBuildInputs = [ check ]; } ''
  ${check}/bin/eca-workflow-hooks-check
  touch $out
''
