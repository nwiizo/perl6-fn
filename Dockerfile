FROM alpine:latest
LABEL version="2.0.4" maintainer="syu.m.5151@gmail.com" perl6version="2018.12"

# Environment
ENV PATH="/root/.rakudobrew/bin:${PATH}" \
    PKGS="curl git perl" \
    PKGS_TMP="curl-dev linux-headers make gcc musl-dev wget"

# Basic setup, programs and init
RUN apk update && apk upgrade \
    && apk add --no-cache $PKGS $PKGS_TMP \
    && git clone https://github.com/tadzik/rakudobrew ~/.rakudobrew \
    && echo 'export PATH=~/.rakudobrew/bin:$PATH\neval "$(/root/.rakudobrew/bin/rakudobrew init -)"' >> /etc/profile \
    && rakudobrew build moar \
    && curl -L https://cpanmin.us | perl - App::cpanminus \
    && cpanm Test::Harness --no-wget \
    && git clone https://github.com/ugexe/zef.git \
    && prove -v -e 'perl6 -I zef/lib' zef/t \
    && perl6 -Izef/lib zef/bin/zef --verbose install ./zef \
    && rakudobrew rehash \
    && zef install Linenoise \
    && apk del $PKGS_TMP \
    && RAKUDO_VERSION=`sed "s/\n//" /root/.rakudobrew/CURRENT` \
       rm -rf /root/.rakudobrew/${RAKUDO_VERSION}/src /root/zef \
       /root/.rakudobrew/git_reference \
    # Print this as a check (really unnecessary)
    && rakudobrew init
# Allows you to add additional packages via build-arg
ARG ADDITIONAL_PACKAGE

# Alternatively use ADD https:// (which will not be cached by Docker builder)
RUN apk --no-cache add curl ${ADDITIONAL_PACKAGE} \
    && echo "Pulling watchdog binary from Github." \
    && curl -sSL https://github.com/openfaas/faas/releases/download/0.9.6/fwatchdog > /usr/bin/fwatchdog \
    && chmod +x /usr/bin/fwatchdog \
    && apk del curl --no-cache

# Add non root user
RUN addgroup -S app && adduser app -S -G app

COPY index.pm .

WORKDIR /home/app/

COPY index.pm .

RUN chown -R app /home/app
RUN cp /root/.rakudobrew/bin/perl6 /usr/local/bin/perl6

USER app
ENV PATH=$PATH:/home/app/.local/bin
RUN mkdir -p function

USER root
COPY function function
RUN chown -R app:app ./
#USER app

ENV fprocess="perl6 index.pm"
EXPOSE 8080

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]
