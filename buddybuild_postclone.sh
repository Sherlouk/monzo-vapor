#!/usr/bin/env bash

brew install openssl
brew install ctls

swift package generate-xcodeproj
