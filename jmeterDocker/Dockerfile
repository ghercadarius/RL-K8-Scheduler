FROM openjdk:17-jdk-slim

RUN apt-get update && \
    apt-get install -y python3 python3-pip curl unzip tar && \
    rm -rf /var/lib/apt/lists/*

RUN echo "Installing jmeter"

ENV JMETER_VERSION 5.6.3
RUN curl -sL https://downloads.apache.org//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz | \
    tar -xz -C /opt && \
    mv /opt/apache-jmeter-${JMETER_VERSION} /opt/jmeter && \
    chmod +x opt/jmeter/bin/jmeter

RUN echo "Downloaded jmeter"

ENV PATH $PATH:/opt/jmeter/bin

WORKDIR /app
COPY server.py /app
COPY requirements.txt /app
RUN pip3 install -r requirements.txt

EXPOSE 5005
CMD ["python3", "server.py"]