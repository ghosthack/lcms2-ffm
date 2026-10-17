# Publishing

Publishing follows the same Maven Central pipeline as `ffmpeg-ffm`.

1. Change all reactor versions from the snapshot to a release such as
   `2.19-0.1.0` and commit it.
2. Create and publish the matching GitHub Release tag, for example
   `v2.19-0.1.0`.
3. The release workflow rebuilds and tests all three native classifiers, then
   deploys one signed Central bundle using the `release,all-natives` profiles.

The repository needs `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`,
`GPG_PRIVATE_KEY`, and `GPG_PASSPHRASE` secrets.


Builds use the Maven Wrapper (`./mvnw`), which pins Maven 3.9.16. Do not
switch the release to the runner's `mvn`: under Maven 3.10 the
central-publishing plugin (0.11.0) stages resolver files such as
`_remote.repositories` and `maven-metadata-local.xml` into the bundle, and
Central rejects it with "Bundle has content that does NOT have a .pom file".

To inspect the signed bundle CI would upload, run the Release workflow
manually (optionally with a throwaway `version`). It builds all three natives,
then bundles against an unreachable Central URL with placeholder credentials
and attaches `central-bundle.zip` as a workflow artifact; nothing is published.
