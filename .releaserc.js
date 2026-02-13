module.exports = {
  branches: ["master"],
  repositoryUrl: "<DEEPL_GITLAB_REPO_URL>",
  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
      },
    ],
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits",
      },
    ],
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md",
        changelogTitle: "# Changelog",
      },
    ],
    [
      "@semantic-release/exec",
      {
        publishCmd: [
          "crane auth login ${process.env.HARBOR_REGISTRY} -u '${process.env.HARBOR_REGISTRY_USER}' -p '${process.env.HARBOR_REGISTRY_TOKEN}'",
          "crane tag ${process.env.HARBOR_REGISTRY}/${process.env.HARBOR_REGISTRY_PROJECT}/yace@${process.env.BUILDKIT_IMAGE_HASH} ${nextRelease.version}",
        ].join(" && "),
      },
    ],
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md"],
        message:
          "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
      },
    ],
  ],
};
