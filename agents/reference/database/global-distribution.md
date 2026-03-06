# Global Database Distribution

## Overview

Patterns for multi-region database architecture, cross-cloud replication, and disaster recovery. Essential for building globally distributed systems with high availability.

## Consistency Models

| Model | Guarantee | Latency | Use Case |
|-------|-----------|---------|----------|
| Strong | Immediate consistency | High | Financial transactions |
| Eventual | Eventually consistent | Low | Social feeds, analytics |
| Causal | Causal ordering preserved | Medium | Collaborative editing |
| Session | Consistent within session | Medium | User sessions |

---

## PostgreSQL Multi-Region Replication

### Streaming Replication Configuration

```sql
-- Primary server configuration (postgresql.conf)
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
track_commit_timestamp = on
synchronous_standby_names = 'FIRST 1 (eu_west_1, us_west_2)'

-- Create replication slots for each region
SELECT pg_create_physical_replication_slot('eu_west_1_slot');
SELECT pg_create_physical_replication_slot('us_west_2_slot');
SELECT pg_create_physical_replication_slot('ap_south_1_slot');
```

### Replica Configuration

```sql
-- Replica server (postgresql.conf)
hot_standby = on
hot_standby_feedback = on
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s

-- Recovery configuration (recovery.conf / postgresql.auto.conf)
primary_conninfo = 'host=primary.us-east-1.aws port=5432 user=replicator password=secret sslmode=require'
primary_slot_name = 'eu_west_1_slot'
recovery_target_timeline = 'latest'
```

### Logical Replication for Multi-Master

```sql
-- Enable pglogical on primary
CREATE EXTENSION pglogical;

-- Create replication set
SELECT pglogical.create_node(
    node_name := 'primary_node',
    dsn := 'host=primary.us-east-1.aws dbname=mydb'
);

SELECT pglogical.replication_set_add_all_tables(
    'default',
    ARRAY['public']
);

-- On replica: Subscribe to primary
SELECT pglogical.create_node(
    node_name := 'replica_node',
    dsn := 'host=replica.eu-west-1.aws dbname=mydb'
);

SELECT pglogical.create_subscription(
    subscription_name := 'subscription_to_primary',
    provider_dsn := 'host=primary.us-east-1.aws dbname=mydb',
    replication_sets := ARRAY['default'],
    synchronize_data := true
);
```

---

## Multi-Cloud DR Architecture

```typescript
// Multi-Cloud Disaster Recovery Orchestrator
class DisasterRecoveryOrchestrator {
  private clouds: Map<string, CloudProvider> = new Map([
    ['aws', new AWSProvider()],
    ['gcp', new GCPProvider()],
    ['azure', new AzureProvider()]
  ]);

  async executeFailover(disaster: DisasterEvent): Promise<FailoverResult> {
    const strategy = this.determineFailoverStrategy(disaster);

    switch (strategy) {
      case 'REGIONAL':
        return await this.regionalFailover(disaster);
      case 'CLOUD':
        return await this.cloudFailover(disaster);
      case 'HYBRID':
        return await this.hybridFailover(disaster);
    }
  }

  private async cloudFailover(disaster: DisasterEvent): Promise<FailoverResult> {
    const primaryCloud = disaster.affectedCloud;
    const secondaryCloud = this.selectSecondaryCloud(primaryCloud);

    // Phase 1: Pre-failover validation
    const validation = await this.validateFailoverReadiness(secondaryCloud);
    if (!validation.ready) {
      throw new Error(`Secondary cloud not ready: ${validation.issues}`);
    }

    // Phase 2: Data synchronization
    await this.syncCriticalData(primaryCloud, secondaryCloud);

    // Phase 3: DNS failover
    await this.executeDNSFailover(secondaryCloud);

    // Phase 4: Application failover
    const apps = await this.failoverApplications(secondaryCloud);

    // Phase 5: Database failover
    await this.failoverDatabases(secondaryCloud);

    // Phase 6: Verification
    await this.verifyFailover(secondaryCloud);

    return {
      status: 'SUCCESS',
      newPrimary: secondaryCloud,
      rto: this.calculateRTO(disaster),
      rpo: this.calculateRPO(disaster),
      affectedServices: apps
    };
  }
}
```

---

## Backup Strategy

### Multi-Tier Backup Configuration

