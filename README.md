# sofwerx/swx-tensorflow-android

[![Build Status](https://travis-ci.org/sofwerx/swx-tensorflow-android.svg)](https://travis-ci.org/sofwerx/swx-tensorflow-android)

This is a docker build harness to compile a forked copy of tensorflow android client from source.

## Usage:

    docker-compose up

Then look in the `outputs/` folder for the apk files.

## Travis-CI Builds

The goal here is rapid iteration and tensorflow model testing on android devices.

The .travis.yml in this project directs Travis-CI to do a cloud-based build on every github push.

This builds the [sofwerx/tensorflow](https://github.com/sofwerx/tensorflow) github repository fork from the [tensorflow/examples/sofwerx-android](https://github.com/sofwerx/tensorflow/tree/master/tensorflow/examples/sofwerx-android) folder (which is merely a renamed copy of the [tensorflow/examples/android](https://github.com/sofwerx/tensorflow/tree/master/tensorflow/examples/android) folder including an updated appid of `org.sofwerx.tensorflow.demo`).

Though only used for build caching purposes, the successfully built resultant docker image is always pushed to Docker Hub as [sofwerx/swx-tensorflow-android](https://hub.docker.com/r/sofwerx/swx-tensorflow-android/)

If a new Github release triggered the build, the `.pb` model uploaded along with the release will be built into the resultant `.apk` files.

The resultant `.apk` files are then automatically published back to Github as asset binaries under the Release.

# Running

Sideload install the app:

    adb install ./outputs/app-debug.apk

Run the app:

    adb shell monkey -p com.example.sofwerx.android.tflitecamerademo -c android.intent.category.LAUNCHER 1

Uninstall the app:

    adb uninstall com.example.sofwerx.android.tflitecamerademo

