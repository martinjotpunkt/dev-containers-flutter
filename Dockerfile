# Alpine
ARG ALPINE_VERSION=latest

# Java
ARG JAVA_VERSION=amazon-corretto-21

# Android
# ANDROID_SDK_TOOLS_VERSION Comes from https://developer.android.com/studio/#command-tools
ARG ANDROID_SDK_TOOLS_VERSION=8512546
ARG ANDROID_PLATFORM_VERSION=android-31
ARG ANDROID_BUILD_TOOL_VERSION=33.0.0

# Flutter
ARG FLUTTER_SDK_VERSION=stable
ARG FLUTTER_SDK_REPOSITORY_URL="https://github.com/flutter/flutter.git"

# Glibc
ARG GLIBC_RESOURCE_URL="https://github.com/sgerrand/alpine-pkg-glibc"
ARG GLIBC_VERSION="2.33-r0"

FROM alpine:$ALPINE_VERSION AS build

USER root
WORKDIR /

ARG JAVA_VERSION

ARG GLIBC_VERSION
ARG GLIBC_RESOURCE_URL

ARG ANDROID_SDK_TOOLS_VERSION
ARG ANDROID_PLATFORM_VERSION
ARG ANDROID_BUILD_TOOL_VERSION

ARG FLUTTER_SDK_VERSION
ARG FLUTTER_SDK_REPOSITORY_URL

# Set environment variables
# Glibc
ENV GLIBC_VERSION=$GLIBC_VERSION \
    GLIBC_RESOURCE_URL=$GLIBC_RESOURCE_URL

# Java
ENV JAVA_VERSION=$JAVA_VERSION

# Android
ENV ANDROID_PLATFORM_VERSION=$ANDROID_PLATFORM_VERSION \
    ANDROID_BUILD_TOOL_VERSION=$ANDROID_BUILD_TOOL_VERSION \
    ANDROID_SDK_TOOLS_VERSION=$ANDROID_SDK_TOOLS_VERSION \
    ANDROID_SDK_ROOT=/usr/lib/android-sdk

# Flutter
ENV FLUTTER_SDK_VERSION=$FLUTTER_SDK_VERSION \
    FLUTTER_SDK_REPOSITORY_URL=$FLUTTER_SDK_REPOSITORY_URL \
    FLUTTER_SDK_ROOT=/usr/lib/flutter \
    FLUTTER_PUB_CACHE=/var/tmp/.pub_cache

# Include flutter and android tools in path
ENV PATH="${PATH}:${FLUTTER_SDK_ROOT}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/:${ANDROID_SDK_ROOT}/platform-tools"

# Install linux dependency and utils
# gcompat is needed for clutter https://github.com/flutter/flutter/issues/73260
RUN set -eux; mkdir -p /usr/lib /tmp/glibc \
    #&& echo "flutter:x:101:flutter" >> /etc/group \
    #&& echo "flutter:x:101:101:Flutter user,,,:/home:/sbin/nologin" >> /etc/passwd \
    && apk --no-cache add bash curl git ca-certificates wget unzip tar gcompat \
     libxext libxrender libxtst libxi freetype procps openssh \
    && rm -rf /var/lib/apt/lists/* /var/cache/apk/*


# Get glibc for current architecure
RUN set -eux; wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget -O /tmp/glibc/glibc.apk ${GLIBC_RESOURCE_URL}/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && wget -O /tmp/glibc/glibc-bin.apk ${GLIBC_RESOURCE_URL}/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk

# Download and install Java
RUN set -eux; wget -O /etc/apk/keys/amazoncorretto.rsa.pub https://apk.corretto.aws/amazoncorretto.rsa.pub \
    && echo "https://apk.corretto.aws/" >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache ${JAVA_VERSION} \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/apk/* /usr/share/man/* /usr/share/doc

# Download and install Android Command Line Tools

RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -O /tmp/android-sdk-tools.zip \
    && unzip -q /tmp/android-sdk-tools.zip -d /tmp/ \
    && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools/latest /root/.android \
    && mv /tmp/cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/latest/ \
    && rm -rf /tmp/* \
    && touch /root/.android/repositories.cfg \
    && yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
    && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platform-tools" "emulator" "extras;google;instantapps" \
    && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platforms;${ANDROID_PLATFORM_VERSION}" "build-tools;${ANDROID_BUILD_TOOL_VERSION}"

# Insall Flutter SDK
RUN mkdir -p ${FLUTTER_SDK_ROOT} $FLUTTER_PUB_CACHE \
    && git clone -b ${FLUTTER_SDK_VERSION} --depth 1 ${FLUTTER_SDK_REPOSITORY_URL} ${FLUTTER_SDK_ROOT} \
    && cd "${FLUTTER_SDK_ROOT}" \
    && git gc --prune=all \
    && cd "${FLUTTER_SDK_ROOT}/bin" \
    && dart --disable-analytics \
    && yes "y" | flutter doctor --android-licenses \
    && flutter config --no-analytics --enable-android \
    && flutter --disable-analytics \
    && flutter precache --universal --android

# Default shell to bash
SHELL ["/bin/bash", "-c"]
