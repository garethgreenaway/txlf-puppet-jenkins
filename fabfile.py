import os
import re
import sys
import time

import fabric.colors
import fabric.contrib

from fabric.api import *

from fabric.contrib.files import exists

from fabric.context_managers import hide

env.roledefs = {
    'trunk': ['web01.domain.com', 'app01.domain.com', 'app02.domain.com'],
}

@parallel
def run_puppet():
    while fabric.contrib.files.exists("/var/lib/puppet/state/puppetdlock"):
        print(fabric.colors.yellow("Sleeping"))
        time.sleep(10)

    print(fabric.colors.green("Running Puppet"))
    sudo("/usr/sbin/puppetd --onetime --verbose --no-daemonize --show_diff", shell=False, pty=False)

