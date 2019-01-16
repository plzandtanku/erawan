FROM ubuntu:16.04
USER root

RUN apt-get update
RUN apt-get install -y --no-install-recommends openssh-server vim

RUN echo PubkeyAuthentication yes >> /etc/ssh/ssh_config
RUN echo Host * >> /etc/ssh/ssh_config
RUN service ssh start
CMD service ssh start && bash
EXPOSE 22/tcp
EXPOSE 22/udp


from openjdk:8
WORKDIR /tmp
RUN wget https://downloads.lightbend.com/scala/2.12.5/scala-2.12.5.tgz
RUN tar xzf scala-2.12.5.tgz
RUN mv scala-2.12.5 /usr/share/scala
RUN ln -s /usr/share/scala/bin/* /usr/bin 
RUN rm scala-2.12.5.tgz
RUN useradd -m -s /bin/bash hadoop
WORKDIR /home/hadoop
RUN wget https://archive.apache.org/dist/hadoop/core/hadoop-3.1.0/hadoop-3.1.0.tar.gz -P .
RUN wget https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-without-hadoop.tgz -P .

RUN tar -zxf hadoop-3.1.0.tar.gz
RUN mv hadoop-3.1.0 hadoop
RUN tar -zxf spark-2.3.0-*.tgz
RUN rm *.tgz
RUN mv spark-2.3.0-* spark
RUN chown hadoop spark -R

RUN mkdir /home/hadoop/.ssh
RUN echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config
RUN echo PasswordAuthentication no >> /home/hadoop/.ssh/config

COPY config/id_rsa.pub /home/hadoop/.ssh/id_rsa.pub
COPY config/id_rsa /home/hadoop/.ssh/id_rsa
RUN cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
RUN chown hadoop .ssh -R

RUN echo PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH >> /home/hadoop/.profile
RUN echo PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH >> /home/hadoop/.bashrc
RUN mkdir -p /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp
RUN chown hadoop /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp /home/hadoop/spark
RUN echo HADOOP_HOME=/home/hadoop/hadoop >> /home/hadoop/.bashrc
RUN chown hadoop /home/hadoop/.profile /home/hadoop/.bashrc
RUN echo JAVA_HOME=/docker-java-home >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh                        
RUN echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
# Spark
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.bashrc
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.profile
RUN echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.profile
RUN echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.bashrc
COPY config/workers /home/hadoop/spark/conf/slaves
COPY config/sparkcmd.sh /home/hadoop/
RUN chown hadoop /home/hadoop/*

COPY config/core-site.xml config/hdfs-site.xml config/mapred-site.xml config/yarn-site.xml config/workers /home/hadoop/hadoop/etc/hadoop/
RUN chown hadoop /home/hadoop/hadoop/etc/hadoop/*
