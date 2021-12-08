FROM redhat/ubi8:8.5 AS local-env
ARG USER_UID=1002710000

### Prepare system
ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk

RUN yum update -y && \
    yum install -y \
    vim \
    wget \
    openssh-server \
    less \
    unzip \
    java-1.8.0-openjdk \
    sudo \
    python3-pip \
    git

RUN cd /usr/bin && \
    sudo ln -s python3 python && \
    python3 -m pip install --upgrade pip

### Create User
RUN useradd -m -u $USER_UID -g 0 hduser && \
    echo "hduser:supergroup" | chpasswd && \
    usermod -aG wheel hduser && \
    echo "hduser     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/hduser

USER hduser


### Start ssh
COPY ssh_config /etc/ssh/ssh_config

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys


### Install Hadoop 2.10.1
ENV HADOOP_HOME /home/hduser/hadoop

RUN wget -q https://downloads.apache.org/hadoop/common/hadoop-2.10.1/hadoop-2.10.1.tar.gz && \
    tar xzf hadoop-2.10.1.tar.gz && \
    mv hadoop-2.10.1 $HADOOP_HOME && \
    rm hadoop-2.10.1.tar.gz

ENV HDFS_NAMENODE_USER hduser
ENV HDFS_DATANODE_USER hduser
ENV HDFS_SECONDARYNAMENODE_USER hduser

ENV YARN_RESOURCEMANAGER_USER hduser
ENV YARN_NODEMANAGER_USER hduser

RUN echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY hadoop-conf/*.xml $HADOOP_HOME/etc/hadoop/
COPY hadoop-sbin/*.sh $HADOOP_HOME/sbin/
RUN sudo chmod +x $HADOOP_HOME/sbin/start-dfs.sh && \
    sudo chmod +x $HADOOP_HOME/sbin/start-yarn.sh && \
    sudo chmod +x $HADOOP_HOME/sbin/stop-dfs.sh && \
    sudo chmod +x $HADOOP_HOME/sbin/stop-yarn.sh


### Install Spark 2.4.8 for Hadoop 2.7
ENV SPARK_HOME /home/hduser/spark
ENV HADOOP_CONF_DIR /home/hduser/hadoop/etc/hadoop/

RUN wget https://archive.apache.org/dist/spark/spark-2.4.8/spark-2.4.8-bin-hadoop2.7.tgz && \
    tar xzf spark-2.4.8-bin-hadoop2.7.tgz && \
    rm spark-2.4.8-bin-hadoop2.7.tgz && \
    mv spark-2.4.8-bin-hadoop2.7 $SPARK_HOME


### Install Airflow 1.10.12
RUN sudo yum install -y \
        gcc \
        gcc-c++ \
        make \
        cyrus-sasl-devel.x86_64 \
        python3-devel

ENV AIRFLOW_HOME /home/hduser/airflow/

RUN pip install apache-airflow[hdfs,hive,jdbc,ssh]==1.10.12 && \
    pip install SQLAlchemy==1.3.15 && \
    pip install wtforms==2.3.3 && \
    pip install psycopg2-binary


### Install Hive 2.3.9
RUN wget https://apache-mirror.rbc.ru/pub/apache/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz &&\
    tar xzf apache-hive-2.3.9-bin.tar.gz && \
    rm apache-hive-2.3.9-bin.tar.gz && \
    mv apache-hive-2.3.9-bin hive

ENV HIVE_HOME /home/hduser/hive
ENV PYTHONIOENCODING utf8

COPY hive-site.xml $HIVE_HOME/conf/


### Set up ports and scripts
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:/home/hduser/.local/bin:$HIVE_HOME/bin

#for Airflow
RUN airflow initdb
COPY airflow.cfg /home/hduser/airflow/
COPY airflow_variables.dev.json /home/hduser/

#for all
RUN mkdir /home/hduser/airflow/dags && \
    mkdir /home/hduser/share && \
    mkdir /home/hduser/share/spark && \
    mkdir /home/hduser/share/sql

COPY docker-entrypoint.sh $HADOOP_HOME/etc/hadoop/
RUN sudo chmod +x $HADOOP_HOME/etc/hadoop/docker-entrypoint.sh
ENTRYPOINT ["/home/hduser/hadoop/etc/hadoop/docker-entrypoint.sh"]


### Image for OpenShift
FROM local-env AS openshift-env
COPY spark /home/hduser/share/spark
COPY sql /home/hduser/share/sql
COPY dags /home/hduser/airflow/dags