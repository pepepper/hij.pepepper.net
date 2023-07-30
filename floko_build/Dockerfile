FROM ubuntu:22.04

ENV USER=android

RUN groupadd -r $USER && useradd -r -m -g $USER $USER && usermod -u 1000 $USER

RUN apt update \
    &&  apt install -y ca-certificates \
        bc bison build-essential ccache curl \
        flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick \
        lib32ncurses5-dev lib32readline-dev lib32z1-dev libelf-dev \
        liblz4-tool libncurses5 libncurses5-dev \
        libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush python-is-python3 rsync \
        schedtool squashfs-tools xsltproc \
        zip zlib1g-dev \
    &&  update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://storage.googleapis.com/git-repo-downloads/repo --output "/bin/repo" \
    && chmod a+x /bin/repo

RUN git config --global user.email "docker@example.com" \
    && git config --global user.name "Docker Android Build Image" \
    && git lfs install

COPY build.sh /build.sh

ENTRYPOINT ["/build.sh", "source"]
CMD ["barbet", "-s"]
