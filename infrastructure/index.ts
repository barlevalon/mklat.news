import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as docker from "@pulumi/docker";
import * as cloudflare from "@pulumi/cloudflare";

// Get configuration
const config = new pulumi.Config();
const gcpConfig = new pulumi.Config("gcp");
const projectId = gcpConfig.require("project");
const region = gcpConfig.get("region") || "me-west1"; // Tel Aviv, Israel
const domain = config.get("domain"); // Custom domain (optional)
const cloudflareConfig = new pulumi.Config("cloudflare");

// Enable required APIs
const cloudRunApi = new gcp.projects.Service("cloud-run-api", {
    service: "run.googleapis.com",
    project: projectId,
});

const containerRegistryApi = new gcp.projects.Service("container-registry-api", {
    service: "containerregistry.googleapis.com",
    project: projectId,
});

const artifactRegistryApi = new gcp.projects.Service("artifact-registry-api", {
    service: "artifactregistry.googleapis.com",
    project: projectId,
});

const cloudBuildApi = new gcp.projects.Service("cloud-build-api", {
    service: "cloudbuild.googleapis.com",
    project: projectId,
});

// Create Artifact Registry repository
const repository = new gcp.artifactregistry.Repository("mklat-news-repo", {
    location: region,
    repositoryId: "mklat-news",
    description: "Docker repository for mklat.news app",
    format: "DOCKER",
}, { dependsOn: [artifactRegistryApi] });

// Reference the Docker image (will be built and pushed by CI)
const imageUri = pulumi.interpolate`${region}-docker.pkg.dev/${projectId}/mklat-news/mklat-news:latest`;

// Create Cloud Run service
const service = new gcp.cloudrun.Service("mklat-news-service", {
    location: region,
    name: "mklat-news-service",
    metadata: {
        annotations: {
            "run.googleapis.com/ingress": "all",
            "run.googleapis.com/ingress-status": "all",
        },
    },
    template: {
        metadata: {
            annotations: {
                // Zero-downtime deployment settings
                "run.googleapis.com/execution-environment": "gen2",
                "autoscaling.knative.dev/maxScale": "10",
                "autoscaling.knative.dev/minScale": "1", // Keep at least 1 instance running
                // Rolling deployment settings
                "run.googleapis.com/cpu-throttling": "false",
            },
        },
        spec: {
            containers: [{
                image: imageUri,
                ports: [{
                    containerPort: 3000,
                }],
                resources: {
                    limits: {
                        cpu: "1000m",      // 1 vCPU
                        memory: "1Gi",     // 1GB RAM
                    },
                    requests: {
                        cpu: "100m",       // 0.1 vCPU minimum
                        memory: "256Mi",   // 256MB minimum
                    },
                },
                envs: [
                    {
                        name: "NODE_ENV",
                        value: "production",
                    },
                    {
                        name: "ORIGIN",
                        value: domain || "",
                    },
                ],
                // Use Cloud Run default probes (TCP with 240s timeout) - worked 2h ago
            }],
            containerConcurrency: 100,
            timeoutSeconds: 300,
        },
    },
    traffics: [{
        percent: 100,
        latestRevision: true,
    }],
}, { dependsOn: [cloudRunApi] });

// Create IAM policy to allow public access
const iamPolicy = new gcp.cloudrun.IamMember("mklat-news-public-access", {
    service: service.name,
    location: service.location,
    role: "roles/run.invoker",
    member: "allUsers",
});

// Global External Application Load Balancer for custom domain support
// Since domain mappings are not supported in me-west1, we use a load balancer

// Create a global address for the load balancer
const globalAddress = new gcp.compute.GlobalAddress("mklat-news-lb-ip", {
    name: "mklat-news-lb-ip",
    description: "Static IP for mklat.news load balancer",
});

// Create a managed SSL certificate for the custom domain
const sslCertificate = domain ? new gcp.compute.ManagedSslCertificate("mklat-news-ssl-cert", {
    name: "mklat-news-ssl-cert",
    managed: {
        domains: [domain],
    },
    description: `Managed SSL certificate for ${domain}`,
}) : undefined;

// Create a Network Endpoint Group for the Cloud Run service
const neg = new gcp.compute.RegionNetworkEndpointGroup("mklat-news-neg", {
    name: "mklat-news-neg",
    region: region,
    networkEndpointType: "SERVERLESS",
    cloudRun: {
        service: service.name,
    },
});

// Create a backend service that points to the NEG
const backendService = new gcp.compute.BackendService("mklat-news-backend", {
    name: "mklat-news-backend",
    description: "Backend service for mklat.news",
    protocol: "HTTPS",
    timeoutSec: 30,
    backends: [{
        group: neg.id,
    }],
    loadBalancingScheme: "EXTERNAL",
});

// Create a URL map to route traffic to the backend service (HTTPS)
const urlMap = new gcp.compute.URLMap("mklat-news-url-map", {
    name: "mklat-news-url-map",
    description: "URL map for mklat.news HTTPS traffic",
    defaultService: backendService.id,
});

// Create a separate URL map for HTTP that redirects to HTTPS
const httpRedirectUrlMap = new gcp.compute.URLMap("mklat-news-http-redirect-map", {
    name: "mklat-news-http-redirect-map", 
    description: "HTTP to HTTPS redirect for mklat.news",
    defaultUrlRedirect: {
        httpsRedirect: true,
        redirectResponseCode: "MOVED_PERMANENTLY_DEFAULT", // 301 redirect
        stripQuery: false,
    },
});

// Create HTTPS proxy
const httpsProxy = sslCertificate ? new gcp.compute.TargetHttpsProxy("mklat-news-https-proxy", {
    name: "mklat-news-https-proxy",
    urlMap: urlMap.id,
    sslCertificates: [sslCertificate.id],
}) : undefined;

// Create HTTP proxy for redirect to HTTPS
const httpProxy = new gcp.compute.TargetHttpProxy("mklat-news-http-proxy", {
    name: "mklat-news-http-proxy",
    urlMap: httpRedirectUrlMap.id,
});

// Create global forwarding rules
const httpsForwardingRule = httpsProxy ? new gcp.compute.GlobalForwardingRule("mklat-news-https-rule", {
    name: "mklat-news-https-rule",
    target: httpsProxy.id,
    portRange: "443",
    ipAddress: globalAddress.address,
}) : undefined;

const httpForwardingRule = new gcp.compute.GlobalForwardingRule("mklat-news-http-rule", {
    name: "mklat-news-http-rule",
    target: httpProxy.id,
    portRange: "80",
    ipAddress: globalAddress.address,
});

// Configure Cloudflare DNS (only if domain is configured)
const zone = domain ? cloudflare.getZoneOutput({
    name: domain, // mklat.news
}) : undefined;

const dnsRecord = domain && zone ? new cloudflare.Record("dns-record", {
    zoneId: zone.id,
    name: "@", // Root domain
    content: globalAddress.address,
    type: "A",
    proxied: false, // Disable Cloudflare proxy since we're using Google's load balancer
    comment: "Points to Google Cloud Load Balancer for Cloud Run service in me-west1 (Tel Aviv)",
}, { dependsOn: [globalAddress] }) : undefined;

// Outputs
export const serviceUrl = service.statuses.apply(statuses => 
    statuses?.[0]?.url || "Service URL not available"
);
export const customDomain = domain || "No custom domain configured";
export const loadBalancerIp = globalAddress.address;
export const deployedImageUri = imageUri;
export const serviceLocation = service.location;
export const repositoryUrl = repository.name;
export const sslCertificateName = sslCertificate?.name || "No SSL certificate configured";
