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

# Do the Python 2 workers first.
COPY    buildbot/worker.tac /home/buildbot/worker/py2-add/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py2-full-clean/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py2-full-clobber/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py2-full-copy/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py2-full-fresh/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py2-incremental/buildbot.tac

# Python 3 workers second.
COPY    buildbot/worker.tac /home/buildbot/worker/py3-add/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py3-full-clean/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py3-full-clobber/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py3-full-copy/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py3-full-fresh/buildbot.tac
COPY    buildbot/worker.tac /home/buildbot/worker/py3-incremental/buildbot.tac

COPY    buildbot /home/buildbot/buildbot


USER    root

COPY    service /var/lib/service

RUN     mkdir -p /service/buildbot/py2 /service/buildbot/py3 /service/worker \
        && ln -s /var/lib/service/buildbot/run /service/buildbot/py2/run \
        && ln -s /var/lib/service/buildbot/run /service/buildbot/py3/run

ENV     PY2_WWW_PORT=8010 PY2_PB_PORT=9989
ENV     PY3_WWW_PORT=8011 PY3_PB_PORT=9990
EXPOSE  8010 8011

CMD     ["runsvdir", "/service"]
