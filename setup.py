# 
#  setup.py
#  
#  Created by Haim Ashkenazi on 2010-01-27.
#  Copyright 2010 Haim Ashkenazi. All rights reserved.
# 

from setuptools import setup

_requirements = ['configobj==4.7.0',
                 'argparse==1.1']

setup(
    name = 'RunSSH',
    version = '0.1.1dev',
    description = 'Easy way to organize and launch ssh sessions.',
    author = 'Haim Ashkenazi',
    author_email = 'haim@babysnakes.org',
    packages = ['babysnakes'],
    package_dir = {'': 'src'},
    install_requires = _requirements,
    entry_points = ("""
        [console_scripts]
        runssh = babysnakes.runsshlib:main
    """)
)