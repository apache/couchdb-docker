# chmod 0600 /opt/couchdb-search/etc/jmxremote.password

exec -c "java -server \
    -Xmx2G \
    -Dsun.net.inetaddr.ttl=30 \
    -Dsun.net.inetaddr.negative.ttl=30 \∂
    -XX:OnOutOfMemoryError="kill -9 %p" \
    -XX:+UseConcMarkSweepGC \
    -XX:+CMSParallelRemarkEnabled \
    -classpath '/opt/couchdb-search/lib/*' \
    com.cloudant.clouseau.Main \
    /opt/couchdb-search/etc/clouseau.ini"
