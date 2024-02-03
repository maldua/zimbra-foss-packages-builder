#!/bin/bash

cd packages
build_pwd="$(pwd)"
build_number=0
for comp in `cat build-order | grep -v '^ '`
do
        let "build_number+=1"
        build_number_string=$(printf %03d ${build_number})
        comp_safe=$(echo $comp | sed -e 's~/~_~g')
        make_all_log_file="make_all_${build_number_string}_${comp_safe}.txt"
        dpkg_scanpackages_log_file="dpkg_scanpackages_${build_number_string}_${comp_safe}.txt"
        build_dep_log_file="build_dep_${build_number_string}_${comp_safe}.txt"
        cd $comp
        echo "${build_number_string} . Processing... '${comp}'"

        # Install build dependencies as needed
        package_dir=$(ls -d */ | grep -e '^zimbra-')
        if sudo apt-get -qq build-dep $(pwd)/${package_dir} -y > ${build_pwd}/${build_dep_log_file} 2>&1 ; then
            :
        else
          echo "ERROR. ${comp} failed. Please check: '${build_dep_log_file}' inside 'packages'."
          cd "${build_pwd}"
          cd ..
          exit 1
        fi

        # Actual build
        if make all > ${build_pwd}/${make_all_log_file} 2>&1 ; then
          cp build/UBUNTU20_64/*deb /var/local/repo
          cd /var/local/repo && dpkg-scanpackages . /dev/null 2> ${build_pwd}/${dpkg_scanpackages_log_file} | gzip -9c > Packages.gz
          apt-get -qq update
        else
          echo "ERROR. ${comp} failed. Please check: '${make_all_log_file}' inside 'packages'."
          cd "${build_pwd}"
          cd ..
          exit 1
        fi
        cd "${build_pwd}"
done
cd ..
