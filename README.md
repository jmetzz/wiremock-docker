# Wiremock Docker

> [Wiremock](http://wiremock.org) standalone HTTP server Docker image


This repository is a simplification of [rodolpheche/wiremock-docker](https://github.com/rodolpheche/wiremock-docker).
Since this is simplified version is enough for my local development tests, I can not promise there will be any 
improvement or added feature in future.

If you are looking for a wiremock on docker with some kind of support, please use `rodolpheche/wiremock-docker` 
version instead. 
 

## The docker image includes

- `EXPOSE 8080 8443` : the wiremock http/https server port
- `VOLUME /home/wiremock` : the wiremock data storage


## Environment variables

- `uid` : the container executor uid, useful to avoid file creation owned by root
- `JAVA_OPTS` : for passing any custom options to Java e.g. `-Xmx128m`

## Getting started

The `wirem.sh` script can be used to build the docker image and start a container with *default* parameters.


```bash
$ wirem.sh build
```

```bash
$ wirem.sh run
```

To test the container, access [http://localhost:8080/__admin](http://localhost:8080/__admin). If you click the link, 
the browser will show the configured mappings.

You can also check this configuration via `curl` command:

```bash
$ curl http://localhost:8080/__admin/
``` 


You can create a new stub mapping by posting to WireMock’s HTTP API:

```bash
$ curl -X POST \
--data '{ "request": { "url": "/get/this", "method": "GET" }, "response": { "status": 200, "body": "Here it is!\n" }}' \
http://localhost:8080/__admin/mappings/new
```

And then fetch it back:
```bash
$ curl http://localhost:8080/get/this
Here it is!
```

> Bear in mind this new stub will not be persisted. 

### Start a Wiremock container with Wiremock arguments


```sh
docker run -it --rm -p 8443:8443 jmetzz/wiremock --https-port 8443 --verbose
```

> Access [https://localhost:8443/__admin](https://localhost:8443/__admin) to check https working

### Start record mode using host uid for file creation

If you don't know what `record mode` means to wiremock, 
visit [Record and Playback](http://wiremock.org/docs/record-playback/) documentation.

You can already use this functionality even starting the wiremock container with default values. 
However when binding host folders (e.g. $PWD/test) with the container volume (/home/wiremock), the created 
files will (or may) be owned by root. Sometimes this is undesired. 
To avoid this, you can use the `uid` docker environment variable to also bind host uid with the container executor uid.

```bash
docker run -d --name wiremock-container \
  -p 8080:8080 \
  -v $PWD/test:/home/wiremock \
  -e uid=$(id -u) \
  jmetzz/wiremock \
    --proxy-all="http://registry.hub.docker.com" \
    --record-mappings --verbose
curl http://localhost:8080
docker rm -f wiremock-container
```

> Check the created file owner with `ls -alR test`

However, the example above is a facility. 
The good practice is to create yourself the binded folder with correct permissions and to use the *-u* docker argument.

```bash
mkdir test
docker run -d --name wiremock-container \
  -p 8080:8080 \
  -v $PWD/test:/home/wiremock \
  -u $(id -u):$(id -g) \
  jmetzz/wiremock \
    --proxy-all="http://registry.hub.docker.com" \
    --record-mappings --verbose
curl http://localhost:8080
docker rm -f wiremock-container
```

> Check the created file owner with `ls -alR test`
 
## Samples

If you have your stubs in another directory in your local disk, you can direct the shared volume to that directory in
 order to load these stubs in wiremock.


```bash
docker run -it --rm \
  -p 8080:8080 \
  -v /your/stubs/path:/home/wiremock \
  jmetzz/wiremock
```

## Use wiremock extensions


```bash
cd wiremock-docker
# prepare extension folder
mkdir wiremock-docker/extensions
# download extension
wget https://repo1.maven.org/maven2/com/opentable/wiremock-body-transformer/1.1.3/wiremock-body-transformer-1.1.3.jar \
  -O wiremock-docker/samples/random/extensions/wiremock-body-transformer-1.1.3.jar
# run a container using extension 
docker run -it --rm \
    -p 8080:8080 \
    -u $(id -u):$(id -g) \
    -v $(pwd)/stubs:/home/wiremock \
    -v $(pwd)/extensions:/var/wiremock/extensions jmetzz/wiremock \
        --extensions com.opentable.extension.BodyTransformer
```

To verify the extension is working, access [http://localhost:8080/random](http://localhost:8080/random) to show random 
number. If the extension is not enabled you will see `"$(!RandomInteger)"` instead.
