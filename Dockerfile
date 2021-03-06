# syntax=docker/dockerfile:experimental
# Run image with 'docker run --name NAME -i -p PORT:8080 quay.io/icecream/cjd:latest'
# Where NAME = Container-Name
# and   PORT = Exposed Port

# Jenkins Base Image. Latest is NOT used to prevent updates from breaking this Image
FROM cloudbees/cloudbees-jenkins-distribution:latest

# Set Maintainer
LABEL maintainer "cogent@cogentwebworks.com"

# Set Working Directory
WORKDIR /tmp

# Many of the commands in this file will not run as the Jenkins user. Thus, we switch to the Root-User here

USER root

# Add Kubectl to Image

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
# chmod Kubectl to allow execution
RUN chmod +x ./kubectl
# Move to /bin (Must be root to have permissions to do this)
RUN mv ./kubectl /usr/local/bin


# Add Blue Ocean Plugin to Jenkins

# Copy from existing Blue Ocean Image, so we don't have to build it ourselves
COPY --from=jenkinsci/blueocean /usr/share/jenkins/ref/plugins/ /usr/share/jenkins/ref/plugins/
RUN install-plugins.sh antisamy-markup-formatter matrix-auth # for security, you know
# Force use of locally built blueocean plugin
RUN for f in /usr/share/jenkins/ref/plugins/blueocean-*.jpi; do mv "$f" "$f.override"; done
# let scripts customize the reference Jenkins folder. Used in bin/build-in-docker to inject the git build data
# Again: Copy from existing image on Hub
COPY --from=jenkinsci/blueocean /usr/share/jenkins/ref /usr/share/jenkins/ref

# Add GenuineTools IMG (for executing Docker commands)
RUN export IMG_SHA256="41aa98ab28be55ba3d383cb4e8f86dceac6d6e92102ee4410a6b43514f4da1fa" && \
    curl -fSL "https://github.com/genuinetools/img/releases/download/v0.5.7/img-linux-amd64" -o "/usr/local/bin/img" && \
	echo "${IMG_SHA256}  /usr/local/bin/img" | sha256sum -c - && \
	chmod a+x "/usr/local/bin/img"

# Switch back to Jenkins-User
USER jenkins