export JAVA_HOME=${JAVA_HOME}

export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
export HADOOP_LOG_DIR=${HADOOP_LOG_DIR}


# The maximum amount of heap to use, in MB. Default is 1000.
export HADOOP_HEAPSIZE=10240
export HADOOP_NAMENODE_INIT_HEAPSIZE=10240

# Extra Java runtime options.  Empty by default.
export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"

# Command specific options appended to HADOOP_OPTS when specified
export HADOOP_NAMENODE_OPTS="-verbose:gc -Xloggc: -XX:ErrorFile=$HADOOP_LOG_DIR/hs_err_pid.log -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=85 -XX:+UseCMSCompactAtFullCollection -XX:CMSMaxAbortablePrecleanTime=1000 -XX:+CMSClassUnloadingEnabled -XX:+DisableExplicitGC -Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_NAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,RFAS $HADOOP_DATANODE_OPTS"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_SECONDARYNAMENODE_OPTS"
export HADOOP_NFS3_OPTS="$HADOOP_NFS3_OPTS"
export HADOOP_PORTMAP_OPTS="-Xmx512m $HADOOP_PORTMAP_OPTS"

export HADOOP_CLIENT_OPTS="-Xmx1240m -XX:PermSize=200M -XX:MaxPermSize=200M -XX:GCTimeRatio=19 -verbose:gc  $HADOOP_CLIENT_OPTS"

export HADOOP_SECURE_DN_USER=${HADOOP_SECURE_DN_USER}

export HADOOP_SECURE_DN_LOG_DIR=${HADOOP_LOG_DIR}/${HADOOP_HDFS_USER}

export HADOOP_PID_DIR=${HADOOP_PID_DIR}
export HADOOP_SECURE_DN_PID_DIR=${HADOOP_PID_DIR}

# A string representing this instance of hadoop. $USER by default.
export HADOOP_IDENT_STRING=$USER
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native/:/usr/local/lib/:/usr/local/snappy/lib/
