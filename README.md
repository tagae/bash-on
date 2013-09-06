Bash On
=======

A modular library of Bash functions.

Support
-------

The library uses features introduced in Bash 4, and therefore does not
work with older versions of Bash.

If you install Bash 4+ in your system, you can bring it forward in
your `PATH` and use `#!/usr/bin/env bash` as shebang. Mind that such
invocation may bring security problems if an attacker were able to
manipulate your `PATH`. Otherwise just hard-code the desired path in
the shebang.

Further note that the shebang of your script has to request `bash`
instead of the more generic (and limited) `sh`.


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

This mechanism will resolve at most one level of symlink indirection,
which is sufficient in most cases.

Licence
-------

Copyright 2013 Sebastián González Montesinos

Licensed under the Apache License, Version 2.0.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.
