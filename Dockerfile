FROM debian:bullseye-slim as base-image

FROM base-image as bitlbee-build

ARG BITLBEE_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential git python autoconf automake libtool intltool flex libglib2.0-dev \
    libssl-dev libpurple-dev libjson-glib-dev libgcrypt20-dev libotr5-dev cmake \
 && cd /tmp \
 && git clone -n https://github.com/bitlbee/bitlbee.git \
 && cd bitlbee \
 && git checkout ${BITLBEE_VERSION} \
 && ./configure --purple=1 --otr=plugin --ssl=openssl --prefix=/usr --etcdir=/etc/bitlbee \
 && make -j$(nproc --ignore 2) \
 && make install-bin \
 && make install-doc \
 && make install-dev \
 && make install-etc \
 && strip /usr/sbin/bitlbee \
 && touch /nowhere

# ---

FROM bitlbee-build as otr-install

ARG OTR=1

RUN echo OTR=${OTR} > /tmp/status \
 && if [ ${OTR} -eq 1 ]; \
     then cd /tmp/bitlbee \
       && make install-plugin-otr; \
     else mkdir -p /usr/lib/bitlbee \
       && ln -sf /nowhere /usr/lib/bitlbee/otr.so; \
    fi

# ---

FROM bitlbee-build as facebook-build

ARG FACEBOOK=1
ARG FACEBOOK_VERSION

