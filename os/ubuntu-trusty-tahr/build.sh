#!/bin/bash -x

BASENAME="ubuntu-14.04"
BUILDMARK="$(date +%Y-%m-%d-%H%M)"
IMG_NAME="$BASENAME-$BUILDMARK"
TMP_IMG_NAME="$BASENAME-tmp-$BUILDMARK"

IMG=ubuntu-14.04-server-cloudimg-amd64-disk1.img
IMG_URL=http://cloud-images.ubuntu.com/releases/14.04/release/$IMG

TMP_DIR=guest


if [ -f "$IMG" ]; then
    rm $IMG
fi

wget -q $IMG_URL


glance --insecure image-create \
       --file $IMG \
       --disk-format qcow2 \
       --container-format bare \
       --name "$TMP_IMG_NAME" \

TMP_IMG_ID="$(openstack --insecure image list --private | grep $TMP_IMG_NAME | tr "|" " " | tr -s " " | cut -d " " -f2)"
echo "TMP_IMG_ID for image '$TMP_IMG_NAME': $TMP_IMG_ID"

STATUS=queued

while [ "$STATUS" != "active" ]
  do
   sleep 10
   STATUS=$(openstack --insecure image show $TMP_IMG_ID | grep status | awk '{print $4}')
   echo "Waiting Image Create"
done

   echo "Image tmp is uploaded"

sed "s/TMP_IMAGE_ID/$TMP_IMG_ID/" $(dirname $0)/build-vars.template.yml > $(dirname $0)/build-vars.yml
sed -i "s/B_TARGET_NAME/$IMG_NAME/" $(dirname $0)/build-vars.yml

mkdir -p $(dirname $0)/output

cd ..

./build.sh ubuntu-trusty-tahr

BUILD_SUCCESS="$?"

#echo "======= Deleting temporary image..."
#glance --insecure image-delete $TMP_IMG_ID

if [ ! "$BUILD_SUCCESS" ]; then
  echo "Build failed! Check packer log for details."
  echo "Error code: $BUILD_SUCCESS"
  exit 1
fi

IMG_ID="$(openstack --insecure image list --private | grep $IMG_NAME | tr "|" " " | tr -s " " | cut -d " " -f2)"

echo "IMG_ID for image '$IMG_NAME': $IMG_ID"


#export NOSE_IMAGE_ID=$IMG_ID

#export NOSE_FLAVOR=21

#export NOSE_NET_ID=$FACTORY_NETWORK_ID

#export NOSE_SG_ID=$FACTORY_SECURITY_GROUP_ID

#pushd ../test-tools/pytesting_os/

#nosetests --nologcapture

#popd


# FIXME: Actually delete images
# echo "======= Deleting deprecated images"
echo "======= Listing deprecated images"
openstack --insecure image list | grep -E "$BASENAME-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}" | tr "|" " " | tr -s " " | cut -d " " -f 3 | sort -r | awk 'NR>5' # | xargs -r openstack image delete

glance  --insecure  image-show $IMG_ID

#if [ "$?" = "0" ]; then
#  echo "======= Validation testing..."
#  echo "URCHIN_IMG_ID=$IMG_ID $WORKSPACE/test-tools/urchin $WORKSPACE/test-tools/ubuntu-tests"
#  URCHIN_IMG_ID=$IMG_ID "$WORKSPACE/test-tools/urchin" "$WORKSPACE/test-tools/ubuntu-tests"
#fi
