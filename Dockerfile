FROM xanter/wine:latest as inno

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends procps xvfb \
    && rm -rf /var/lib/apt/lists/*

# get at least error information from wine
ENV WINEDEBUG -all,err+all

# Run virtual X buffer on this port
ENV DISPLAY :99

COPY opt /opt
RUN chmod +x /opt/bin/*
ENV PATH $PATH:/opt/bin

USER xclient
ENV INNOSETUP_VERSION 6.2.0

# Install Inno Setup binaries
RUN curl -SL "http://files.jrsoftware.org/is/6/innosetup-${INNOSETUP_VERSION}.exe" -o is.exe \
    && wine-x11-run wine is.exe /SP- /VERYSILENT /ALLUSERS /SUPPRESSMSGBOXES \
    && rm is.exe


FROM debian:bullseye-slim

RUN addgroup --system xusers \
  && adduser \
			--home /home/xclient \
			--disabled-password \
			--shell /bin/bash \
			--gecos "user for running an xclient application" \
			--ingroup xusers \
			--quiet \
			xclient

# Install some tools required for creating the image
# Install wine and related packages
RUN dpkg --add-architecture i386 \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
                wine \
                wine32 \
                zip unzip \
        && rm -rf /var/lib/apt/lists/*

COPY opt /opt
RUN chmod +x /opt/bin/*
ENV PATH $PATH:/opt/bin

COPY --from=inno /home/xclient/.wine /home/xclient/.wine
RUN mkdir /work \
    && chown xclient:xusers -R /home/xclient/.wine /work

# Wine really doesn't like to be run as root, so let's use a non-root user
USER xclient
ENV HOME /home/xclient
ENV WINEPREFIX /home/xclient/.wine
ENV WINEARCH win32

WORKDIR /work
# ENTRYPOINT ["wine-x11-run", "iscc"]
ENTRYPOINT ["iscc"]
