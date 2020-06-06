# effortless_gitlab

Sample Effortless Config repository with example of a GitLab CI/CD pipeline configuration for building and promoting effortless packages.  This is a simple example without advanced testing and publishing functionality and is only intended as a reference for base functionality.

# Contents

## Chef Repository

This repository follows the Chef Repo pattern for Effortless Config [https://docs.chef.io/effortless/effortless_config/#chef-repo-cookbook-pattern]

## Habitat

`./habitat` path contains Habitat plan

## Cookbooks

Contains `effortless` cookbook which is added to the effortless package

## Policyfiles

Contains `effortless.rb` policyfile, used by Habitat for creating the Effortless package with the repo.

# Local Test Kitchen (Docker)

* Contains configuration files to run local testing of the package using the `kitchen-docker` driver, `chef exec gem install kitchen-docker`.
* `kitchen.yml` - Kitchen configuration file for building with Docker locally, uses `shell` provisioner and `scripts/hab-build-local-docker.sh`.

# GitLab CICD Test Kitchen

* Includes `.gitlab-ci.yml` file for GitLab CICD testing.
* Includes env variable `HAB_AUTH_TOKEN` which is anticipated to be set on GitLab.
