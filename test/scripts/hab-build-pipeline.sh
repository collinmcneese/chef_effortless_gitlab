#!/bin/bash
# Builds on a GitLab runner instance.

# Setting hostname for GitLab intance so that it is reachable.
echo "${GITLAB_SERVER_IP} ${GITLAB_SERVER_HOSTNAME}" >> /etc/hosts

# License environment variables
export HAB_LICENSE="accept-no-persist"
export CHEF_LICENSE="accept-no-persist"

# Install Habitat if it is not already present
if [ ! -e "/bin/hab" ]; then
  curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash
fi

# Create the hab user/group, if needed.
if grep "^hab:" /etc/passwd > /dev/null; then
  echo "Hab user exists"
else
  useradd hab && true
fi

if grep "^hab:" /etc/group > /dev/null; then
  echo "Hab group exists"
else
  groupadd hab && true
fi

# Install core/git package, will be used to fetch code for building
hab pkg install core/git

# Expects that environment variables are set via kitchen:
## GIT_PROJECT_NAME, GIT_REPO_URL, GIT_COMMIT_ID

# Clone the project locally to instance and checkout the proper commit
if [ ! -d /tmp/${GIT_PROJECT_NAME} ]; then
  cd /tmp
  hab pkg exec core/git git clone ${GIT_REPO_URL}
fi
cd /tmp/${GIT_PROJECT_NAME}
hab pkg exec core/git git checkout ${GIT_COMMIT_ID}

# Load variable data from plan file
. habitat/plan.sh
export HAB_ORIGIN_NAME=${pkg_origin}

# Download origin keys if HAB_AUTH_TOKEN is set, otherwise generate.
# Generate origin keys since HAB_AUTH_TOKEN is not being set
# hab origin key generate ${pkg_origin}
# When using in a real pipeline, always download origin keys instead to prevent key sprawl.
hab origin key download ${pkg_origin} -s
hab origin key download ${pkg_origin}

# Build the Habitat package
# Use the -k flag with origin so that keys are loaded properly
cd /tmp/${GIT_PROJECT_NAME}
hab studio -k ${pkg_origin} build .

# Test that build completed
if [ -f results/last_build.env ]; then
  echo "Build success, proceeding ..."
fi

# Upload to builder if branch is master
cd /tmp/${GIT_PROJECT_NAME}
if [ $GIT_BRANCH_NAME == 'master' ] ; then
  . results/last_build.env
  # hab pkg upload results/${pkg_artifact}
  echo "package would be uploaded here normally - results/${pkg_artifact}"
else
  echo "not on master branch, completed"
fi
