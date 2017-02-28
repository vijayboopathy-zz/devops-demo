if docker service ls 2> /dev/null | grep -q -i "tomapp"; then
        echo "Service is already running"
else
#        docker service create --replicas 6 --publish 8080:8080 --log-driver=syslog  --log-opt syslog-address=tcp://192.168.0.53:5000 --name tomapp initcronregistry.org/tomcatapp
        docker service create --replicas 3 --publish 8080:8080 --log-driver=syslog  --log-opt syslog-address=tcp://192.168.0.56:5000 --name tomapp initcronregistry.org/tomcatapp

fi

#if docker service ls 2> /dev/null | grep -q -i "cadvisor"; then
#        echo "Service is already running"
#else
#        docker service create --replicas 3 --publish=9090:8080 --name cadvisor google/cadvisor
#fi
