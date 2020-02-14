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

$ keybase.is-up-to-date        # does a phone-home-to-keybase curl

$ mkdir repos repos/my-team
$ cd repos/my-team
$ git clone keybase://team/my-team/repo-in-team
$ cd repo-in-team
$ ls
$ exit

% ls ~/DockerVolumes/keybase-home/repos/my-team/repo-in-team
```

## Dotfiles

You have a persistent "inside keybase container" home directory, you can drop
files into it either inside or outside of Docker.

* A simple shell config which emits a notice reminding you of commands might
  suit; see `example.bashrc`
* Creating a `.gitconfig` will help if you use the `keybase:` schema git
  remotes inside the Container.

Since dealing with SSH-based git remotes, with agent forwarding, inside a
Docker container is a little troublesome, I recommend taking advantage of the
common directory and just don't do that inside the keybase container.  Talk
with regular non-keybase git remotes outside the container, `keybase:` schema
remotes inside the container.

It's much less hassle to accept the limitation than to try to support other
people when working with SSH agent forwarding, across both native Docker and
Docker-inside-implicit-VM.
