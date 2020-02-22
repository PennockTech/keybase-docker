keybase-docker
==============

Run Keybase isolated inside a Docker container, but with KBFS and git remotes
using `keybase:` schemas working.

The Docker container will need three elevated permissions, but does not
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


## Build (Short Version)

```console
% ./build
```

That will build the image, then run it once without any privileges at all,
just enough to ask the `keybase` command inside it what its version number is,
so that the built image can be tagged with a real version number.

You'll get two images out, one tagged with a `-root` suffix; the root images
are from just before the final step where the user is assigned, so the runtime
user is still `root`.

This only builds the Docker image; it does not set up the directory which
will be your home-directory inside the running container.  Nothing is strictly
needed, but see [Dotfiles](#Dotfiles) below for some recommended items.


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

### Two available runner scripts

There are two scripts for running the Docker container.

1. `simpler-runner` has no options, it just shows the bare minimum for how to
   run the Docker container.  To understand what's going on, look at that
   first.  It's short.
2. `keybase.run_docker` has options; run `keybase.run_docker -h` to see help.
   It's shell with getopts and usage, but when invoked with no options ends up
   doing exactly the same as `simpler-runner`.

If you don't like even seeing shell longer than a few lines, then audit
`simpler-runner`, change the hard-coded paths and image names, and use that.

If you're happy with what `keybase.run_docker` is doing, then use that.
Sooner or later you might want to explicitly run an older release of Keybase,
to avoid or investigate some change in behavior.  This is why the build
script tags the actual version.


## Dotfiles

You have a persistent "inside keybase container" home directory, you can drop
files into it either inside or outside of Docker.

* A simple shell config which emits a notice reminding you of commands might
  suit; see [`example.bashrc`](example.bashrc)
* Creating a `.gitconfig` will help if you use the `keybase:` schema git
  remotes inside the Container.
  It doesn't need anything keybase-specific, but if you copy in your regular
  `~/.gitconfig`, do think about issues like "credential helpers" and perhaps
  simplify it a bit.

Since dealing with SSH-based git remotes, with agent forwarding, inside a
Docker container is a little troublesome, I recommend taking advantage of the
common directory and just don't do that inside the keybase container.  Talk
with regular non-keybase git remotes outside the container, `keybase:` schema
remotes inside the container.

It's much less hassle to accept the limitation than to try to support other
people when working with SSH agent forwarding, across both native Docker and
Docker-inside-implicit-VM or remote Docker.


## Advanced build

Accepting the defaults (uid 1000), the simplest is:

```console
% docker build -t keybase:latest .
% keybase.run_docker keybase --version
[ see a version number here ]
% docker tag keybase:latest keybase:5.2.0
```

The version-specific tag is only for if you want to go back to an older
version later; by default, `keybase.run_docker` uses implicit latest.

To build if you're not happy for the keybase run-time user to be uid 1000
(which only really affects the ownership of files inside the Volume used
for the home-dir), use a "docker build argument" to change that:

```console
% docker build --build-arg KEYBASE_UID=$(id -u) -t keybase:latest .
```

Then, to be able to run a container where inside it you are the `root` user,
not the `keybase` user, go ahead and capture the earlier build stage:

```console
% docker build --target root -t keybase:latest-root .
% docker build -t keybase:latest .
% keybase.run_docker keybase --version
[ see a version number here ]
% docker tag keybase:latest keybase:5.2.0
% docker tag keybase:latest-root keybase:5.2.0-root
```

And by now you see why the build script does what it does.

## Credits

My starting point for "a container with Keybase installed" was
<https://hub.docker.com/r/langrisha/keybase/dockerfile>
by Filip Dupanović
<https://keybase.io/langrisha>
<https://github.com/langri-sha>.
I've belatedly found the Git repository for that, over at
<https://github.com/langri-sha/docker-keybase>.

While I changed a lot, looking back I still see the core of what I copy/pasted
fragments from, so I've updated the license to acknowledge the copyright of
that original.

Conveniently, we each independently went with a MIT license.

The stuff to get KBFS working, that was all my head leaving indentations in
the nearest wall.
