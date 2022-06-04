resource "google_service_account" "node" {
  account_id   = "${var.base_name}-gke-node-account"
  display_name = "Service Account for ${var.base_name} GKE Node"
}

resource "google_project_iam_member" "node_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_sa_resource_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_sa_resource_gcr" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_sa_resource_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_container_cluster" "blue" {
  provider = google-beta

  # name は project と location 内で unique にする
  name     = "${var.base_name}-blue"
  location = var.cluster_location

  # node pool 無しではクラスタは作成できないが、node pool は別途管理したいため
  # default node pool はすぐに削除する
  remove_default_node_pool = true
  initial_node_count       = 1

  description = "${var.base_name} cluster"

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.base_name}-tokyo-01-pods"
    services_secondary_range_name = "${var.base_name}-tokyo-01-services"
  }

  # 1 node あたり 110 Pods を max にすると /24 のアドレスが node ごとに割り当てられるが
  # そんなに使うことはないだろうから 64 にして /25 にしておく
  # 32 にすれば /26 まで減らせる (16 はさすがに小さすぎだろう)
  # https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr
  # Pod の CIDR は追加できる (ただし、全ての node pool が 1.19.8-gke.1000 から 1.20, もしくは 1.20.4-gke.500 以降でなければならない)
  # https://cloud.google.com/kubernetes-engine/docs/how-to/multi-pod-cidr
  default_max_pods_per_node = var.default_max_pods_per_node

  # Binary Authorization は、Grafeas オープンソース プロジェクトの一部である Kritis 仕様に基づいている
  # https://grafeas.io/
  # https://github.com/grafeas/kritis/blob/master/docs/binary-authorization.md
  # https://cloud.google.com/architecture/binary-auth-with-cloud-build-and-gke?hl=ja
  # Binary Authorization は Anthos 契約でない場合は追加の費用が発生する (1クラスタあたり月額12ドル程度)
  enable_binary_authorization = false

  # alpha 段階の機能を有効にしたい場合 true にする
  enable_kubernetes_alpha = false

  # 機械学習とかで TPU を使いたい場合向け https://cloud.google.com/tpu
  enable_tpu = false

  # ABAC (Attribute-based access control) は使わない
  enable_legacy_abac = false

  enable_shielded_nodes = true

  # node の管理を Google Cloud に任せるやつ
  # false だとしても指定すると enable_intranode_visibility, enable_shielded_nodes, enable_binary_authorization, default_max_pods_per_node, remove_default_node_pool, cluster_autoscaling などと conflict error になるので有効にしない場合は指定しない
  #enable_autopilot = true

  # cluster_telemetry を有効にする場合は logging_service, monitoring_service は指定しない
  # none | logging.googleapis.com (Legacy Stackdriver) | logging.googleapis.com/kubernetes (default)
  #logging_service = "logging.googleapis.com/kubernetes"
  # none | monitoring.googleapis.com (Legacy Stackdriver) | monitoring.googleapis.com/kubernetes (default)
  #monitoring_service = "monitoring.googleapis.com/kubernetes"

  network = google_compute_network.vpc.self_link

  subnetwork = google_compute_subnetwork.subnets["tokyo-01"].id

  # Dataplane V2 を使う場合は指定不可
  #network_policy {
  #  enabled = true
  #  provider = "PROVIDER_UNSPECIFIED"
  #}
  dynamic "network_policy" {
    for_each = local.network_policy_enabled ? ["dummy"] : []
    content {
      enabled  = true
      provider = var.network_policy_provider
    }
  }

  pod_security_policy_config {
    enabled = false
  }

  #authenticator_groups_config {
  #  security_group = "gke-security-groups@yourdomain.com"
  #}
  dynamic "authenticator_groups_config" {
    for_each = var.authenticator_groups_config_group != "" ? ["dummy"] : []
    content {
      security_group = var.authenticator_groups_config_group
    }
  }

  private_cluster_config {
    # API Server と node 間を private address で通信するように private endpoint を作成する
    enable_private_nodes = true
    # true にすると endpoint が private のものだけになる
    enable_private_endpoint = false
    # controle plane に割り当てる CIDR (/28 で指定する)
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
    master_global_access_config {
      enabled = true
    }
  }

  # log や metrics の収集を行うかどうか、対象をどうするか (ENABLED, DISABLED, SYSTEM_ONLY)
  # https://cloud.google.com/stackdriver/docs/solutions/gke/installing#controlling_the_collection_of_application_logs
  cluster_telemetry {
    type = "ENABLED"
  }

  # https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
  # UNSPECIFIED (default), RAPID, REGULAR, STABLE
  dynamic "release_channel" {
    for_each = var.release_channel == "UNSPECIFIED" ? [] : ["dummy"]
    content {
      channel = var.release_channel
    }
  }

  #resource_labels = {}

  # https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-usage-metering
  # リソースリクエストと使用量を BigQuery (gke_cluster_resource_consumption) に保存する
  # DataPortal https://cloud.google.com/bigquery/docs/visualize-data-studio などを
  # 利用して可視化することができる
  #resource_usage_export_config {
  #  # egress 計測を有効にすると、それ用の DaemonSet が deploy される
  #  enable_network_egress_metering = true
  #  # 有効にするとリソース使用量を BigQuery に保存する (default: true)
  #  enable_resource_consumption_metering = true
  #  # BigQuery の dataset id は必須
  #  bigquery_destination {
  #    dataset_id = "cluster_resource_usage"
  #  }
  #}

  # https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler
  vertical_pod_autoscaling {
    enabled = true
  }

  workload_identity_config {
    # 古い google provider での指定方法
    #identity_namespace = "${data.google_project.project.project_id}.svc.id.goog"

    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }

  # 同一 node 内の Pod 間通信を可視化するかどうか
  enable_intranode_visibility = true

  # L4 の Internal Load Balancer の Sub Setting を有効にするかどうか
  # 1.18 以上でないと有効にできない
  #enable_l4_ilb_subsetting = true

  # 有効にしない場合は指定しない
  #private_ipv6_google_access = true

  # DATAPATH_PROVIDER_UNSPECIFIED, LEGACY_DATAPATH, ADVANCED_DATAPATH
  # ADVANCED_DATAPATH (Dataplane V2) にする場合は network_policy は自動で有効となり
  # 明示的に指定できない
  # Dataplane V2 は 1.17.9 以降で指定可能
  # https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2
  # https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine
  # 2021-05-10 に GKE 1.20.6-gke.700 から GA になった
  datapath_provider = var.datapath_provider

  # node 内での SNAT は無効にする
  default_snat_status {
    disabled = true
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }

    # Dataplane V2 を使う場合は指定しない
    dynamic "network_policy_config" {
      for_each = var.datapath_provider == "ADVANCED_DATAPATH" ? [] : ["dummy"]
      content {
        disabled = var.network_policy_enabled ? true : false
      }
    }

    cloudrun_config {
      disabled = true
      # デフォルトは EXTERNAL
      #load_balancer_type = "LOAD_BALANCER_TYPE_INTERNAL"
    }

    istio_config {
      disabled = true
      #auth = "AUTH_MUTUAL_TLS"
    }

    dns_cache_config {
      enabled = true
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    # https://github.com/kalmhq/kalm
    kalm_config {
      enabled = false
    }

    config_connector_config {
      enabled = false
    }
  }

  cluster_autoscaling {
    enabled = true
    #auto_provisioning_defaults {
    #  min_cpu_platform = "Intel Haswell" | "Intel Sandy Bridge"
    #  oauth_scopes = "https://www.googleapis.com/auth/cloud-platform"
    #  service_account = ""
    #}
    autoscaling_profile = "BALANCED" # BALANCED | OPTIMIZE_UTILIZATION
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 16
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 32
    }
  }

  # etcd の中身の暗号化
  database_encryption {
    state = "DECRYPTED" # ENCRYPTED | DECRYPTED
    #key_name = "projects/MY-PROJECT/locations/global/keyRings/MY-RING/cryptoKeys/MY-KEY"
  }
  maintenance_policy {
    # daily_maintenance_window では start_time しか指定できない、Timezone は GMT
    # gcp console では recurring_window を設定するようになっているためこれはもう推奨されないのか？
    daily_maintenance_window {
      start_time = "17:00"
    }

    # recurring_window の方が柔軟 (取得時は UTC になるので差分として表示されないように UTC で指定する方が良い)
    #recurring_window {
    #  start_time = "2021-04-29T01:00:00+09:00"
    #  end_time   = "2021-04-29T08:00:00+09:00" # "2021-04-28T23:00:00Z"
    #  recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    #}

    # exclusion は複数登録可能
    #maintenance_exclusion {
    #  exclusion_name = "batch job"
    #  start_time     = "2019-01-01T00:00:00Z"
    #  end_time       = "2019-01-02T00:00:00Z"
    #}
    #maintenance_exclusion {
    #  exclusion_name = "holiday data load"
    #  start_time     = "2019-05-01T00:00:00Z"
    #  end_time       = "2019-05-02T00:00:00Z"
    #}
  }

  # API Server へアクセスする際の古い認証方法を無効にする
  master_auth {
    # 古い google provider では両方空文字列にすることで Basic Auth を無効にする
    #username = ""
    #password = ""

    # クライアント証明書での認証を無効にする
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # API Server へのアクセスを IP Address で制限する
  dynamic "master_authorized_networks_config" {
    for_each = local.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value.cidr_blocks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }

  # PubSub へのイベント通知
  notification_config {
    pubsub {
      enabled = false
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "google_container_node_pool" "node_pools_blue" {
  for_each = var.node_pools

  name               = "${var.base_name}-blue-${each.key}"
  location           = var.cluster_location
  cluster            = google_container_cluster.blue.name
  initial_node_count = each.value.autoscaling.min_node_count
  version            = google_container_cluster.blue.master_version
  #node_count = each.value.autoscaling.min_node_count

  autoscaling {
    min_node_count = each.value.autoscaling.min_node_count
    max_node_count = each.value.autoscaling.max_node_count
  }

  management {
    auto_repair  = each.value.management.auto_repair
    auto_upgrade = each.value.management.auto_upgrade
  }

  upgrade_settings {
    max_surge       = each.value.upgrade_settings.max_surge
    max_unavailable = each.value.upgrade_settings.max_unavailable
  }

  node_config {
    preemptible     = true
    machine_type    = "e2-medium"
    service_account = google_service_account.node.email
    image_type      = each.value.image_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type

    metadata = {
      disable-legacy-endpoints = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  #lifecycle {
  #  ignore_changes = [
  #    node_count,
  #  ]
  #}
}
