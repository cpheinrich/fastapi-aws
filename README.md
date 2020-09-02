# fastapi-aws

This is an example project / starter project for deploying an extensible Fastapi backend on AWS. The [fastapi documentation](https://fastapi.tiangolo.com/) is a great source of information about fastapi, but does not have a ton of details on how to deploy the app, presumably becasue there are so many options. Meanwhile the [fastapi full stack app](https://github.com/tiangolo/full-stack-fastapi-postgresql) takes a fair bit of work and cost to get up and running.

This sample app is intended to be dead simple to deploy, and uses the brand new integration of docker with AWS ECS -- see the [docs](https://docs.docker.com/engine/context/ecs-integration/) or [github](https://github.com/docker/ecs-plugin) -- that enables you to deploy docker apps to AWS using native docker commands.

While docker-compose may be somewhat overkill for this simple backend which only has a one service, the benefit is that it is easily extensible to add other services to the stack such as a database.

## Running locally

### With Docker

Assuming you have Docker installed (which you will need to be able to deploy this) you can run the backend locally with

```
docker-compose up
```

after which the root should be at <http://0.0.0.0:80> and the docs at <http://0.0.0.0:80/docs>

### Without Docker

If you want to run locally without docker:

```
cd backend && pip install -r requirements.txt
```

preferably from within a virtual environment. Then:

```
cd app && uvicorn app.main:app --reload
```

after which the site should be live at <http://127.0.0.1:8000> and the API docs live at <http://127.0.0.1:8000/docs>

## Deploying to AWS

The application is deployed to AWS using the [Docker ECS integration](https://docs.docker.com/engine/context/ecs-integration/). The steps below are very similar, and largely copied, from the setup instructions of Docker's example app for deploying with the Docker ECS plugin that you can find [here](https://github.com/docker/ecs-plugin/tree/master/example).

### Setup pull credentials for private Docker Hub repositories

You should use a Personal Access Token (PAT) rather than your account password.
If you have 2FA enabled on your Hub account you will need to create a PAT.
You can read more about managing access tokens here:
https://docs.docker.com/docker-hub/access-tokens/

You can then create `DockerHubToken` secret on [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) using following command

```console
docker ecs secret create -d MyKey -u myhubusername -p myhubpat DockerHubToken
```

### Create an AWS Docker context and list available contexts

To initialize the Docker ECS integration, you will need to run the `setup`
command. This will create a Docker context that works with AWS ECS.

```console
$ docker ecs setup
Enter context name: aws
✔ sandbox.devtools.developer
Enter cluster name:
Enter region: us-west-2
✗ Enter credentials:
```

You can verify that the context was created by listing your Docker contexts:

```console
$ docker context ls
NAME                DESCRIPTION                               DOCKER ENDPOINT               KUBERNETES ENDPOINT   ORCHESTRATOR
aws
default *           Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                         swarm
```

### Update docker-compose.yml

Open up `docker-compose.yml` and:

- Set the value for `x-aws-pull_credentials` with your ARN, which you can get with `docker ecs secret list`
- Replace `your-docker-hub-username` with your `username` in the image field

### Test locally

The first step is to test your application works locally. To do this, you will
need to switch to using the default local context so that you are targeting your
local machine.

```console
docker context use default
```

You can then run the application using `docker-compose`:

```console
docker-compose up
```

Once the application has started, you can navigate to http://localhost:5000
using your Web browser using the following command:

```console
open http://0.0.0.0:80
```

### Push images to Docker Hub for ECS (ECS cannot see your local image cache)

In order to run your application in the cloud, you will need your container
images to be in a registry. You can push them from your local machine using:

```console
docker-compose push
```

You can verify that this command pushed to the Docker Hub by
[logging in](https://hub.docker.com) and looking for the `timestamper`
repository under your user name.

### Switch to ECS context and launch the app

Now that you've tested the application works locally and that you've pushed the
container images to the Docker Hub, you can switch to using the `aws` context
you created earlier.

```console
docker context use aws
```

Running the application on ECS is then as simple as doing a `compose up`:

```console
docker ecs compose up
```

### Check out the CLI

Once the application is running in ECS, you can list the running containers with
the `ps` command. Note that you will need to run this from the directory where
you Compose file is.

```console
docker ecs compose ps
```

You can also read the application logs using `compose logs`:

```console
docker ecs compose logs
```

### Check out the AWS console

You can see all the AWS components created for your running application in the
AWS console. There you will find:

- CloudFormation being used to manage all the infrastructure
- CloudWatch for logs
- Security Groups for network policies
- Load balancers (ELB for this example / ALB if your app only uses 80/443)

### Access your API endpoints

In the AWS console go to the EC2 panel and click on Load balancers. Select the Load balancer associated with this app -- it should be titled something like FastapiApp, then scroll down and copy the DNS name and enter this in your browser. You should see the {"Hello": "World"}, and you can access the example endpoint at `/example`

### Checkout CloudFormation

The ECS Docker CLI integration has the ability to output the CloudFormation
template used to create the application in the `compose convert` command. You
can see this by running:

```console
docker ecs compose convert
```

### Stop the meters

To shut down your application, you simply need to run:

```console
docker ecs compose down
```

## Using Amazon ECR instead of Docker Hub

If you'd like to use AWS ECR instead of Docker Hub, the [Makefile](Makefile) has
an example setup for creating an ECR repository and pushing to it.
You'll need to have the AWS CLI installed and your AWS credentials available.

```console
make create-ecr
REGISTRY_ID=<from the create above> make build-image
REGISTRY_ID=<from the create above> make push-image-ecr
```

Note that you will need to change the name of the image in the
[Compose file](docker-compose.yml).

If you want to use this often, you'll likely want to replace
`PUT_ECR_REGISTRY_ID_HERE` with the value from above.
