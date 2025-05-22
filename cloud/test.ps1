$ips = gcloud compute instances list `
    --filter="name~'gke-'" `
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)"

$ips
