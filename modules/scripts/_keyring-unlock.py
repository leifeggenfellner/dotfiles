"""Unlock the running gnome-keyring daemon's login keyring.

greetd autologs in without a password, so pam_gnome_keyring starts the daemon
with the login keyring locked. `gnome-keyring-daemon --unlock` can't fix that:
it spawns a second daemon instead of talking to the running one. This speaks
the daemon's control-socket protocol (the same one pam_gnome_keyring uses) to
unlock it in place, reading the password from stdin.
"""

import os
import socket
import struct
import sys

OP_UNLOCK = 1
RESULTS = {0: "ok", 1: "denied", 2: "failed", 3: "no daemon"}

password = sys.stdin.buffer.read().rstrip(b"\n")
control = os.path.join(os.environ["XDG_RUNTIME_DIR"], "keyring", "control")

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
    sock.connect(control)
    # Credentials byte: the daemon checks the peer's uid via SO_PEERCRED.
    sock.sendall(b"\0")
    # Packet: total length, op, then the password as a length-prefixed string.
    sock.sendall(
        struct.pack(">III", 12 + len(password), OP_UNLOCK, len(password))
        + password
    )
    _length, result = struct.unpack(">II", sock.recv(8))

print(f"login keyring unlock: {RESULTS.get(result, result)}", file=sys.stderr)
sys.exit(0 if result == 0 else 1)
