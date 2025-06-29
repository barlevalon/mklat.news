import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

/**
 * Monitoring and Alerting Configuration
 * 
 * This sets up monitoring for OREF API failures.
 * 
 * To receive alerts:
 * 1. Go to GCP Console > Monitoring > Alerting
 * 2. Click on the alert policies created by this stack
 * 3. Add notification channels (email, SMS, Slack, etc.)
 * 
 * Alternative: Project owners/editors automatically get alerts via:
 * - GCP Console notifications
 * - Mobile app notifications (if GCP app is installed)
 * 
 * The webhook channel created here can be configured for Slack/Discord integration.
 */

// Get configuration
const config = new pulumi.Config();
const gcpConfig = new pulumi.Config("gcp");
const projectId = gcpConfig.require("project");

// Enable required APIs
const monitoringApi = new gcp.projects.Service("monitoring-api", {
    service: "monitoring.googleapis.com",
    project: projectId,
});

const loggingApi = new gcp.projects.Service("logging-api", {
    service: "logging.googleapis.com",
    project: projectId,
});

// Use the project's default notification channels
// Project owners and editors will automatically receive alerts
// Users can also configure additional channels in the GCP Console

// Create a Slack/webhook notification channel that can be configured later
const webhookNotificationChannel = new gcp.monitoring.NotificationChannel("oref-failure-webhook", {
    displayName: "OREF API Failure Webhook",
    type: "webhook_tokenauth",
    description: "Configure this webhook in GCP Console to send alerts to Slack, Discord, etc.",
    labels: {
        url: "https://example.com/webhook", // Placeholder - configure in GCP Console
    },
    userLabels: {
        severity: "critical",
        purpose: "oref-api-monitoring",
    },
    enabled: false, // Disabled by default - enable and configure in GCP Console
}, { dependsOn: [monitoringApi] });

// Create a log-based metric for OREF API failures
const orefFailureMetric = new gcp.logging.Metric("oref-api-failures", {
    name: "oref-api-failures",
    description: "Count of OREF API failures (403 errors)",
    filter: `resource.type="cloud_run_revision"
AND (
    textPayload=~"Primary alerts API failed.*403"
    OR textPayload=~"Error in fetchAlertAreas.*403"
    OR textPayload=~"Backup API also failed.*403"
    OR textPayload=~"Error fetching historical alerts.*403"
)`,
    metricDescriptor: {
        metricKind: "DELTA",
        valueType: "INT64",
        displayName: "OREF API Failures",
    },
}, { dependsOn: [loggingApi] });

// Create an alert policy for OREF API failures
const orefFailureAlert = new gcp.monitoring.AlertPolicy("oref-api-failure-alert", {
    displayName: "OREF API Failure Alert",
    combiner: "OR",
    documentation: {
        content: `OREF API is returning 403 errors. This means:
- Alerts are not being fetched
- Location list is using fallback data
- Users may not see real-time alerts

Check:
1. If OREF API has changed their access requirements
2. If our IP is being blocked
3. If headers need to be updated`,
        mimeType: "text/markdown",
    },
    conditions: [{
        displayName: "OREF API returning 403 errors",
        conditionThreshold: {
            filter: pulumi.interpolate`resource.type = "cloud_run_revision"
AND metric.type = "logging.googleapis.com/user/${orefFailureMetric.name}"`,
            comparison: "COMPARISON_GT",
            thresholdValue: 10,
            duration: "300s", // Alert if more than 10 failures in 5 minutes
            aggregations: [{
                alignmentPeriod: "60s",
                perSeriesAligner: "ALIGN_RATE",
            }],
        },
    }],
    notificationChannels: [webhookNotificationChannel.id],
    alertStrategy: {
        autoClose: "86400s", // Auto close after 24 hours if resolved
    },
}, { dependsOn: [monitoringApi, orefFailureMetric] });

// Create a more sensitive alert for complete OREF outage
const orefOutageAlert = new gcp.monitoring.AlertPolicy("oref-complete-outage-alert", {
    displayName: "OREF Complete Outage Alert",
    combiner: "OR",
    documentation: {
        content: `OREF API is completely unreachable. This is a critical issue as:
- NO real-time alerts are available
- The app is running in degraded mode with fallback data only

Immediate action required!`,
        mimeType: "text/markdown",
    },
    conditions: [{
        displayName: "OREF API complete outage",
        conditionThreshold: {
            filter: pulumi.interpolate`resource.type = "cloud_run_revision"
AND metric.type = "logging.googleapis.com/user/${orefFailureMetric.name}"`,
            comparison: "COMPARISON_GT",
            thresholdValue: 50,
            duration: "60s", // Alert immediately if more than 50 failures in 1 minute
            aggregations: [{
                alignmentPeriod: "60s",
                perSeriesAligner: "ALIGN_RATE",
            }],
        },
    }],
    notificationChannels: [webhookNotificationChannel.id],
}, { dependsOn: [monitoringApi, orefFailureMetric] });


// Export monitoring resources
export const notificationChannelId = webhookNotificationChannel.id;
export const orefFailureMetricName = orefFailureMetric.name;
export const orefFailureAlertName = orefFailureAlert.name;
export const orefOutageAlertName = orefOutageAlert.name;
