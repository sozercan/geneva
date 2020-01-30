#!/usr/bin/env bash

set -x

# Determine if we should use a file added by the build or if we should just download the latest .deb
# from the repo and install it

echo -e "\nChecking for MDSD debian package and Installing it as necessary\n"

# File indicating this is a build with no accompanying debs
NOINSTALL_DEB="noinstall.deb"

# Names of deb packages to install
package_names=( "azure-mdsd" )

# See if a debian file exists locally
function check_deb_exists {
    if ! ls /*.deb; then
        return 1
    else
        return 0
    fi
}

# Make sure the right number of debian package(s) exist
function check_number_of_debs {
    # Loop through package(s) and make sure only 1 of each name exists
    for package in "${package_names[@]}"
    do
        :
        if [[ $(ls /${package}*.deb | wc -l) -gt 1 ]] ; then
            echo "Only 1 debian package with the same prefix name may be installed at a time"
            total_packages=$(ls /${package}*.deb | wc -l)
            echo "Found ${total_packages} debian packages with the prefix ${package}"
            exit 1
        fi
    done
}

# Download the latest debian package(s) from the repository and save locally
function download_deb {
    # Loop through package(s) and download them
    for package in "${package_names[@]}"
    do
        :
        echo "Downloading ${package} from repository"
        if ! apt-get download ${package}; then
            echo "Could not fetch ${package} from repository"
            exit 1
        fi
    done
}

# Install the debian package(s)
function install_deb {
    # Loop through packages and install them
    for package in "${package_names[@]}"
    do
        :
        ls /${package}*.deb | while read -r line
        do
            echo "Installing debian package: ${line}"
            if ! gdebi --non-interactive ${line}; then
                echo "Failed to install ${package} .deb file"
                exit 1
            fi
        done
    done
}

# Delete the debian package(s)
function delete_deb {
    ls /*.deb | while read -r line
    do
        echo "Deleting debian package: ${line}"
        rm -Rf ${line}
    done
}

# Delete .deb file which is passed in if no local debs are to be installed.  This is workaround for the
# docker COPY bug which fails if no files are present.
rm -Rf /${NOINSTALL_DEB}

# Check if package(s) exist already
# If they don't, download it and install them
if check_deb_exists; then
    # Make sure that the number of .deb files with each prefix is only 1 since we can't install multiple .deb files with
    # the same name
    check_number_of_debs

    # Install all the expected .deb package(s)
    install_deb
else
    # Download all the expected .deb package(s)
    download_deb

    # Check if package(s) exist
    if check_deb_exists; then
        # Install all the expected .deb package(s)
        install_deb
    else
        echo "Debian file does not exist even though apt-get download succeeded"
        exit 1
    fi
fi

# Delete all leftover install .deb file(s)
delete_deb