```typescript
const backupStrategy = {
  databases: {
    frequency: 'hourly',
    retention: {
      hourly: 24,    // Keep 24 hourly backups
      daily: 30,     // Keep 30 daily backups
      weekly: 12,    // Keep 12 weekly backups
      monthly: 12,   // Keep 12 monthly backups
      yearly: 7      // Keep 7 yearly backups
    },
    locations: [
      's3://backup-primary/db/',      // Primary region
      'gs://backup-secondary/db/',    // Secondary cloud
      'azure://backup-tertiary/db/'   // Tertiary cloud
    ],
    encryption: 'AES-256',
    verification: true
  },

  configurations: {
    frequency: 'on-change',
    versionControl: 'git',
    encryption: 'gpg',
    locations: [
      'git@github.com:company/dr-configs.git',
      's3://config-backup/',
      'vault://disaster-recovery/'
    ]
  }
};
```

### Automated Backup Script

```bash
#!/bin/bash
# Multi-region PostgreSQL backup with verification

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-mydb}"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${DB_NAME}_${BACKUP_DATE}.sql.gz"

# Create backup with parallel dump
pg_dump -h "$DB_HOST" -U postgres -d "$DB_NAME" \
  --format=custom \
  --compress=9 \
  --jobs=4 \
  --file="/tmp/${BACKUP_FILE}"

# Upload to multiple regions
for REGION in us-east-1 eu-west-1 ap-south-1; do
  aws s3 cp "/tmp/${BACKUP_FILE}" \
    "s3://db-backups-${REGION}/${BACKUP_FILE}" \
    --storage-class GLACIER_IR \
    --sse aws:kms &
done
wait

# Verify backup integrity
pg_restore --list "/tmp/${BACKUP_FILE}" > /dev/null

# Upload verification checksum
sha256sum "/tmp/${BACKUP_FILE}" | \
  aws s3 cp - "s3://db-backups-us-east-1/${BACKUP_FILE}.sha256"

# Cleanup
rm -f "/tmp/${BACKUP_FILE}"

echo "Backup completed: ${BACKUP_FILE}"
```

---

## Conflict Resolution

### Last-Write-Wins with Vector Clocks

```typescript
interface VectorClock {
  [nodeId: string]: number;
}

class ConflictResolver {
  // Compare vector clocks to determine ordering
  compare(a: VectorClock, b: VectorClock): 'before' | 'after' | 'concurrent' {
    let aBeforeB = false;
    let bBeforeA = false;

    const allNodes = new Set([...Object.keys(a), ...Object.keys(b)]);

    for (const node of allNodes) {
      const aVal = a[node] || 0;
      const bVal = b[node] || 0;

      if (aVal < bVal) aBeforeB = true;
      if (bVal < aVal) bBeforeA = true;
    }

    if (aBeforeB && !bBeforeA) return 'before';
    if (bBeforeA && !aBeforeB) return 'after';
    return 'concurrent';
  }

  // Resolve concurrent updates
  resolve<T>(updates: Array<{value: T; clock: VectorClock; timestamp: number}>): T {
    // Sort by timestamp for deterministic ordering
    const sorted = updates.sort((a, b) => b.timestamp - a.timestamp);
    return sorted[0].value; // Last-write-wins
  }

  // Merge vector clocks after resolution
  merge(clocks: VectorClock[]): VectorClock {
    const result: VectorClock = {};

    for (const clock of clocks) {
      for (const [node, version] of Object.entries(clock)) {
        result[node] = Math.max(result[node] || 0, version);
      }
    }

    return result;
  }
}
```

---

## Monitoring Replication Lag

```sql
-- Monitor streaming replication lag
SELECT
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) / 1024 / 1024 AS lag_mb
FROM pg_stat_replication;

-- Alert on lag exceeding threshold
CREATE OR REPLACE FUNCTION check_replication_lag()
RETURNS void AS $$
DECLARE
    max_lag_mb CONSTANT int := 100;
    current_lag_mb int;
BEGIN
    SELECT MAX(pg_wal_lsn_diff(sent_lsn, replay_lsn) / 1024 / 1024)
    INTO current_lag_mb
    FROM pg_stat_replication;

    IF current_lag_mb > max_lag_mb THEN
        PERFORM pg_notify('replication_lag_alert',
            format('Replication lag: %s MB', current_lag_mb));
    END IF;
END;
$$ LANGUAGE plpgsql;
```

---

## Key Metrics

| Metric | Target | Critical |
|--------|--------|----------|
| Replication Lag | < 1 second | > 30 seconds |
| RPO (Recovery Point Objective) | < 1 minute | > 15 minutes |
| RTO (Recovery Time Objective) | < 5 minutes | > 1 hour |
| Backup Success Rate | 100% | < 95% |
| Cross-Region Latency | < 100ms | > 500ms |

## Related Documentation

- For event streaming patterns: `stream-processing.md`
- For change data capture: `cdc-implementation.md`
