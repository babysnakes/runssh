#
#  runsshlib.py
#
#  Created by Haim Ashkenazi on 2010-01-27.
#  Copyright 2010 Haim Ashkenazi. All rights reserved.
#

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
    (options, args) = parser.parse_args()
    
    config = ConfigObj(_configfile)
    
    # initialy we use the 'root' section
    s = config
    for arg in args:
        try:
            s = s[arg]
        except KeyError, ke:
            sys.stderr.write('invalid section: "%s"\n' % arg)
            sys.exit(5)
    
    # is this a group or host?
    if s.sections:      # group
        if options.list:
            print_sections(s)
        else:
            parser.error("last argument is a section, not host!")
    else:               # host
        if not options.list:
            run_ssh(s)

def print_sections(section):
    for s in section.sections:
        print s

def run_ssh(section):
    user = ''
    if 'user' in section.keys():
        user = '-l %s' % section['user']
    
    try:
        host = section['host']
    except KeyError, ke:
        print 'Invalid configuration for "%s". No host specified!' % section
    
    print 'ssh %s %s' % (user, host)
