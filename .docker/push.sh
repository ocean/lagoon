#!/usr/bin/env bash
##
# Build and push images to Dockerhub.
#

# set -u
set -x

# Docker registry host - when set should contain /.
DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-}
# Namespace for the image.
DOCKERHUB_NAMESPACE=${DOCKERHUB_NAMESPACE:-oceanic}

# Setting Lagoon image version here as it doesn't seem to inherit from .env.default
LAGOON_IMAGE_VERSION=v1.6.0
# Setting other vars here too.
PHP_IMAGE_VERSION=7.3
SITE_AUDIT_VERSION=7.x-3.x
GOVCMS_PROJECT_VERSION=1.5.0
DRUPAL_CORE_VERSION=8.8.8
COMPOSER_AUTH=${COMPOSER_AUTH}
FORCE_IMAGE_BUILD=true

# Docker image version tag.
IMAGE_VERSION_TAG=${IMAGE_VERSION_TAG:-8.8.0}
# Docker image tag prefix to be stripped from tag. Use " " (space) value to
# prevent stripping of the version.
IMAGE_VERSION_TAG_PREFIX=${IMAGE_VERSION_TAG_PREFIX:-8.x-}
# Docker image edge tag.
IMAGE_TAG_EDGE=${IMAGE_TAG_EDGE:-latest}
# Flag to force image build.
FORCE_IMAGE_BUILD=${FORCE_IMAGE_BUILD:-}
# Path prefix to Dockerfiles extension that is used as a name of the service.
FILE_EXTENSION_PREFIX=${FILE_EXTENSION_PREFIX:-.docker/Dockerfile.}
# CLI Image name
CLI_IMAGE=${DOCKERHUB_NAMESPACE:-govcms8lagoon}/govcms-govcms8:${IMAGE_VERSION_TAG:-8.8.0}

# Build govcms8 base image first and push as otherwise Docker can't find it for other images.
echo "==> Building \"govcms-govcms8\" image from file \"govcms8.Dockerfile\" for service \"$DOCKERHUB_NAMESPACE/govcms-govcms8\""
docker build --no-cache -f .docker/govcms8.Dockerfile -t $DOCKERHUB_NAMESPACE/govcms-govcms8 --build-arg SITE_AUDIT_VERSION=${SITE_AUDIT_VERSION} --build-arg LAGOON_IMAGE_VERSION=${LAGOON_IMAGE_VERSION} --build-arg PHP_IMAGE_VERSION=${PHP_IMAGE_VERSION} --build-arg GOVCMS_PROJECT_VERSION=${GOVCMS_PROJECT_VERSION} --build-arg DRUPAL_CORE_VERSION=${DRUPAL_CORE_VERSION} .
echo "==> Tagging and pushing \"govcms-govcms8\" image to \"$DOCKERHUB_NAMESPACE/govcms-govcms8:$IMAGE_VERSION_TAG\""
docker tag $DOCKERHUB_NAMESPACE/govcms-govcms8 $DOCKER_REGISTRY_HOST$DOCKERHUB_NAMESPACE/govcms-govcms8:$IMAGE_VERSION_TAG
docker push $DOCKER_REGISTRY_HOST$DOCKERHUB_NAMESPACE/govcms-govcms8:$IMAGE_VERSION_TAG

for file in $(echo $FILE_EXTENSION_PREFIX"*"); do
    service=govcms-${file/$FILE_EXTENSION_PREFIX/}

    version_tag=$IMAGE_VERSION_TAG
    [ "$IMAGE_VERSION_TAG_PREFIX" != "" ] && version_tag=${IMAGE_VERSION_TAG/$IMAGE_VERSION_TAG_PREFIX/}

    existing_image=$(docker images -q $DOCKERHUB_NAMESPACE/$service)

    # Only rebuild images if they do not exist or rebuild is forced.
    if [ "$existing_image" == "" ] || [ "$FORCE_IMAGE_BUILD" != "" ]; then
      echo "==> Building \"$service\" image from file $file for service \"$DOCKERHUB_NAMESPACE/$service\""
      docker build --no-cache -f $file -t $DOCKERHUB_NAMESPACE/$service --build-arg CLI_IMAGE=${CLI_IMAGE} --build-arg SITE_AUDIT_VERSION=${SITE_AUDIT_VERSION} --build-arg LAGOON_IMAGE_VERSION=${LAGOON_IMAGE_VERSION} --build-arg PHP_IMAGE_VERSION=${PHP_IMAGE_VERSION} --build-arg GOVCMS_PROJECT_VERSION=${GOVCMS_PROJECT_VERSION} --build-arg DRUPAL_CORE_VERSION=${DRUPAL_CORE_VERSION} .
    fi

    # Tag images with 'edge' tag and push.
    # echo "==> Tagged and pushed \"$service\" image to $DOCKERHUB_NAMESPACE/$service:$IMAGE_TAG_EDGE"
    # docker tag $DOCKERHUB_NAMESPACE/$service $DOCKER_REGISTRY_HOST$DOCKERHUB_NAMESPACE/$service:$IMAGE_TAG_EDGE
    # docker push $DOCKER_REGISTRY_HOST$DOCKERHUB_NAMESPACE/$service:$IMAGE_TAG_EDGE

    # Tag images with version tag, if provided, and push.
    if [ "$version_tag" != "" ]; then
      echo "==> Tagging and pushing \"$service\" image to $DOCKERHUB_NAMESPACE/$service:$version_tag"
      docker tag $DOCKERHUB_NAMESPACE/$service $DOCKER_REGISTRY_HOST$DOCKERHUB_NAMESPACE/$service:$version_tag
      docker push $DOCKER_REGISTRY_HOST$DOCKERHUB_NAMESPACE/$service:$version_tag
    fi
done
