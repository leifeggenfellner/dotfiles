{ pkgs }:
pkgs.writeShellApplication {
  name = "sops-enroll-host";
  runtimeInputs = with pkgs; [ git sops ssh-to-age yq-go ];
  text = ''
    # Enroll this machine (or the host named by $1) as a recipient of every
    # secret under sops/: derive the host's age key from its persisted SSH
    # host key, record it in .sops.yaml, and re-encrypt. Re-encrypting needs
    # an existing recipient, i.e. the personal GPG key imported into gpg.
    host="''${1:-$(hostname)}"
    cd "$(git rev-parse --show-toplevel)"

    pub=/persist/etc/ssh/ssh_host_ed25519_key.pub
    [ -r "$pub" ] || pub=/etc/ssh/ssh_host_ed25519_key.pub
    age_key="$(ssh-to-age < "$pub")"

    if grep -qF "$age_key" .sops.yaml; then
      echo "$host is already enrolled ($age_key)."
    elif [ -n "$(yq ".keys[] | select(anchor == \"$host\")" .sops.yaml)" ]; then
      echo "Rotating $host's key to $age_key (host key changed, e.g. reinstall)."
      yq -i "(.keys[] | select(anchor == \"$host\")) |= \"$age_key\"" .sops.yaml
    else
      echo "Adding $host ($age_key)."
      yq -i "
        .keys += [\"$age_key\"] | .keys[-1] anchor = \"$host\"
        | .creation_rules[].key_groups[0].age += [\"\"]
        | .creation_rules[].key_groups[0].age[-1] alias = \"$host\"
      " .sops.yaml
    fi

    for file in sops/*.yaml; do
      sops updatekeys --yes "$file"
    done

    cat <<EOF

    Done. Next:
      1. Set 'secrets.enable = true;' in modules/hosts/$host/_machine.nix
      2. git add .sops.yaml sops/ && git commit
      3. Rebuild; secrets appear under /run/secrets.
    EOF
  '';
}
