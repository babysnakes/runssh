#
#  runsshlib.py
#
#  Created by Haim Ashkenazi on 2010-01-27.
#  Copyright 2010 Haim Ashkenazi. All rights reserved.
#

"""
TODO:
    - Fix the workflow (e.g., The parser.error should only be thrown in one place
      and we should use exceptions to handle it).
    - Write validation for the config object (e.g., either section or host)
    - Add functionality to edit (add/delete/create) configs through command line.
    - Add ssh options (tunnel, port, etc)
"""

import os, sys
from optparse import OptionParser
from configobj import ConfigObj

_configfile = os.path.join(os.getenv('HOME'), '.runssh.conf')

def main():
    # command line arguments
    usage = "usage: %prog [options] [section ...] host"
    parser = OptionParser(usage=usage)
    parser.add_option("-l", action="store_true", dest="list", default=False,
                      help="list available sub-secions.")
    parser.add_option("-p", action="store_true", dest="printconfig", default=False,
                      help="print configuration of host definition.")
    (options, args) = parser.parse_args()
    
    config = ConfigObj(_configfile)
    
    # drill down through all sections (args)
    s = config      # initialy we use the 'root' section
    for arg in args:
        try:
            s = s[arg]
        except KeyError, ke:
            parser.error('invalid section: "%s"\n' % arg)
    
    # is this a group or host?
    if s.sections:      # group
        if options.list:
            print_sections(s)
        else:
            parser.error("last argument is a section, not host!")
    else:               # host
        if options.list:
            pass    # list has no effect here.
        if options.printconfig:
            print_host(s)
        else:
            run_ssh(s)

def print_sections(section):
    """
    list available sub-secions
    
    arguments:
        section - a configobj (sub)section to list it's contents.
    """
    for s in section.sections:
        print s

def print_host(host):
    """
    print the host configuration.
    
    arguments:
        host - a configobj section with no sub-sections (only keys)
    """
    for k, v in host.items():
        print "%s: %s" % (k, v)

def run_ssh(section):
    """
    run ssh with the settings from the host (section).
    
    arguments:
        section - The subsection with the host configuration.
    """
    # TODO: why 'ssh' have to appear twice in execvp?
    sshargs = ['ssh']
    if 'user' in section.keys():
        sshargs.extend(['-l', section['user']])
    
    try:
        host = section['host']
        sshargs.append(host)
    except KeyError, ke:
        # TODO: call this error through parser?
        sys.stderr.write('Invalid configuration for "%s". No host specified!\n'
                         % section.name)
        sys.exit(3)
    
    os.execvp('ssh', sshargs)
