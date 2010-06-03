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
    - Handle '-' in section names (either avoid or solve completion)
"""

import os, sys

import cmdln
from configobj import ConfigObj

def main():
    command = RunSSHCmd()
    sys.exit(command.main(loop=cmdln.LOOP_IF_EMPTY))
    # command line arguments
    # usage = "usage: %prog [options] [section ...] host"
    # parser = OptionParser(usage=usage)
    # parser.add_option("-l", action="store_true", dest="list", default=False,
    #                   help="list available sub-secions.")
    # parser.add_option("-p", action="store_true", dest="printconfig", default=False,
    #                   help="print configuration of host definition.")
    # (options, args) = parser.parse_args()
    #
    # config = ConfigObj(_configfile)
    #
    # # drill down through all sections (args)
    # s = config      # initialy we use the 'root' section
    # for arg in args:
    #     try:
    #         s = s[arg]
    #     except KeyError, ke:
    #         parser.error('invalid section: "%s"\n' % arg)
    #
    # # is this a group or host?
    # if s.sections:      # group
    #     if options.list:
    #         print_sections(s)
    #     else:
    #         parser.error("last argument is a section, not host!")
    # else:               # host
    #     if options.list:
    #         pass    # list has no effect here.
    #     elif options.printconfig:
    #         print_host(s)
    #     else:
    #         run_ssh(s)

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
    except KeyError:
        # TODO: call this error through parser?
        sys.stderr.write('Invalid configuration for "%s". No host specified!\n'
                         % section.name)
        sys.exit(3)
    
    os.execvp('ssh', sshargs)


class RunSSHConfig:
    "A wrapper for the app configuration."
    
    def __init__(self, configfile=None):
        if not configfile:
            configfile = os.path.join(os.getenv('HOME'), '.runssh.conf')
        self.config = ConfigObj(configfile)
    
    def get_subsections_list(self, path):
        """ A utility method to return a list of available subsecions extracted
            from the specified path.
            
            path is a sequence of ordered subsection names separated
            by spaces. e.g, 'section1 subsection12 subsection124' where
            subsecion12 is a sub-section of section1 etc...
        """
        s = self._get_section_from_path(path)
        return s.sections
    
    def _get_section_from_path(self, path):
        """ extract the section specified through the path.
            
            path is a sequence of ordered subsection names separated
            by spaces. e.g, 'section1 subsection12 subsection124' where
            subsecion12 is a sub-section of section1 etc...
        """
        s = self.config
        for section in path:
            try:
                s = s[section]
            except KeyError:
                raise SectionError("No Such (sub)section: \"%s\"" % section)
        return s


class RunSSHCmd(cmdln.Cmdln):
    
    config = RunSSHConfig()
    
    def do_connect(self, subcmd, opts, *host):
        "connect to remote host"
        print 'connecting to',  host
    
    def complete_connect(self, text, line, begidx, endidx):
        path = line.split()
        # the first entry is the original command
        path.pop(0)
        if text:    # the word we're searching completion for
            path.pop()
        # no need to catch SectionError, cmdln ignores it.
        result = RunSSHCmd.config.get_subsections_list(path)
        return [n for n in result if n.startswith(text)]


class SectionError(Exception):
    """Indicates config section error."""
    pass
