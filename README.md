# Kanban Dashboard – AWS CI/CD DevOps Project

## Project Overview

A production-style Kanban Task Management application deployed on an AWS EC2 instance using a fully automated CI/CD pipeline.

The project demonstrates how source code changes are automatically built, containerized, stored in Amazon ECR, deployed to an EC2 instance, and validated using automated health and application checks.

## Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   | GitHub Webhook
   v
Jenkins
   |
   +----------------------+
   |                      |
   v                      v
Docker Build          Application Tests
   |
   v
Amazon ECR
   |
   v
EC2 Instance
   |
   v
Docker Container
   |
   v
Nginx
   |
   v
Kanban Dashboard
```

## Technology Stack

* **Frontend:** React / TypeScript
* **Build Tool:** Vite
* **Web Server:** Nginx
* **Containerization:** Docker
* **CI/CD:** Jenkins
* **Source Control:** Git / GitHub
* **Container Registry:** Amazon Elastic Container Registry (ECR)
* **Cloud Platform:** AWS
* **Compute:** Amazon EC2
* **Automation:** Jenkins Pipeline
* **Deployment Trigger:** GitHub Webhook

## CI/CD Workflow

The pipeline follows this workflow:

1. Source code is maintained in GitHub.
2. A push to the main branch triggers the Jenkins pipeline through a GitHub webhook.
3. Jenkins checks out the latest source code.
4. A unique Docker image tag is generated using the Git commit SHA and Jenkins build number.
5. The application is built using the project's Dockerfile.
6. The production frontend is generated using the Vite build process.
7. The resulting Docker image uses Nginx to serve the production application.
8. Jenkins authenticates with Amazon ECR.
9. The Docker image is tagged and pushed to the ECR repository.
10. The image is pulled onto the EC2 deployment host.
11. The existing application container is replaced with the new version.
12. Docker HEALTHCHECK validates the container.
13. Jenkins performs an application-level HTTP validation.
14. The deployment is reported successful only when the required health and application checks pass.

## Docker Implementation

The application uses a multi-stage Docker build.

### Build Stage

The Node.js environment is used to:

* Install project dependencies
* Compile TypeScript
* Build the production Vite application
* Generate optimized frontend assets

### Runtime Stage

The production image uses Nginx to:

* Serve the generated static files
* Listen on port 80
* Run as the non-root `nginx` user
* Provide container health monitoring

## Container Health Monitoring

The Docker image includes an HTTP-based HEALTHCHECK that verifies the Nginx application endpoint.

A deployment is considered healthy only when:

* The container is running
* Docker reports the container as `healthy`
* The application endpoint responds successfully

This prevents a running but unhealthy container from being considered a successful deployment.

## Image Versioning

Docker images are versioned using:

```text
<git-commit-sha>-<jenkins-build-number>
```

Example:

```text
02142c3-17
```

This provides traceability between:

* GitHub source code
* Jenkins build
* Docker image
* Amazon ECR image
* EC2 deployment

## Amazon ECR

The application image is stored in an Amazon ECR repository.

Example repository:

```text
kanban-dashboard
```

Images are pushed using unique build-specific tags rather than relying only on the `latest` tag.

An ECR lifecycle policy is also configured to:

* Retain a limited number of tagged images
* Remove old untagged images
* Reduce unnecessary registry storage consumption

## Deployment Validation

The deployment pipeline validates the application at multiple levels.

### Container Validation

The deployment verifies that the application container is:

* Running
* Healthy
* Listening on the expected port

### Application Validation

The deployed application endpoint is checked for a successful HTTP response.

A successful response confirms that:

* Nginx is running
* The container networking is functional
* The application files are being served
* The deployment is responding to requests

## Automatic Rollback

The Jenkins pipeline includes deployment failure handling.

If the newly deployed image fails its health validation:

1. The failed deployment is identified.
2. The failed container is stopped.
3. The previously running image is restored.
4. The previous image is started.
5. The restored container is health-checked.
6. The application endpoint is validated again.
7. The deployment is marked as successfully rolled back.

This provides a recovery mechanism for failed deployments.

## Logging and Monitoring

Application and deployment behavior can be verified through:

* Jenkins build logs
* Docker container status
* Docker health status
* Nginx access logs
* Jenkins service logs
* Container resource statistics
* Deployment and rollback logs

The logs provide traceability when diagnosing failed builds, unhealthy containers, or unsuccessful deployments.

## Resource Management

The EC2 deployment environment is monitored for:

* CPU utilization
* Memory utilization
* Container resource consumption
* Jenkins resource usage
* Docker container status

Docker resource limits can be applied to prevent the application container from consuming excessive host resources.

## Security

Security considerations implemented in the project include:

* AWS IAM roles for EC2-based AWS access
* Amazon ECR authentication
* No AWS access keys embedded in application source code
* Jenkins-managed credentials
* Non-root Nginx container execution
* Versioned Docker images
* Restricted cloud permissions based on required operations

## Webhook Integration

GitHub webhook integration connects source-code changes with Jenkins.

The workflow is:

```text
GitHub Push
     |
     v
GitHub Webhook
     |
     v
Jenkins
     |
     v
Pipeline
     |
     v
Build → ECR → Deploy → Health Check
```

This enables automated CI/CD whenever changes are pushed to the configured repository.

## Project Deliverables

The project contains the following major deliverables:

* GitHub Repository
* Dockerfile
* Jenkinsfile
* README.md
* Amazon ECR Repository
* Jenkins CI/CD Pipeline
* GitHub Webhook Integration
* Dockerized Application
* EC2 Deployment
* Automated Health Checks
* Application Validation
* Deployment Logging
* Automatic Rollback
* ECR Lifecycle Policy
* Resource Monitoring
* Application URL / EC2 Public IP
* CI/CD evidence and screenshots

## Deployment Result

The completed pipeline provides an automated path from source-code commit to production deployment:

```text
Code Commit
    ↓
GitHub
    ↓
Webhook
    ↓
Jenkins
    ↓
Docker Build
    ↓
ECR Push
    ↓
EC2 Deployment
    ↓
Container Health Check
    ↓
Application Check
    ↓
Successful Deployment
```

## Key DevOps Concepts Demonstrated

* Git and GitHub
* GitHub Webhooks
* Jenkins Declarative Pipeline
* CI/CD automation
* Docker
* Multi-stage Docker builds
* Docker HEALTHCHECK
* Docker resource management
* Amazon ECR
* Amazon EC2
* AWS IAM roles
* Image versioning
* Deployment validation
* Logging and monitoring
* Automatic rollback
* Containerized application deployment
* Infrastructure and deployment troubleshooting
* Failure recovery
* Artifact traceability

## Project Outcome

The project demonstrates a complete DevOps delivery workflow in which application changes are automatically built, containerized, stored in a private container registry, deployed to AWS infrastructure, validated through automated health checks, and recovered through rollback mechanisms when deployment validation fails.
