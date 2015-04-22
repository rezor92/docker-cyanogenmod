# Build environment for CyanogenMod

FROM ubuntu:14.04
MAINTAINER Michael Stucki <mundaun@gmx.ch>

ENV DEBIAN_FRONTEND noninteractive

RUN sed -i 's/main$/main universe/' /etc/apt/sources.list
RUN apt-get -qq update

RUN apt-get install -y bsdmainutils curl file screen
RUN apt-get install -y android-tools-adb android-tools-fastboot
RUN apt-get install -y bison build-essential flex git gnupg gperf libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev libxml2 libxml2-utils lzop openjdk-7-jdk openjdk-7-jre pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev
RUN apt-get install -y ccache g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev
RUN apt-get install -y tig rsync wget

# Workaround for apt-get upgrade issue described here: https://github.com/dotcloud/docker/issues/1724
# If you still have problems with upgrading this image, you most likely use an outdated base image
RUN dpkg-divert --local --rename /usr/bin/ischroot && ln -sf /bin/true /usr/bin/ischroot

# Workaround for screen: /usr/bin/screen cannot be installed with setgid "utmp": https://github.com/stucki/docker-cyanogenmod/issues/2
# Install screen with setuid root instead (that's ok on a single-user system)
RUN chmod u+s /usr/bin/screen
RUN chmod 755 /var/run/screen

RUN apt-get -qqy upgrade

RUN mkdir -p /home/cmbuild && useradd --no-create-home cmbuild && rsync -a /etc/skel/ /home/cmbuild/

RUN mkdir /home/cmbuild/bin
RUN curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > /home/cmbuild/bin/repo
RUN chmod a+x /home/cmbuild/bin/repo

# local_manifest and roomservice
RUN mkdir -p /home/cmbuild/android/.repo/local_manifests
RUN echo "<?xml version="1.0" encoding="UTF-8"?>\n<manifest>\n<project name="CyanogenMod/android_device_oneplus_bacon" path="device/oneplus/bacon" remote="github" revision="cm-12.1" />\n<project name="CyanogenMod/android_device_qcom_common" path="device/qcom/common" remote="github" revision="cm-12.1" />\n<project name="CyanogenMod/android_device_oppo_msm8974-common" path="device/oppo/msm8974-common" remote="github" revision="cm-12.1" />\n<project name="CyanogenMod/android_device_oppo_common" path="device/oppo/common" remote="github" revision="cm-12.1" />\n<project name="CyanogenMod/android_kernel_oneplus_msm8974" path="kernel/oneplus/msm8974" remote="github" revision="cm-12.1" />\n<project name="TheMuppets/proprietary_vendor_oppo" path="vendor/oppo" remote="github" revision="cm-12.1" />\n<project name="TheMuppets/proprietary_vendor_oneplus" path="vendor/oneplus" remote="github" revision="cm-12.1" />\n<project name="DonkeyCoyote/proprietary_vendor_lge" path="vendor/lge" remote="github" revision="android-5.1"/>\n</manifest>" > /home/cmbuild/android/.repo/local_manifests/local_manifests.xml
RUN echo "<?xml version="1.0" encoding="UTF-8"?>\n<manifest>\n<remove-project name="platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.8" />\n<project name="ArchiDroid/Toolchain" path="prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.8" remote="github" revision="sabermod-4.8-arm-linux-androideabi" />\n<remove-project name="platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8" />\n<project name="ArchiDroid/Toolchain" path="prebuilts/gcc/linux-x86/arm/arm-eabi-4.8" remote="github" revision="architoolchain-4.9-arm-linux-gnueabihf-cortex_a7_neon_vfpv4" />\n</manifest>" > /home/cmbuild/android/.repo/local_manifests/roomservice.xml

# Add sudo permission
RUN echo "cmbuild ALL=NOPASSWD: ALL" > /etc/sudoers.d/cmbuild

# Fix ownership
RUN chown -R cmbuild:cmbuild /home/cmbuild

ADD startup.sh /root/startup.sh
RUN chmod a+x /root/startup.sh

# Set global variables
ADD android-env-vars.sh /etc/android-env-vars.sh
RUN echo "source /etc/android-env-vars.sh" >> /etc/bash.bashrc

VOLUME /home/cmbuild/android
VOLUME /srv/ccache

# Installation of libisl13 for Sabermod
RUN wget http://launchpadlibrarian.net/191842424/libisl13_0.14-1_amd64.deb
RUN dpkg -i libisl13_0.14-1_amd64.deb

CMD /root/startup.sh

# This does not work yet, see https://github.com/docker/docker/issues/9806
#USER cmbuild
#WORKDIR /home/cmbuild/android
