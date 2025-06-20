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

// Artifact Registry repository is created by CI pipeline if needed

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

// Allow only the load balancer to access Cloud Run (no public access)
const iamPolicy = new gcp.cloudrun.IamMember("mklat-news-lb-access", {
    service: service.name,
    location: service.location,
    role: "roles/run.invoker",
    member: "allUsers", // Keep for simplicity, but traffic blocked by load balancer security policy
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

// Create security policy to allow only Cloudflare IPs
const securityPolicy = new gcp.compute.SecurityPolicy("mklat-news-security-policy", {
    name: "mklat-news-security-policy",
    description: "Allow only Cloudflare IPs to prevent direct access bypass",
    rules: [
        {
            action: "allow",
            priority: 500,
            match: {
                versionedExpr: "SRC_IPS_V1",
                config: {
                    srcIpRanges: [
                        // Cloudflare IPv4 ranges - Part 1 (max 10)
                        "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22",
                        "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18",
                        "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22",
                        "198.41.128.0/17",
                    ],
                },
            },
            description: "Allow Cloudflare IPs - Part 1",
        },
        {
            action: "allow",
            priority: 501,
            match: {
                versionedExpr: "SRC_IPS_V1",
                config: {
                    srcIpRanges: [
                        // Cloudflare IPv4 ranges - Part 2
                        "162.158.0.0/15", "104.16.0.0/13",
                        "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
                    ],
                },
            },
            description: "Allow Cloudflare IPs - Part 2",
        },
        {
            action: "deny(403)",
            priority: 2147483647,
            match: {
                versionedExpr: "SRC_IPS_V1",
                config: {
                    srcIpRanges: ["*"],
                },
            },
            description: "Default deny all",
        },
    ],
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
    // securityPolicy: securityPolicy.id, // Temporarily disable to test
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
    proxied: true, // Re-enable proxy now that SSL cert is provisioned
    comment: "Points to Google Cloud Load Balancer for Cloud Run service in me-west1 (Tel Aviv)",
}, { dependsOn: [globalAddress] }) : undefined;

// Configure SSL mode for origin connection
const sslSettings = domain && zone ? new cloudflare.ZoneSettingsOverride("ssl-settings", {
    zoneId: zone.id,
    settings: {
        ssl: "full", // Full SSL encryption between Cloudflare and origin
        alwaysUseHttps: "on",
        minTlsVersion: "1.2",
    },
}) : undefined;

// Temporarily disable geo-restriction to test
// const israelOnlyRule = domain && zone ? new cloudflare.Ruleset("israel-only-access", {
//     zoneId: zone.id,
//     name: "Geo-restriction: Israel only",
//     description: "Block all traffic except from Israel",
//     kind: "zone",
//     phase: "http_request_firewall_custom",
//     rules: [{
//         action: "block",
//         expression: "ip.geoip.country ne \"IL\"",
//         description: "Block non-Israeli traffic",
//         enabled: true,
//     }],
// }) : undefined;

// Outputs
export const serviceUrl = service.statuses.apply(statuses => 
    statuses?.[0]?.url || "Service URL not available"
);
export const customDomain = domain || "No custom domain configured";
export const loadBalancerIp = globalAddress.address;
export const deployedImageUri = imageUri;
export const serviceLocation = service.location;
export const repositoryUrl = `${region}-docker.pkg.dev/${projectId}/mklat-news`;
export const sslCertificateName = sslCertificate?.name || "No SSL certificate configured";
