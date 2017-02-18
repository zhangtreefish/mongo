

# Andrew Erlichson, edited by treefish for use in Windows
# MongoDB
# script to start a sharded environment on localhost

# clean everything up
echo "killing mongod and mongos"
# killall mongod
# killall mongos
taskkill /im mongod.exe /f
taskkill /im mongos.exe /f
# TODO: for now, manually do below:
# tasklist | grep mongod
# tasklist | grep mongos
# taskkill /pid <pid>

echo "removing data files"
rm -rf \data\config

rm -rf \data\shard*
rm "cfg-a.log" "cfg-b.log" "cfg-c.log" "s0-r0.log" "s0-r1.log" "s0-r2.log" "s1-r0.log" "s1-r1.log" "s1-r2.log"
rm "s2-r0.log" "s2-r1.log" "s2-r2.log"
rm "mongos-1.log"

# start a replica set and tell it that it will be shard0
echo "starting servers for shard 0"
mkdir \data\shard0\rs0 \data\shard0\rs1 \data\shard0\rs2
start mongod --replSet s0 --logpath "s0-r0.log" --dbpath \data\shard0\rs0 --port 37017 --shardsvr --smallfiles
start mongod --replSet s0 --logpath "s0-r1.log" --dbpath \data\shard0\rs1 --port 37018 --shardsvr --smallfiles
start mongod --replSet s0 --logpath "s0-r2.log" --dbpath \data\shard0\rs2 --port 37019 --shardsvr --smallfiles

sleep 5
# connect to one server and initiate the set
echo "Configuring s0 replica set"
mongo --port 37017 << 'EOF'
config = { _id: "s0", members:[
          { _id : 0, host : "localhost:37017" },
          { _id : 1, host : "localhost:37018" },
          { _id : 2, host : "localhost:37019" }]};
rs.initiate(config)
EOF

# start a replicate set and tell it that it will be a shard1
echo "starting servers for shard 1"
mkdir \data\shard1\rs0 \data\shard1\rs1 \data\shard1\rs2
start mongod --replSet s1 --logpath "s1-r0.log" --dbpath \data\shard1\rs0 --port 47017 --shardsvr --smallfiles
start mongod --replSet s1 --logpath "s1-r1.log" --dbpath \data\shard1\rs1 --port 47018 --shardsvr --smallfiles
start mongod --replSet s1 --logpath "s1-r2.log" --dbpath \data\shard1\rs2 --port 47019 --shardsvr --smallfiles

sleep 5

echo "Configuring s1 replica set"
mongo --port 47017 << 'EOF'
config = { _id: "s1", members:[
          { _id : 0, host : "localhost:47017" },
          { _id : 1, host : "localhost:47018" },
          { _id : 2, host : "localhost:47019" }]};
rs.initiate(config)
EOF

# start a replicate set and tell it that it will be a shard2
echo "starting servers for shard 2"
mkdir \data\shard2\rs0 \data\shard2\rs1 \data\shard2\rs2
start mongod --replSet s2 --logpath "s2-r0.log" --dbpath \data\shard2\rs0 --port 57017 --shardsvr --smallfiles
start mongod --replSet s2 --logpath "s2-r1.log" --dbpath \data\shard2\rs1 --port 57018 --shardsvr --smallfiles
start mongod --replSet s2 --logpath "s2-r2.log" --dbpath \data\shard2\rs2 --port 57019 --shardsvr --smallfiles

sleep 5

echo "Configuring s2 replica set"
mongo --port 57017 << 'EOF'
config = { _id: "s2", members:[
          { _id : 0, host : "localhost:57017" },
          { _id : 1, host : "localhost:57018" },
          { _id : 2, host : "localhost:57019" }]};
rs.initiate(config)
EOF


# now start 3 config servers
echo "Starting config servers"
mkdir \data\config\config-a \data\config\config-b \data\config\config-c
start mongod --replSet csReplSet --logpath "cfg-a.log" --dbpath \data\config\config-a --port 57040 --configsvr --smallfiles
start mongod --replSet csReplSet --logpath "cfg-b.log" --dbpath \data\config\config-b --port 57041 --configsvr --smallfiles
start mongod --replSet csReplSet --logpath "cfg-c.log" --dbpath \data\config\config-c --port 57042 --configsvr --smallfiles

sleep 5

echo "Configuring csReplSet replica set"
mongo --port 57040 << 'EOF'
rs.initiate( {
   _id: "csReplSet",
   configsvr: true,
   version: 1,
   members: [ { _id: 0, host: "localhost:57040" },
   			  { _id: 1, host: "localhost:57041" },
   			  { _id: 2, host: "localhost:57042" } ]});
EOF

# now start the mongos on a standard port
mongos --logpath "mongos-1.log" --configdb csReplSet/localhost:57040,localhost:57041,localhost:57042
# echo "Waiting 60 seconds for the replica sets to fully come online"
# sleep 60
# sharding
echo "Connnecting to mongos and enabling sharding"

# add shards and enable sharding on the test db
mongo <<'EOF'
db.adminCommand( { addshard : "s0/"+"localhost:37017" } );
db.adminCommand( { addshard : "s1/"+"localhost:47017" } );
db.adminCommand( { addshard : "s2/"+"localhost:57017" } );
db.adminCommand({enableSharding: "schooldb"})
db.adminCommand({shardCollection: "schooldb.students", key: {student_id:1}});
EOF


