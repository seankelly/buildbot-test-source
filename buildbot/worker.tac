import os

import six

from buildbot_worker.bot import Worker
from twisted.application import service

if six.PY2:
    PB_PORT = int(os.environ['PY2_PB_PORT'])
elif six.PY3:
    PB_PORT = int(os.environ['PY3_PB_PORT'])

basedir = os.path.abspath(os.path.dirname(__file__))
rotateLength = 10000000
maxRotatedFiles = 1

basename = os.path.split(basedir)[1]
name = 'source-' + basename[4:]

# note: this line is matched against to check that this is a worker
# directory; do not edit it.
application = service.Application('buildbot-worker')

from twisted.python.logfile import LogFile
from twisted.python.log import ILogObserver, FileLogObserver
logfile = LogFile.fromFullPath(
    os.path.join(basedir, "twistd.log"), rotateLength=rotateLength,
    maxRotatedFiles=maxRotatedFiles)
application.setComponent(ILogObserver, FileLogObserver(logfile).emit)

buildmaster_host = '127.0.0.1'
port = PB_PORT
workername = name
passwd = 'pass'
keepalive = 600
umask = None
maxdelay = 300
numcpus = None
allow_shutdown = None

s = Worker(buildmaster_host, port, workername, passwd, basedir,
           keepalive, umask=umask, maxdelay=maxdelay,
           numcpus=numcpus, allow_shutdown=allow_shutdown)
s.setServiceParent(application)
