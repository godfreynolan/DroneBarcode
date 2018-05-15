"""
dronebarcode python package configuration.

Luke Justice <ljustice@riis.com>
"""

from setuptools import setup

setup(
    name='dronebarcode',
    version='0.1.0',
    packages=['dronebarcode'],
    include_package_data=True,
    install_requires=[
        'ecdsa==0.13',
        'html5validator==0.2.8',
        'pycodestyle==2.3.1',
        'pydocstyle==2.0.0',
        'pylint==1.8.1',
        'nodeenv==1.2.0',
        'sh==1.12.14',
        'Flask-Testing==0.6.2',
        'selenium==3.6.0',
        'requests==2.18.4',
        'arrow==0.10.0'
    ],
)
