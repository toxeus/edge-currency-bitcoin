FROM ubuntu:17.10


ENV ANDROID_HOME="/android-ndk" PATH="/node-v8.11.1-linux-x64/bin:$PATH"

RUN apt-get update && \
    apt-get install -y default-jdk-headless git unzip wget xz-utils make g++ python && \
    cd /tmp && wget https://nodejs.org/dist/v8.11.1/node-v8.11.1-linux-x64.tar.xz && \
    wget -qO- https://nodejs.org/dist/v8.11.1/SHASUMS256.txt | grep node-v8.11.1-linux-x64.tar.xz | sha256sum -c - && \
    cd / && tar xf /tmp/node-v8.11.1-linux-x64.tar.xz && \
    rm /tmp/node-v8.11.1-linux-x64.tar.xz && \
    npm install -g react-native-cli yarn node-gyp && \
    mkdir $ANDROID_HOME && \
    wget -O/tmp/android-sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip && \
    bash -c 'sha256sum -c - <<< "444e22ce8ca0f67353bda4b85175ed3731cae3ffa695ca18119cbacef1c1bea0 /tmp/android-sdk-tools.zip"' && \
    unzip /tmp/android-sdk-tools.zip -d $ANDROID_HOME && \
    rm /tmp/android-sdk-tools.zip && \
    yes | $ANDROID_HOME/tools/bin/sdkmanager 'ndk-bundle' && \
    git clone https://github.com/Airbitz/edge-react-gui.git /src/edge-react-gui && \
    cd /src/edge-react-gui/ && yarn install && \
    cp env.example.json env.json && \
    cd android && ./gradlew assembleRelease

ARG AIRBITZ_API_KEY
ARG HOCKEYAPP_API_ID=0123456789abcdef0123456789abcdef

ADD . /src/edge-currency-bitcoin

RUN [ -n "$AIRBITZ_API_KEY" ] || (echo 'FAILED: please set $AIRBITZ_API_KEY using `docker build --build-args`'; return 1) && \
    cd /src/edge-currency-bitcoin && yarn install && \
    cd /src/edge-react-gui/ && \
    sed -i s/AIRBITZ_ANDROID_API_KEY/$AIRBITZ_API_KEY/ env.json && \
    sed -i s/HOCKEYAPP_ANDROID_ID/$HOCKEYAPP_API_ID/ env.json && \
    sed -i s/HOCKEYAPP_ANDROID_API_ID/$HOCKEYAPP_API_ID/ env.json && \
    yarn run updot edge-currency-bitcoin && \
    yarn run postinstall && \
    yarn run android:release
