FROM    debian:9

# Install everything plus dependencies in order to install Perforce.
RUN     apt-get update \
            && apt-get install -y \
                bzr \
                curl \
                cvs \
                darcs \
                git \
                gnupg2 \
                mercurial \
                procps \
                python-future \
                python-markupsafe \
                python-migrate \
                python-sqlalchemy \
                python-tempita \
                python-twisted \
                python-virtualenv \
                python2.7 \
                python3 \
                python3-future \
                python3-markupsafe \
                python3-migrate \
                python3-sqlalchemy \
                python3-tempita \
                python3-twisted \
                python3-virtualenv \
                runit \
                subversion \
            && apt-get install -y --no-install-recommends \
                python-pip \
                python-setuptools \
                python3-pip \
                python3-setuptools \
            && rm -rf /var/lib/apt/lists/*

RUN     curl https://package.perforce.com/perforce.pubkey | apt-key add -

COPY    perforce.list /etc/apt/sources.list.d/perforce.list

RUN     apt-get update \
            && apt-get install -y \
                helix-p4d \
                helix-cli \
            && rm -rf /var/lib/apt/lists/*


RUN     useradd -m buildbot

USER    buildbot

RUN     virtualenv -p python2.7 --system-site-packages ~/venv/py2 \
        && virtualenv -p python3.5 --system-site-packages ~/venv/py3

RUN     ~/venv/py2/bin/pip install 'buildbot[bundle]' buildbot-worker \
        && ~/venv/py3/bin/pip install 'buildbot[bundle]' buildbot-worker

RUN     ~/venv/py2/bin/buildbot create-master ~/buildbot-py2 \
        && ~/venv/py3/bin/buildbot create-master ~/buildbot-py3

RUN     ln -s ~/buildbot/master.cfg ~/buildbot-py2/master.cfg \
        && ln -s ~/buildbot/master.cfg ~/buildbot-py3/master.cfg

COPY    buildbot /home/buildbot/buildbot


USER    root

COPY    service /service

CMD     ["runsvdir", "/service"]
