Travis Maven Settings
=====================

This branch contains a default Maven settings file to be used by [Travis CI](https://travis-ci.org/) Maven scripts.

It notably configures the `sonatype-nexus-snapshots` repo credentials using the following environment variables:

```xml
<servers>
  <server>
    <id>sonatype-nexus-snapshots</id>
    <username>${env.CI_DEPLOY_USERNAME}</username>
    <password>${env.CI_DEPLOY_PASSWORD}</password>
  </server>
</servers>
```

See for example the [Travis CI configuration](https://github.com/daisy-consortium/xspec-maven-plugin/blob/master/.travis.yml) of the daisy-consortium/xspec-maven-plugin project to see how this 
is first checked out then used with Maven to deploy the build artifacts to Sonatype's OSS repository.