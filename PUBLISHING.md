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

