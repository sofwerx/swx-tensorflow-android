FROM tensorflow/tensorflow:1.4.0-devel-gpu

WORKDIR /tensorflow

RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Sets language to UTF8 : this works in pretty much all cases
ENV LANG en_US.UTF-8
RUN locale-gen $LANG

ENV DOCKER_ANDROID_LANG en_US
ENV DOCKER_ANDROID_DISPLAY_NAME mobileci-docker

# Never ask for confirmations
ENV DEBIAN_FRONTEND noninteractive

# Update apt-get
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -yq \
      libc6:i386 \
      build-essential \
      libssl-dev \
      ruby \
      ruby-dev \
      unzip \
      locales \
      --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler

# Install Java
RUN apt-add-repository ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get -y install openjdk-8-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Download and untar Android SDK tools
RUN mkdir -p /opt/android-sdk && \
    wget https://dl.google.com/android/repository/tools_r25.2.3-linux.zip -O tools.zip && \
    unzip tools.zip -d /opt/android-sdk && \
    rm tools.zip

# Set environment variable
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:$PATH

RUN mkdir -p $ANDROID_HOME/licenses && \
    echo -e "8933bad161af4178b1185d1a37fbf41ea5269c55" > $ANDROID_HOME/licenses/android-sdk-license && \
    echo -e "d56f5187479451eabf01fb78af6dfcb131a6481e" >> $ANDROID_HOME/licenses/android-sdk-license && \
    echo -e "84831b9409646a918e30573bab4c9c91346d8abd" >> $ANDROID_HOME/licenses/android-sdk-preview-license && \
    echo -e "d975f751698a77b662f1254ddbeed3901e976f5a" >> $ANDROID_HOME/licenses/intel-android-extra-license

# Update and install using sdkmanager 
RUN $ANDROID_HOME/tools/bin/sdkmanager "tools" "platform-tools"
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;26.0.2" "build-tools;25.0.3"
RUN $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-26" "platforms;android-25" "platforms;android-24" "platforms;android-23"
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;android;m2repository" "extras;google;m2repository"
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2"
ENV LD_LIBRARY_PATH ${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/qt/lib

# Install Android NDK
ENV ANDROID_NDK_VERSION r15c
RUN wget http://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
    unzip android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
    mv android-ndk-${ANDROID_NDK_VERSION} /opt/android-ndk && \
    rm android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip

# download and install Gradle
ENV GRADLE_VERSION 4.3
RUN cd /opt && \
    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip gradle*.zip && \
    mv gradle-${GRADLE_VERSION} gradle && \
    rm gradle*.zip
ENV GRADLE_HOME /opt/gradle

# Environment variables
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV ANDROID_NDK_HOME /opt/android-ndk

ENV PATH ${INFER_HOME}/bin:${PATH}
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/tools/bin
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/26.0.2
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/25.0.3
ENV PATH $PATH:$ANDROID_NDK_HOME
ENV PATH $PATH:$JAVA_HOME/bin
ENV PATH $PATH:$GRADLE_HOME/bin

# Support Gradle
ENV TERM dumb
ENV JAVA_OPTS "-Xms4096m -Xmx4096m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

RUN mkdir -p $ANDROID_HOME/licenses && \
    echo "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > $ANDROID_HOME/licenses/android-sdk-license && \
    echo "\nd56f5187479451eabf01fb78af6dfcb131a6481e" >> $ANDROID_HOME/licenses/android-sdk-license && \
    echo "\ne6b7c2ab7fa2298c15165e9583d0acf0b04a2232" >> $ANDROID_HOME/licenses/android-sdk-license && \
    echo "\n84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license && \
    echo "\nd975f751698a77b662f1254ddbeed3901e976f5a" > $ANDROID_HOME/licenses/intel-android-extra-license

RUN mkdir -p ~/.android $ANDROID_HOME/.android && \
    touch ~/.android/repositories.cfg $ANDROID_HOME/.android/repositories.cfg

# Updating everything again
RUN yes | sdkmanager --update

WORKDIR /tensorflow

RUN git remote add sofwerx https://github.com/sofwerx/tensorflow && \
    git fetch --all && \
    git reset --hard sofwerx/master

WORKDIR /tensorflow/tensorflow/examples/android

RUN sed -i -e "s/def nativeBuildSystem = 'bazel'/def nativeBuildSystem = 'cmake'/" build.gradle

RUN find /tensorflow -name '*.pb' -print

RUN gradle build

# Include David's trained model
ARG TRAVIS_TAG=v1.0.0
RUN cd /tensorflow/tensorflow/examples/android/assets/ && \
    curl -sLo retrained_graph.pb https://github.com/sofwerx/swx-tensorflow-android/releases/download/${TRAVIS_TAG}/retrained_graph.pb

RUN gradle build

RUN find /tensorflow -name '*.pb' -print

WORKDIR /outputs
VOLUME /outputs

# The built APK files are now available here:
# /tensorflow/tensorflow/examples/android/gradleBuild/outputs/apk/android-release-unsigned.apk
# /tensorflow/tensorflow/examples/android/gradleBuild/outputs/apk/android-debug.apk

RUN find /tensorflow -name '*.apk' -print

# This will copy the apk files to the /outputs folder
CMD bash -c "\
      cp /tensorflow/tensorflow/examples/android/gradleBuild/outputs/apk/android-release-unsigned.apk /outputs ; \
      cp /tensorflow/tensorflow/examples/android/gradleBuild/outputs/apk/android-debug.apk /outputs \
    "
