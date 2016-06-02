FROM bfd/rdc/hadoop-base-2.6.4:1.3
 
USER root
ENV hadoops /opt/hadoops
ENV HADOOP_HOME /opt/hadoops/hadoop

COPY config/* $hadoops/hadoop/etc/hadoop/
COPY run.sh $HADOOP_HOME/run.sh
RUN chown -R hadoop ${hadoops}
RUN chmod a+x $HADOOP_HOME/run.sh
RUN apt-get install -y net-tools
# Mapred ports
EXPOSE 50020 9000 50070 50010 50075


USER hadoop
WORKDIR $hadoops 

CMD ["/opt/hadoops/hadoop/run.sh"]
