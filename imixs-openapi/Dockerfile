# Dockerfile
# #############################################################################
#
# Build image:
# >> docker build -t imixs .
#
# Run container:
# >> docker run --rm -it -p 8080:8080 imixs
#
# #############################################################################

FROM payara/micro:5.201

# Create config dir
USER root
RUN mkdir ${PAYARA_HOME}/config

# Copy config
COPY ./src/docker/conf/payara-micro/domain.xml ${PAYARA_HOME}/config/

# Deploy artefacts
COPY ./target/postgresql-42.2.5.jar ${PAYARA_HOME}/config
COPY ./target/*.war ${DEPLOY_DIR}

RUN chown -R payara:payara ${PAYARA_HOME}/config
USER payara
WORKDIR ${PAYARA_HOME}

# add lauch options
EXPOSE 8080
CMD ["--addLibs","/opt/payara/config/postgresql-42.2.5.jar", "--deploymentDir", "/opt/payara/deployments", "--rootDir", "/opt/payara/config","--domainConfig", "/opt/payara/config/domain.xml"]
