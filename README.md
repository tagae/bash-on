Bash On
=======

Yet another script to write today? No worries mate, bash on!

Bash On is a modular library that helps you write robust Bash scripts.

Support
-------

The library has been tested on Bash version 4.2.

Installation
------------

Independently of source code management:

    git clone git://github.com/tagae/bash-on.git lib

As a submodule of your current git-managed project:

    git submodule add git://github.com/tagae/bash-on.git lib

Loading
-------

Simply source `modules.sh` into your script.

Supposing you installed the library into a `lib` directory as
indicated previously, use

    source "$(dirname "$0")/lib/modules.sh"

The library loads the following modules as part of its core
functionality, which therefore need not be loaded explicitly:

* colors
* interaction
* scripting
* modules

### Tips

There is a caveat with the naive loading mechanism suggested
previously. If your script is invoked through a symlink, the location
of `$0` will not reflect the true location where `lib` can be found.

To account for these cases, use

    source "$(dirname "$(readlink -e "$0")")/lib/modules.sh"

This is a robust loading mechanism, though the `-e` option is specific
to GNU `readlink` from the `coreutils` package.

To use `readlink` portably across GNU and BSD, do

    source "$(dirname "$(readlink "$0" || echo "$0")")/lib/modules.sh"

This mechanism will resolve at most one level of symlink indirection.
