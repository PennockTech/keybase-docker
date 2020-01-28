keybase-docker
==============

Run keybase isolated inside a Docker container, but with KBFS and git remotes
using `keybase:` schemas working.

The Docker container to be run needs three elevated permissions, but does not
run as `--privileged`.  The three are:

    --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined

This uses a "recent" Ubuntu release as the base, and is expected to roll with
the "current" Ubuntu release as they come out.

Keybase's public key for signing packages is inside this git repo, so we've
only taken a leap-of-faith once.

You will need to keep around a Docker Volume to act as your `$HOME` inside the
container.
This is because the act of authenticating a device to your Keybase account
leaves an irrevocable entry in a public audit trail.  You don't want to keep
doing that.  So we use a volume.  This means you can also check out Keybase
git repos and then access the contents from outside the Docker container.

I use `~/DockerVolumes/keybase-home` and that's what's in the wrapper script.

## Build

```console
% docker build -t keybase:latest .
% keybase.run_docker
$ keybase --version
[ see a version number here ]
$ exit
% docker tag keybase:latest keybase:5.1.1
```

## Use

```console
% keybase.run_docker
$ run_keybase
$ ls /keybase/public/philpennock/PGP-Keys/

$ mkdir repos repos/my-team
$ cd repos/my-team
$ git clone keybase://team/my-team/repo-in-team
$ cd repo-in-team
$ ls
$ exit

% ls ~/DockerVolumes/keybase-home/repos/my-team/repo-in-team
```
