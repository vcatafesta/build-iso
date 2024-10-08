name: iso_build
#on:
#  workflow_dispatch:
#  schedule:
#    - cron:  '30 2 * * *'

jobs:
  prepare-release:
    runs-on: ubuntu-20.04
    steps:
      - uses: styfle/cancel-workflow-action@0.9.0
        with:
          access_token: ${{ github.token }}
      - id: time
        uses: nanzm/get-time-action@v1.1
        with:
          format: "YYYYMMDDHHmm"
    outputs:
      release_tag: ${{ steps.time.outputs.time }}
  build-release:
    runs-on: ubuntu-20.04
    needs: [prepare-release]
    strategy:
      matrix:
        EDITION: [biglinux]
        BRANCH: [stable]
        SCOPE: [minimal]
    steps:
      - uses: styfle/cancel-workflow-action@0.9.0
        with:
          access_token: ${{ github.token }}
      - id: time
        uses: nanzm/get-time-action@v1.1
        with:
          format: "YY.MM"
      - name: image-build-upload
        uses: biglinux/biglinux-iso-action@main
        with:
          edition: ${{ matrix.edition }}
          branch: ${{ matrix.branch }}
          scope: ${{ matrix.scope }}
          version: ${{ steps.time.outputs.time }}-development
          kernel: linux515
          code-name: "Nightly-Build"
          iso-profiles-repo: "https://github.com/biglinux/iso-profiles"
          release-tag: ${{ needs.prepare-release.outputs.release_tag }}
      - name: rollback
        if: ${{ failure() || cancelled() }}
        run: |
          echo ${{ github.token }} | gh auth login --with-token
          gh release delete ${{ needs.prepare-release.outputs.release_tag }} -y --repo ${{ github.repository }}
