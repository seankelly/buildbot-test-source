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
                python-future \
                python-markupsafe \
                python-migrate \
                python-sqlalchemy \
                python-tempita \
                python-twisted \
                python2.7 \
                python3 \
                python3-future \
                python3-markupsafe \
                python3-migrate \
                python3-sqlalchemy \
                python3-tempita \
                python3-twisted \
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

RUN     pip install 'buildbot[bundle]' buildbot-worker \
        && pip3 install 'buildbot[bundle]' buildbot-worker
