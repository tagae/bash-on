Bash On
=======

Yet another script to write today? No worries, bash on!

Bash On is a modular Bash library to help you write robust scripts.

Support
-------

The library uses features introduced in Bash 4, and therefore does not
work with older versions of Bash.

### Tip

You can use a newer version of bash by having your script start with

    #!/usr/bin/env bash

instead of the traditional `/bin/bash`. Of course this requires that
the newer version of `bash` is found first in the current `PATH`.  For
this very reason, such invocation may bring security problems.

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

You can then load the modules you need with `require-module`, for
example

    require-module files

If you need just one module, you can load it directly:

    source "$(dirname "$0")/lib/files.sh"

### Tips

There is a caveat with the vanilla loading mechanism suggested
previously. If your script is invoked through a symlink, the location
of `$0` will not reflect the true location where `lib` can be found.

To account for these cases, use

    source "$(dirname "$(readlink -e "$0")")/lib/modules.sh"

This is a robust loading mechanism, though the `-e` option is specific
to GNU `readlink` from the `coreutils` package.

To use `readlink` portably across GNU and BSD, do

    source "$(dirname "$(readlink "$0" || echo "$0")")/lib/modules.sh"

This mechanism will resolve at most one level of symlink indirection.
