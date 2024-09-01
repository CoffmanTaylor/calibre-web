FROM ubuntu:noble AS base

WORKDIR /opt/calibre-web

# Setup conda
COPY --from=continuumio/miniconda3 /opt/conda /opt/conda
ENV PATH=/opt/conda/bin:$PATH
RUN set -ex && \
    conda config --set always_yes yes --set changeps1 no && \
    conda info -a && \
    conda config --add channels conda-forge && \
    conda install --quiet --freeze-installed \
        python==3.11 \
        pip

# Fetch apt deps
FROM base AS deps

# APT-able deps
RUN apt update && \ 
    apt install -y \
        gcc \
        imagemagick \
        libmagic-dev

ADD ./requirements.txt .
ADD ./optional-requirements.txt .
RUN pip install --upgrade -r requirements.txt -r optional-requirements.txt

# Calibre
FROM base AS calibre 

RUN apt update && \ 
    apt install -y \
        gcc \
        xdg-utils \
        wget \
        xz-utils \
        libopengl0 \
        libxcb-cursor0 \
        libxkbcommon-x11-0

ADD https://download.calibre-ebook.com/linux-installer.sh /tmp/calibre-install.sh
RUN sh /tmp/calibre-install.sh isolated=y

# Prod
FROM deps AS prod

# Get the binary deps
ADD https://github.com/pgaskin/kepubify/releases/latest/download/kepubify-linux-64bit /opt/kepubify/kepubify
COPY --from=calibre /opt/calibre /opt/calibre

ADD . .

CMD ["python", "cps.py", "-p", "/mnt/config/app.db"]
