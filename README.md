# Blue/Green Deployment Strategy

## Project Overview

This project demonstrates the implementation of a Blue/Green deployment strategy using Docker, Caddy, and GitHub Actions. The purpose of this strategy is to minimize application downtime during production deployments by maintaining two separate environments, Blue and Green.

Only one environment serves production traffic at a time, while the other remains available for deploying and testing updates. GitHub Actions automates the deployment process, performs health checks, and requires manual approval before switching production traffic to the updated environment.

The project also includes an automated rollback workflow that allows production traffic to be redirected to the previous environment if problems occur after deployment.

## Architecture and Technologies

The Blue/Green deployment architecture consists of two separate application environments managed through Docker Compose. Both environments run the same FastAPI application but use different environment variables to identify their versions and deployment environments.

The project uses the following technologies:

- **FastAPI:** Provides the application and health check endpoints used to validate deployments.
- **Docker and Docker Compose:** Build and manage the Blue and Green application containers.
- **Caddy:** Acts as a reverse proxy that directs production traffic to the active environment.
- **GitHub Actions:** Automates deployments, health checks, production approval, traffic switching, and rollback.

The Blue environment is accessible locally through port 4000, while Green uses port 4001. Caddy serves production traffic through port 8080 and communicates with the application containers internally through port 8000.

The architecture allows the inactive environment to be updated and tested without interrupting requests to the active production environment.

For a visual representation of the architecture, see **architecture.md**.

## Deployment Process

The deployment process is automated using GitHub Actions through the `blue-green-deploy.yml` workflow. The workflow is manually triggered from the GitHub Actions tab, where the user selects either the Blue or Green environment as the deployment target.

Once triggered, GitHub Actions executes the `deploy.sh` script, which verifies that the selected environment is inactive before building and deploying the application using Docker Compose. After deployment, the script performs health checks using the `/health` endpoint to confirm that the application is running correctly.

If the health checks pass, the workflow proceeds to the production approval stage. GitHub Actions requires manual approval before allowing the deployment to continue. This prevents production traffic from switching before the updated environment has been validated and approved.

After approval, GitHub Actions executes the `switch.sh` script, which uses the Caddy Admin API to update the reverse proxy configuration and redirect production traffic to the newly deployed environment. The workflow then verifies that the production application is responding successfully.

This process allows application updates to be deployed and tested while the existing production environment continues serving requests.

## Rollback Process

The rollback process is automated through GitHub Actions using the `blue-green-rollback.yml` workflow. If a problem occurs after deployment, the workflow can be manually triggered from the GitHub Actions tab to restore production traffic to the previous environment.

Once triggered and approved, GitHub Actions executes the `rollback.sh` script. The script identifies the currently active production environment and selects the alternate environment as the rollback target. Before switching traffic, it performs a health check to verify that the alternate environment is running correctly.

If the health check passes, the rollback script executes `switch.sh`, which uses the Caddy Admin API to redirect production traffic to the alternate environment. The workflow then verifies that the production application is responding successfully through its health check endpoint.

During testing, the rollback workflow successfully switched production traffic between the Blue and Green environments, demonstrating that a deployment can be reversed without rebuilding or redeploying the application.

## Testing and Results

The Blue/Green deployment strategy was tested locally using Docker Desktop and GitHub Actions with a self-hosted runner. Testing focused on automated deployments, health checks, production approval, traffic switching, rollback functionality, and application availability.

The following tests were successfully completed:

- **Environment Validation:** Confirmed that both Blue and Green application containers were running independently using Docker Compose.
- **Automated Deployment:** Successfully deployed the application to the inactive environment through GitHub Actions.
- **Health Checks:** Verified that the application responded successfully through the `/health` endpoint before production promotion.
- **Production Approval:** Confirmed that manual approval was required before switching production traffic.
- **Traffic Switching:** Successfully redirected production traffic between the Blue and Green environments using Caddy.
- **Rollback:** Successfully executed the GitHub Actions rollback workflow to restore production traffic to the alternate environment.

### Near-Zero Downtime Verification

To evaluate application availability during traffic switching, a Python monitoring script continuously sent HTTP requests to the production health endpoint (`http://localhost:8080/health`) for 60 seconds. During the monitoring period, production traffic was switched between the Blue and Green environments.

The monitoring script recorded the following results:

- **Successful Requests:** 515
- **Failed Requests:** 0
- **Success Rate:** 100.00%

These results demonstrate that the application remained available throughout the observed traffic switch, with no failed requests recorded during the test. Although this does not guarantee zero downtime under all conditions, it provides evidence that the implemented strategy supports near-zero downtime deployments.

Overall, the project successfully demonstrated automated deployment, health validation, controlled production promotion, traffic switching, and rollback functionality.