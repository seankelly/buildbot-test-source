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

COPY    apt/perforce.list /etc/apt/sources.list.d/perforce.list

RUN     apt-get update \
            && apt-get install -y \
                helix-p4d \
                helix-cli \
            && rm -rf /var/lib/apt/lists/*

# Configure Perforce server.
RUN     /opt/perforce/sbin/configure-helix-p4d.sh master -n -p 1666 -r /srv/perforce/master -u super -P SuperSuper

# Start Perforce automatically.
RUN     mkdir /service/p4d \
        && ln -s /var/lib/service/perforce/run-p4d /service/p4d/run

# Configure subversion server
RUN     useradd -d /srv/svn -m svn

USER    svn
RUN     svnadmin create /srv/svn
RUN     chown -R svn:svn /srv/svn

USER    root

RUN     mkdir /service/svn \
        && ln -s /var/lib/service/subversion/run /service/svn/run

COPY    service /var/lib/service

RUN     mkdir -p /service/buildbot-py2 /service/buildbot-py3 \
        && ln -s /var/lib/service/buildbot/run /service/buildbot-py2/run \
        && ln -s /var/lib/service/buildbot/run /service/buildbot-py3/run

RUN     for pyver in py2 py3; do \
            for worker in add full-clean full-clobber full-copy full-fresh incremental; do \
                mkdir -p /service/worker-$pyver-$worker \
                && ln -s /var/lib/service/worker/run /service/worker-$pyver-$worker/run; \
            done; \
        done


RUN     useradd -m buildbot

USER    buildbot

RUN     virtualenv -p python2.7 --system-site-packages ~/venv/py2 \
        && virtualenv -p python3.5 --system-site-packages ~/venv/py3

RUN     ~/venv/py2/bin/pip install 'buildbot[bundle]' buildbot-grid-view buildbot-worker \
        && ~/venv/py3/bin/pip install 'buildbot[bundle]' buildbot-grid-view buildbot-worker

RUN     ~/venv/py2/bin/buildbot create-master ~/buildbot-py2 \
        && ~/venv/py3/bin/buildbot create-master ~/buildbot-py3

RUN     ln -s ~/buildbot/master.cfg ~/buildbot-py2/master.cfg \
        && ln -s ~/buildbot/master.cfg ~/buildbot-py3/master.cfg

COPY    buildbot /home/buildbot/buildbot/
COPY    buildbot/buildbot.tac /home/buildbot/buildbot-py2/buildbot.tac
COPY    buildbot/buildbot.tac /home/buildbot/buildbot-py3/buildbot.tac

RUN     for pyver in py2 py3; do \
            for worker in add full-clean full-clobber full-copy full-fresh incremental; do \
                mkdir -p ~/worker/$pyver-$worker \
                && ln -s ~/buildbot/worker.tac ~/worker/$pyver-$worker/buildbot.tac; \
            done; \
        done

USER    root

RUN     chown -R buildbot:buildbot ~buildbot/buildbot ~buildbot/worker

ENV     PY2_WWW_PORT=8010 PY2_PB_PORT=9989
ENV     PY3_WWW_PORT=8011 PY3_PB_PORT=9990
EXPOSE  8010 8011

CMD     ["runsvdir", "/service"]
