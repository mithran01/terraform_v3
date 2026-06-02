how can we check the volume 
            kubectl describe pv pvc-3f16cae6-f48e-4bce-a17f-1ca330ff8629

            kubectl get sts -n openemr

            kubectl get pvc -n openemr

            kubectl get pods -n openemr -o wide


how can we test presistence

            kubectl exec -it -n openemr mariadb-0 -- bash

            mariadb -u root -p

            CREATE DATABASE testdb;
            kubectl delete pod mariadb-0 -n openemr

            Wait for recreation:

            kubectl get pods -n openemr -w

            Reconnect and verify:

Test EBS Reattachment

            kubectl drain ip-172-31-82-169.ec2.internal \
            --ignore-daemonsets \
            --delete-emptydir-data

  Then terminate the DB EC2 instance from AWS.

  TASK [Show generated credentials] *****************************************************************************
ok: [172.31.43.196] => {
    "msg": [
        "=================================",
        "MariaDB Credentials",
        "=================================",
        "Database: openemr",
        "User: openemr",
        "Password: 9EPdMkbfojzVf2GHdDvtaO4ILERSlPX7",
        "Root Password: JYTUvFiyp7YDOAPemZpalRPiyDZy61GW",
        "================================="
    ]
}
