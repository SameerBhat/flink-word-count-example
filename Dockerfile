FROM openjdk:15-jdk-alpine3.11

# Install requirements
RUN apk add --no-cache bash snappy libc6-compat

# Flink environment variables
ENV FLINK_INSTALL_PATH=/opt
ENV FLINK_HOME $FLINK_INSTALL_PATH/flink
ENV FLINK_LIB_DIR $FLINK_HOME/lib
ENV FLINK_PLUGINS_DIR $FLINK_HOME/plugins
ENV FLINK_OPT_DIR $FLINK_HOME/opt
ENV FLINK_JOB_ARTIFACTS_DIR $FLINK_INSTALL_PATH/artifacts
ENV FLINK_USR_LIB_DIR $FLINK_HOME/usrlib
ENV PATH $PATH:$FLINK_HOME/bin

# flink-dist can point to a directory or a tarball on the local system
ARG flink_dist=NOT_SET
ARG job_artifacts=NOT_SET
ARG python_version=NOT_SET
# hadoop jar is optional
ARG hadoop_jar=NOT_SET*

# Install Python
RUN \
  if [ "$python_version" = "2" ]; then \
    apk add --no-cache python; \
  elif [ "$python_version" = "3" ]; then \
    apk add --no-cache python3 && ln -s /usr/bin/python3 /usr/bin/python; \
  fi

# Install build dependencies and flink
ADD $flink_dist $hadoop_jar $FLINK_INSTALL_PATH/
ADD $job_artifacts/* $FLINK_JOB_ARTIFACTS_DIR/

COPY artifacts/WordCount.jar /opt/artifacts/WordCount.jar

RUN set -x && \
  ln -s $FLINK_INSTALL_PATH/flink-[0-9]* $FLINK_HOME && \
  ln -s $FLINK_JOB_ARTIFACTS_DIR $FLINK_USR_LIB_DIR && \
  if [ -n "$python_version" ]; then ln -s $FLINK_OPT_DIR/flink-python*.jar $FLINK_LIB_DIR; fi && \
  if [ -f ${FLINK_INSTALL_PATH}/flink-shaded-hadoop* ]; then ln -s ${FLINK_INSTALL_PATH}/flink-shaded-hadoop* $FLINK_LIB_DIR; fi && \
  addgroup -S flink && adduser -D -S -H -G flink -h $FLINK_HOME flink && \
  chown -R flink:flink ${FLINK_INSTALL_PATH}/flink-* && \
  chown -R flink:flink ${FLINK_JOB_ARTIFACTS_DIR}/ && \
  chown -h flink:flink $FLINK_HOME

COPY docker-entrypoint.sh /

USER flink
EXPOSE 8081 6122 6123 6124

# ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD ["job-cluster"]
