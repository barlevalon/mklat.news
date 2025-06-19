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

// Create Artifact Registry repository
const repository = new gcp.artifactregistry.Repository("mklat-news-repo", {
    location: region,
    repositoryId: "mklat-news",
    description: "Docker repository for mklat.news app",
    format: "DOCKER",
}, { dependsOn: [artifactRegistryApi] });

// Build and push Docker image
const image = new docker.Image("mklat-news-image", {
    imageName: pulumi.interpolate`${region}-docker.pkg.dev/${projectId}/mklat-news/mklat-news:latest`,
    build: {
        context: "../", // Build from parent directory
        dockerfile: "../Dockerfile",
        platform: "linux/amd64",
    },
}, { dependsOn: [repository] });

// Create Cloud Run service
const service = new gcp.cloudrun.Service("mklat-news-service", {
    location: region,
    metadata: {
        annotations: {
            "run.googleapis.com/ingress": "all",
            "run.googleapis.com/ingress-status": "all",
        },
    },
    template: {
        spec: {
            containers: [{
                image: image.imageName,
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

// Create custom domain mapping (only if domain is configured)
const domainMapping = domain ? new gcp.cloudrun.DomainMapping("mklat-news-domain", {
    location: region,
    name: domain,
    metadata: {
        namespace: projectId,
    },
    spec: {
        routeName: service.name,
    },
}, { 
    dependsOn: [service] 
}) : undefined;

// Configure Cloudflare DNS (only if domain is configured)
const zone = domain ? cloudflare.getZoneOutput({
    name: domain, // mklat.news
}) : undefined;

const dnsRecord = domain && zone ? new cloudflare.Record("dns-record", {
    zoneId: zone.id,
    name: "@", // Root domain
    content: service.statuses.apply(statuses => {
        const url = statuses?.[0]?.url;
        return url ? url.replace(/^https?:\/\//, '') : '';
    }),
    type: "CNAME",
    proxied: true, // Enable Cloudflare proxy
}, { dependsOn: [service] }) : undefined;

// Outputs
export const serviceUrl = service.statuses.apply(statuses => 
    statuses?.[0]?.url || "Service URL not available"
);
export const customDomain = domain || "No custom domain configured";
export const imageUri = image.imageName;
export const serviceLocation = service.location;
export const repositoryUrl = repository.name;
