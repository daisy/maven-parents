#!/bin/bash

if [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  mvn deploy -DskipTests -Dinvoker.skip=true --settings target/travis/settings.xml
else
  echo "Skipping Maven deploy."
fi