# #!/bin/bash

# Builds on a Docker instance, anticipates that repo is mounted at default /kitchen.
if [ ! -d /kitchen ] ; then
  echo "Could not find /kitchen, exiting"
  exit 1
fi

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

# Load variable data from plan file
cd /kitchen
source habitat/plan.sh || . habitat/plan.sh
export HAB_ORIGIN_NAME=${pkg_origin}

# Download origin keys if HAB_AUTH_TOKEN is set, otherwise generate.
# Generate origin keys since HAB_AUTH_TOKEN is not being set
# hab origin key generate ${pkg_origin}
# When using in a real pipeline, always download origin keys instead to prevent key sprawl.
hab origin key download ${pkg_origin} -s
hab origin key download ${pkg_origin}

# Build the Habitat package
# Use the -k flag with origin so that keys are loaded properly
cd /kitchen
hab studio -k ${pkg_origin} build .

# Test that build completed
if [ -f results/last_build.env ]; then
  echo "Build success, proceeding ..."
fi

# Upload to builder if branch is master
cd /kitchen
if [ $HAB_UPLOAD == true ] ; then
  . results/last_build.env
  # hab pkg upload results/${pkg_artifact}
  echo "package would be uploaded here normally - results/${pkg_artifact}"
else
  echo "HAB_UPLOAD is not set to true, completed"
fi

