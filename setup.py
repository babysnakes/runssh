# 
#  setup.py
#  
#  Created by Haim Ashkenazi on 2010-01-27.
#  Copyright 2010 Haim Ashkenazi. All rights reserved.
# 

from setuptools import setup

setup(
    name = 'RunssH',
    version = '0.1.0a1',
    description = 'Easy way to organize and launch ssh sessions.',
    author = 'Haim Ashkenazi',
    author_email = 'haim@babysnakes.org',
    packages = ['babysnakes'],
    package_dir = {'': 'src'},
    install_requires = ['ConfigObj'],
    entry_points = ("""
        [console_scripts]
        runssh = babysnakes.runsshlib:main
    """)
)