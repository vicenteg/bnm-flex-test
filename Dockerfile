FROM python:3.11-slim AS build
# FROM gcr.io/dataflow-templates-base/python311-template-launcher-base@sha256:769c5c5f877830cff520974ec9f43d0921a12ad3a16db35d5c7c0db2002d5c14
WORKDIR /app

# COPY the script and dependencies
COPY . .

# Update the OS packages
RUN apt update \
    && apt upgrade \
    && apt install curl -y \
    && apt remove libharfbuzz0b 6.0.0+dfsg-3 -y \
    && apt remove perl-base 5.36.0-7+deb12u1 -y \
    && apt remove libtiff6 4.5.0-6+deb12u1 -y \
    && apt remove libexpat1 2.5.0-1 -y \
    && apt remove libsqlite3-0 3.40.1-2 -y \
    && apt remove libnss3 2:3.87.1-1 -y \
    && apt remove libxml2 2.9.14+dfsg-1.3~deb12u1 -y \
    && apt remove openssl 3.0.13-1~deb12u1 -y \
    && apt remove libssl3 3.0.13-1~deb12u1 -y \
    && apt remove libnss3 2:3.87.1-1 -y \
    && apt remove libtiff6 4.5.0-6+deb12u1 -y \
    # This removes packages that can no longer be downloaded
    && apt autoclean -y \
    # This removes dependencies of packages that are no longer installed
    && apt autoremove -y

# - vg - unclear why we don't just use the base image above?
COPY --from=gcr.io/dataflow-templates-base/python311-template-launcher-base:20230622_RC00 /opt/google/dataflow/python_template_launcher /opt/google/dataflow/python_template_launcher

# Update the OS packages
RUN pip install --upgrade pip
RUN apt-get install default-jdk -y
RUN pip install apache-beam[gcp]==2.57.0
RUN pip install -r requirements.txt
RUN pip -V \
    && python -V
# Verify that the image does not have conflicting dependencies.
RUN pip check

# Create standard non-root app user and group
RUN groupadd -g 2000 container-user \
  && adduser --disabled-password --gecos '' --uid 2000 --gid 2000 container-user --home /home/container-user \
  && chown -R container-user:container-user /home/container-user

RUN chmod g+s /app \
  && chmod g+rx /app/* \
  && chown -R container-user:container-user /app

RUN chmod g+s /opt/google/dataflow/python_template_launcher \
  && chown -R container-user:container-user /opt/google/dataflow/python_template_launcher

RUN chmod g+s /var/log \
  && chmod -R 777 /var/log \
  && chown -R container-user:container-user /var/log


USER container-user
RUN whoami

WORKDIR /app/src

ENV FLEX_TEMPLATE_PYTHON_PY_FILE="${WORKDIR}/wordcount_flex_template.py"
ENV FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE="${WORKDIR}/requirements.txt"

# Set the entrypoint to Apache Beam SDK launcher.
ENTRYPOINT ["/opt/apache/beam/boot"]
