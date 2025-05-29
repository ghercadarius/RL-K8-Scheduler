#!/bin/bash

docker run -d --name jmeter-server -p 9095:5005  --memory="1g" --cpus="1.0" --pull always ghercadarius/testing-app
echo "JMeter server started at http://localhost:9095"
