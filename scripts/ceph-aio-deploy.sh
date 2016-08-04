#!/usr/bin/env bash

set -e

LOCALDIR="$(dirname $0)"

source ${LOCALDIR}/ceph-aio.conf

USE_LOCAL_REPO=${USE_LOCAL_REPO:=false}
CEPH_NODE="$(hostname)"
CEPH_NODE_IP="$(ip addr list eth0|grep 'inet '|cut -d' ' -f6|cut -d/ -f1)"
OS_METADATA_HOST="169.254.169.254"
OS_FLOATING_IP="$(curl --connect-timeout 5 -s http://${OS_METADATA_HOST}/latest/meta-data/public-ipv4 || echo -n '127.0.0.1')"
CEPH_RELEASE="${CEPH_RELEASE:="jewel"}"
CEPH_REPO_STRING="${CEPH_REPO_STRING:="deb http://download.ceph.com/debian-${CEPH_RELEASE}/ trusty main"}"
DATA_DIR="/mnt/ceph-osd"
DATA_DEV_SIZE="${DATA_DEV_SIZE:="20G"}"

RGW_BUCKET="${RGW_BUCKET:="superbucket"}"
RGW_USER="${RGW_USER:="s3-user"}"
RGW_ACCESSKEY="${RGW_ACCESSKEY:="5030VJ9HAB3GOFDQQTAY"}"
RGW_SECRET="${RGW_SECRET:="P7AfQ9cDeCWA7Tv1fqawR3o3eQQUlJqY2aXsJ1Xq"}"
RGW_PORT="8080"

if ${USE_LOCAL_REPO} ; then
	echo "Using local apt mirrors"
	source ${LOCALDIR}/local_repos.sh
	echo ${CEPH_REPO_STRING} > /etc/apt/sources.list.d/ceph.list
else
	echo "Using official apt mirrors"
	wget -qO - 'https://download.ceph.com/keys/release.asc' | apt-key add -
	echo ${CEPH_REPO_STRING} > /etc/apt/sources.list.d/ceph.list
fi

apt-get -qqy update

# Cleaning up
apt-get -qqy purge $(dpkg -l | egrep 'juju|chef|puppet|ruby|rpcbind' | awk '{print $2}' | xargs) && apt-get -qqy --purge autoremove

[[ -f ${HOME}/.ssh/id_rsa ]] || ssh-keygen -t rsa -N "" -f ${HOME}/.ssh/id_rsa
cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys
[[ -n $(grep $(hostname) /etc/hosts) ]] \
&& sed -i "s/.*$(hostname).*/${CEPH_NODE_IP} ${CEPH_NODE} ${RGW_BUCKET}.${CEPH_NODE}/g" /etc/hosts \
|| echo "${CEPH_NODE_IP} ${CEPH_NODE} ${RGW_BUCKET}.${CEPH_NODE}" >> /etc/hosts

apt-get -qqy install ceph-deploy python-magic python-pip

mkdir -p /opt/ceph-deploy && cd /opt/ceph-deploy
ceph-deploy -q install --mon --osd --rgw --no-adjust-repos --release ${CEPH_RELEASE} ${CEPH_NODE}
ceph-deploy -q new ${CEPH_NODE}

echo "osd crush chooseleaf type = 0" >> ./ceph.conf
echo "osd pool default size = 1" >> ./ceph.conf
echo -e "\n[client.rgw.${CEPH_NODE}]\nhost = ${CEPH_NODE}\nrgw dns name = ${CEPH_NODE}\nrgw_frontends = \"civetweb port=${RGW_PORT}\"\nrgw print continue = false\n" >> ./ceph.conf

ceph-deploy -q mon create-initial

echo "Creating block device for ceph OSD (${DATA_DEV_SIZE})..."
dd if=/dev/zero of=/ceph.osd bs=1 count=0 seek=${DATA_DEV_SIZE}
losetup /dev/loop0 /ceph.osd
mkfs.xfs /dev/loop0
mkdir -p ${DATA_DIR}
mount /dev/loop0 ${DATA_DIR} && chown -R ceph:ceph ${DATA_DIR}

echo -e "description \"Setup loop device\"\nstart on mounted MOUNTPOINT=/\ntask\nexec losetup /dev/loop0 /ceph.osd\n" > /etc/init/losetup.conf
echo "/dev/loop0 ${DATA_DIR} xfs loop 0 0" >> /etc/fstab

ceph-deploy -q osd prepare ${CEPH_NODE}:${DATA_DIR}
ceph-deploy -q osd activate ${CEPH_NODE}:${DATA_DIR}
ceph-deploy -q rgw create ${CEPH_NODE}

radosgw-admin user create --uid=${RGW_USER} --display-name=${RGW_USER} --access-key=${RGW_ACCESSKEY} --secret=${RGW_SECRET}

pip install s3cmd
echo -e "[default]\nhost_base = ${CEPH_NODE}:${RGW_PORT}\nhost_bucket = %(bucket)s.${CEPH_NODE}:${RGW_PORT}\naccess_key = ${RGW_ACCESSKEY}\nsecret_key = ${RGW_SECRET}\nuse_https = False\nsignature_v2 = True" > ${HOME}/.s3cfg

s3cmd mb s3://${RGW_BUCKET} > /dev/null
s3cmd --acl-public put /vagrant/tmp/testfile.gif s3://${RGW_BUCKET} > /dev/null

echo "================================================================================================="
echo "RadosGW installed successfully and listens on http://${CEPH_NODE}:${RGW_PORT} (IP ${OS_FLOATING_IP})"
echo "Please add the line \"${OS_FLOATING_IP} ${CEPH_NODE} ${RGW_BUCKET}.${CEPH_NODE}\" to /etc/hosts on your machine"
echo "and try to access http://${CEPH_NODE}:${RGW_PORT}/${RGW_BUCKET}/testfile.gif via web browser"
echo "================================================================================================="
