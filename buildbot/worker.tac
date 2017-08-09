import os

from buildbot_worker.bot import Worker
from twisted.application import service

basedir = 'BASEDIR'
rotateLength = 10000000
maxRotatedFiles = 1

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
port = PORT
workername = 'NAME'
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