RUN echo FACEBOOK=${FACEBOOK} > /tmp/status \
 && if [ ${FACEBOOK} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/bitlbee/bitlbee-facebook.git \
       && cd bitlbee-facebook \
       && git checkout ${FACEBOOK_VERSION} \
       && ./autogen.sh \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/bitlbee/facebook.so; \
     else mkdir -p /usr/lib/bitlbee \
        && ln -sf /nowhere /usr/lib/bitlbee/facebook.so \
       && ln -sf /nowhere /usr/lib/bitlbee/facebook.la; \
    fi

# ---

FROM bitlbee-build as steam-build

ARG STEAM=1
ARG STEAM_VERSION

RUN echo STEAM=${STEAM} > /tmp/status \
 && if [ ${STEAM} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/bitlbee/bitlbee-steam.git \
       && cd bitlbee-steam \
       && git checkout ${STEAM_VERSION} \
       && ./autogen.sh \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/bitlbee/steam.so; \
     else mkdir -p /usr/lib/bitlbee \
       && ln -sf /nowhere /usr/lib/bitlbee/steam.so \
       && ln -sf /nowhere /usr/lib/bitlbee/steam.la; \
    fi

# ---

FROM bitlbee-build as skypeweb-build

ARG SKYPEWEB=1
ARG SKYPEWEB_VERSION

RUN echo SKYPEWEB=${SKYPEWEB} > /tmp/status \
 && if [ ${SKYPEWEB} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/EionRobb/skype4pidgin.git \
       && cd skype4pidgin \
       && git checkout ${SKYPEWEB_VERSION} \
       && cd skypeweb \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/libskypeweb.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libskypeweb.so; \
    fi

# ---

FROM bitlbee-build as telegram-build

ARG TELEGRAM=1
ARG TELEGRAM_VERSION

RUN echo TELEGRAM=${TELEGRAM} > /tmp/status \
 && if [ ${TELEGRAM} -eq 1 ]; \
     then cd /tmp \
       && apt-get update \
       && apt-get install -y --no-install-recommends cmake gperf libwebp-dev libpng-dev \
       && git clone -n https://github.com/ars3niy/tdlib-purple.git \
       && cd tdlib-purple \
       && git checkout ${TELEGRAM_VERSION} \
       && TDLIB_REQ_VERSION=$(grep -o "tdlib version.*" CMakeLists.txt| tail -1 | awk '{print $3}') \
       && cd /tmp \
       && git clone -n https://github.com/tdlib/td.git tdlib \
       && cd tdlib \
       && TDLIB_VERSION=$(git log --pretty=format:"%h%x09%s" | grep "Update version to ${TDLIB_REQ_VERSION}" | awk '{print $1}') \
       && git checkout ${TDLIB_VERSION} \
       && mkdir build \
       && cd build \
       && cmake -DCMAKE_BUILD_TYPE=Release .. \
       && make -j$(nproc --ignore 2) \
       && make install \
       && cd /tmp/tdlib-purple \
       && mkdir build \
       && cd build \
       && cmake -DTd_DIR=/usr/local/lib/cmake/Td -DNoLottie=True -DNoVoip=True .. \
       && make -j$(nproc --ignore 2)\
       && make install \
       && strip /usr/lib/purple-2/libtelegram-tdlib.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libtelegram-tdlib.so \
       && ln -sf /nowhere /usr/local/share/metainfo/tdlib-purple.metainfo.xml \
       && ln -sf /nowhere /usr/local/share/locale; \
    fi

# ---

FROM bitlbee-build as hangouts-build

ARG HANGOUTS=1
ARG HANGOUTS_VERSION

RUN echo HANGOUTS=${HANGOUTS} > /tmp/status \
 && if [ ${HANGOUTS} -eq 1 ]; \
     then cd /tmp \
       && apt-get update \
       && apt-get install -y --no-install-recommends libprotobuf-c-dev protobuf-c-compiler \
       && git clone -n https://github.com/EionRobb/purple-hangouts.git \
       && cd purple-hangouts \
       && git checkout ${HANGOUTS_VERSION} \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/libhangouts.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libhangouts.so; \
    fi

# ---

FROM bitlbee-build as slack-build

ARG SLACK=1
ARG SLACK_VERSION

SHELL [ "/bin/bash", "-c" ]

RUN echo SLACK=${SLACK} > /tmp/status \
 && if [ ${SLACK} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/dylex/slack-libpurple.git \
       && cd slack-libpurple \
       && git checkout ${SLACK_VERSION} \
       && make -j$(nproc --ignore 2) \
       && install -d /usr/share/pixmaps/pidgin/protocols/{16,22,48} \
       && make install \
       && strip /usr/lib/purple-2/libslack.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libslack.so; \
    fi

# ---

FROM bitlbee-build as sipe-build

ARG SIPE=1
ARG SIPE_VERSION

RUN echo SIPE=${SIPE} > /tmp/status \
 && if [ ${SIPE} -eq 1 ]; \
     then cd /tmp \
       && apt-get update \
       && apt-get install -y --no-install-recommends libxml2-dev autopoint \
       && git clone -n https://repo.or.cz/siplcs.git \
       && cd siplcs \
       && git checkout ${SIPE_VERSION} \
       && ./autogen.sh \
       && ./configure --prefix=/usr \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/libsipe.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libsipe.so \
       && ln -sf /nowhere /usr/lib/purple-2/libsipe.la \
       && ln -sf /nowhere /usr/share/locale; \
    fi

# ---

FROM bitlbee-build as discord-build

ARG DISCORD=1
ARG DISCORD_VERSION

RUN echo DISCORD=${DISCORD} > /tmp/status \
 && if [ ${DISCORD} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/sm00th/bitlbee-discord.git \
       && cd bitlbee-discord \
       && git checkout ${DISCORD_VERSION} \
       && ./autogen.sh \
       && ./configure --prefix=/usr \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/bitlbee/discord.so; \
     else mkdir -p /usr/lib/bitlbee \
       && ln -sf /nowhere /usr/lib/bitlbee/discord.so \
       && ln -sf /nowhere /usr/lib/bitlbee/discord.la \
       && ln -sf /nowhere /usr/share/bitlbee/discord-help.txt; \
    fi

# ---

FROM bitlbee-build as rocketchat-build

ARG ROCKETCHAT=1
ARG ROCKETCHAT_VERSION

RUN echo ROCKETCHAT=${ROCKETCHAT} > /tmp/status \
 && if [ ${ROCKETCHAT} -eq 1 ]; \
     then cd /tmp \
       && apt-get update \
       && apt-get install -y --no-install-recommends libmarkdown2-dev \
       && git clone -n https://github.com/EionRobb/purple-rocketchat.git \
       && cd purple-rocketchat \
       && git checkout ${ROCKETCHAT_VERSION} \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/librocketchat.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/librocketchat.so; \
    fi

# ---

FROM bitlbee-build as mastodon-build

ARG MASTODON=1
ARG MASTODON_VERSION

RUN echo MASTODON=${MASTODON} > /tmp/status \
 && if [ ${MASTODON} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/kensanata/bitlbee-mastodon \
       && cd bitlbee-mastodon \
       && git checkout ${MASTODON_VERSION} \
       && sh ./autogen.sh \
       && ./configure \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/bitlbee/mastodon.so; \
     else mkdir -p /usr/lib/bitlbee \
       && ln -sf /nowhere /usr/lib/bitlbee/mastodon.so \
       && ln -sf /nowhere /usr/lib/bitlbee/mastodon.la \
       && ln -sf /nowhere /usr/share/bitlbee/mastodon-help.txt; \
    fi

# ---

FROM bitlbee-build as matrix-build

ARG MATRIX=1
ARG MATRIX_VERSION

SHELL [ "/bin/bash", "-c" ]

COPY matrix-e2e.c.patch /tmp/matrix-e2e.c.patch

RUN echo MATRIX=${MATRIX} > /tmp/status \
 && if [ ${MATRIX} -eq 1 ]; \
     then cd /tmp \
       && apt-get update \
       && apt-get install -y --no-install-recommends libsqlite3-dev libhttp-parser-dev libolm-dev patch \
       && git clone -n https://github.com/matrix-org/purple-matrix \
       && cd purple-matrix \
       && git checkout ${MATRIX_VERSION} \
       && if [ $(uname -m) == "armv7l" ]; then patch < ../matrix-e2e.c.patch; fi \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/libmatrix.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libmatrix.so; \
    fi

# ---

FROM bitlbee-build as signald-build

ARG SIGNAL=1
ARG SIGNAL_VERSION

RUN echo SIGNAL=${SIGNAL} > /tmp/status \
 && if [ ${SIGNAL} -eq 1 ]; \
     then cd /tmp \
       && apt-get update \
       && apt-get install -y --no-install-recommends libmagic-dev \
       && git clone -n https://github.com/hoehermann/purple-signald \
       && cd purple-signald \
       && git checkout ${SIGNAL_VERSION} \
       && git submodule init \
       && git submodule update \
       && mkdir -p build \
       && cd build \
       && cmake .. \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/libsignald.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libsignald.so; \
    fi

# ---

FROM bitlbee-build as icyque-build

ARG ICYQUE=1
ARG ICYQUE_VERSION

RUN echo ICYQUE=${ICYQUE} > /tmp/status \
 && if [ ${ICYQUE} -eq 1 ]; \
     then cd /tmp \
       && git clone -n https://github.com/EionRobb/icyque.git \
       && cd icyque \
       && git checkout ${ICYQUE_VERSION} \
       && make -j$(nproc --ignore 2) \
       && make install \
       && strip /usr/lib/purple-2/libicyque.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libicyque.so; \
    fi

# ---

FROM bitlbee-build as whatsapp-build

ARG WHATSAPP=1
ARG WHATSAPP_VERSION

RUN echo WHATSAPP=${WHATSAPP} > /tmp/status \
 && if [ ${WHATSAPP} -eq 1 ]; \
     then cd /tmp \
       && echo "deb http://deb.debian.org/debian bullseye-backports main" | tee -a /etc/apt/sources.list \
       && apt-get update \
       && apt-get install -y --no-install-recommends -t bullseye-backports golang-go \
       && apt-get install -y --no-install-recommends cmake pkg-config \
       && git clone -n https://github.com/hoehermann/purple-gowhatsapp.git \
       && cd purple-gowhatsapp \
       && git checkout ${WHATSAPP_VERSION} \
       && mkdir build \
       && cd build \
       && cmake .. \
       && make -j$(nproc --ignore 2) \
       && make install/strip \
       && strip /usr/lib/purple-2/libwhatsmeow.so; \
     else mkdir -p /usr/lib/purple-2 \
       && ln -sf /nowhere /usr/lib/purple-2/libwhatsmeow.so; \
    fi

# ---

FROM base-image as bitlbee-plugins

COPY --from=bitlbee-build /usr/sbin/bitlbee /tmp/usr/sbin/bitlbee
COPY --from=bitlbee-build /usr/share/man/man8/bitlbee.8 /tmp/usr/share/man/man8/bitlbee.8
COPY --from=bitlbee-build /usr/share/man/man5/bitlbee.conf.5 /tmp/usr/share/man/man5/bitlbee.conf.5
COPY --from=bitlbee-build /usr/share/bitlbee /tmp/usr/share/bitlbee
COPY --from=bitlbee-build /usr/lib/pkgconfig/bitlbee.pc /tmp/usr/lib/pkgconfig/bitlbee.pc
COPY --from=bitlbee-build /etc/bitlbee /tmp/etc/bitlbee

COPY --from=otr-install /usr/lib/bitlbee/otr.so /tmp/usr/lib/bitlbee/otr.so
COPY --from=otr-install /tmp/status /tmp/plugin/otr

COPY --from=facebook-build /usr/lib/bitlbee/facebook.so /tmp/usr/lib/bitlbee/facebook.so
COPY --from=facebook-build /usr/lib/bitlbee/facebook.la /tmp/usr/lib/bitlbee/facebook.la
COPY --from=facebook-build /tmp/status /tmp/plugin/facebook

COPY --from=steam-build /usr/lib/bitlbee/steam.so /tmp/usr/lib/bitlbee/steam.so
COPY --from=steam-build /usr/lib/bitlbee/steam.la /tmp/usr/lib/bitlbee/steam.la
COPY --from=steam-build /tmp/status /tmp/plugin/steam

COPY --from=skypeweb-build /usr/lib/purple-2/libskypeweb.so /tmp/usr/lib/purple-2/libskypeweb.so
COPY --from=skypeweb-build /tmp/status /tmp/plugin/skypeweb

COPY --from=telegram-build /usr/lib/purple-2/libtelegram-tdlib.so /tmp/usr/lib/purple-2/libtelegram-tdlib.so
COPY --from=telegram-build /usr/local/share/metainfo/tdlib-purple.metainfo.xml /tmp/usr/local/share/metainfo/tdlib-purple.metainfo.xml
COPY --from=telegram-build /usr/local/share/locale /tmp/usr/local/share/locale
COPY --from=telegram-build /tmp/status /tmp/plugin/telegram

COPY --from=hangouts-build /usr/lib/purple-2/libhangouts.so /tmp/usr/lib/purple-2/libhangouts.so
COPY --from=hangouts-build /tmp/status /tmp/plugin/hangouts

COPY --from=slack-build /usr/lib/purple-2/libslack.so /tmp/usr/lib/purple-2/libslack.so
COPY --from=slack-build /tmp/status /tmp/plugin/slack

COPY --from=sipe-build /usr/lib/purple-2/libsipe.so /tmp/usr/lib/purple-2/libsipe.so
COPY --from=sipe-build /usr/lib/purple-2/libsipe.la /tmp/usr/lib/purple-2/libsipe.la
COPY --from=sipe-build /usr/share/locale /tmp/usr/share/locale
COPY --from=sipe-build /tmp/status /tmp/plugin/sipe

COPY --from=discord-build /usr/lib/bitlbee/discord.so /tmp/usr/lib/bitlbee/discord.so
COPY --from=discord-build /usr/lib/bitlbee/discord.la /tmp/usr/lib/bitlbee/discord.la
COPY --from=discord-build /usr/share/bitlbee/discord-help.txt /tmp/usr/share/bitlbee/discord-help.txt
COPY --from=discord-build /tmp/status /tmp/plugin/discord

COPY --from=rocketchat-build /usr/lib/purple-2/librocketchat.so /tmp/usr/lib/purple-2/librocketchat.so
COPY --from=rocketchat-build /tmp/status /tmp/plugin/rocketchat

COPY --from=mastodon-build /usr/lib/bitlbee/mastodon.so /tmp/usr/lib/bitlbee/mastodon.so
COPY --from=mastodon-build /usr/lib/bitlbee/mastodon.la /tmp/usr/lib/bitlbee/mastodon.la
COPY --from=mastodon-build /usr/share/bitlbee/mastodon-help.txt /tmp/usr/share/bitlbee/mastodon-help.txt
COPY --from=mastodon-build /tmp/status /tmp/plugin/mastodon

COPY --from=matrix-build /usr/lib/purple-2/libmatrix.so /tmp/usr/lib/purple-2/libmatrix.so
COPY --from=matrix-build /tmp/status /tmp/plugin/matrix

COPY --from=signald-build /usr/lib/purple-2/libsignald.so /tmp/usr/lib/purple-2/libsignald.so
COPY --from=signald-build /tmp/status /tmp/plugin/signald

COPY --from=icyque-build /usr/lib/purple-2/libicyque.so /tmp/usr/lib/purple-2/libicyque.so
COPY --from=icyque-build /tmp/status /tmp/plugin/icyque

COPY --from=whatsapp-build /usr/lib/purple-2/libwhatsmeow.so /tmp/usr/lib/purple-2/libwhatsmeow.so
COPY --from=whatsapp-build /tmp/status /tmp/plugin/whatsapp

RUN apt-get update \
 && apt-get install -y --no-install-recommends findutils \
 && find /tmp/ -type f -empty -delete \
 && find /tmp/ -type d -empty -delete \
 && cat /tmp/plugin/* > /tmp/plugins \
 && rm -rf /tmp/plugin

# ---

FROM base-image as bitlbee-libpurple

COPY --from=bitlbee-plugins /tmp/ /

ARG PKGS="tzdata libglib2.0-0 libssl1.1 libpurple0 libtcl8.6 libtk8.6 ca-certificates"

SHELL [ "/bin/bash", "-c" ]

RUN groupadd -g 101 -r bitlbee \
 && useradd -u 101 -r -g bitlbee -m -d /var/lib/bitlbee bitlbee \
 && install -d -m 750 -o bitlbee -g bitlbee /var/lib/bitlbee \
 && source /plugins \
 && if [ ${OTR} -eq 1 ]; then PKGS="${PKGS} libotr5"; fi \
 && if [ ${FACEBOOK} -eq 1 ] || [ ${SKYPEWEB} -eq 1 ] || [ ${HANGOUTS} -eq 1 ] \
 || [ ${ROCKETCHAT} -eq 1 ] || [ ${MATRIX} -eq 1 ] || [ ${SIGNAL} -eq 1 ] \
 || [ ${ICYQUE} -eq 1 ]; then PKGS="${PKGS} libjson-glib-1.0-0"; fi \
 && if [ ${STEAM} -eq 1 ] || [ ${TELEGRAM} -eq 1 ] || [ ${MATRIX} -eq 1 ]; then PKGS="${PKGS} libgcrypt20"; fi \
 && if [ ${TELEGRAM} -eq 1 ]; then PKGS="${PKGS} zlib1g libwebp6 libpng16-16 libstdc++6"; fi \
 && if [ ${HANGOUTS} -eq 1 ] || [ ${SIGNAL} -eq 1 ]; then PKGS="${PKGS} libprotobuf-c1"; fi \
 && if [ ${SIGNAL} -eq 1 ]; then PKGS="${PKGS} libmagic1"; fi \
 && if [ ${SIPE} -eq 1 ]; then PKGS="${PKGS} libxml2"; fi \
 && if [ ${ROCKETCHAT} -eq 1 ]; then PKGS="${PKGS} libmarkdown2"; fi \
 && if [ ${MATRIX} -eq 1 ]; then PKGS="${PKGS} libsqlite3-0 libhttp-parser2.9 libolm2"; fi \
 && apt-get update \
 && apt-get install -y --no-install-recommends ${PKGS} \
 && apt-get clean \
 && rm /plugins

EXPOSE 6667

CMD [ "/usr/sbin/bitlbee", "-F", "-n", "-u", "bitlbee" ]
