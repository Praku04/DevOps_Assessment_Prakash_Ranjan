# DevOps Assessment: Terraform + Database Reliability

This repository contains a complete assessment project for designing AWS infrastructure with Terraform and demonstrating local PostgreSQL backup, restore, seed data, and query optimization.

Actual AWS deployment is not required. The Terraform environments are configured for plan-only review with dummy credentials and provider validation skips.

## Project Structure

```text
infra/
  modules/
    network/
    ecs/
    rds/
  envs/
    dev/
    prod/
.github/workflows/terraform.yml
db/
  migrations/
  seeds/
scripts/
docker-compose.yml
```

## Terraform Design

The infrastructure models:

```text
Internet -> ALB in public subnets -> ECS/Fargate in private subnets -> RDS PostgreSQL in private subnets
```

Included resources:

- VPC with public and private subnets
- Internet gateway for public subnet internet access
- NAT gateway for private subnet outbound internet access
- ALB security group allowing HTTP from the internet
- ECS/Fargate security group allowing traffic only from the ALB
- RDS security group allowing PostgreSQL only from ECS/Fargate
- ECS cluster, task definition, service, target group, listener, and ALB
- RDS PostgreSQL instance in private subnets

Environment differences:

| Setting | dev | prod |
| --- | --- | --- |
| ECS CPU/memory | 256 / 512 | 512 / 1024 |
| ECS desired count | 1 | 2 |
| RDS instance | db.t4g.micro | db.t4g.small |
| RDS storage | 20 GB | 50 GB |

### Validate Terraform

Run from either environment directory:

```bash
cd infra/envs/dev
terraform fmt -recursive ../../..
terraform init
terraform validate
terraform plan -refresh=false -var-file=dev.tfvars
```

For production:

```bash
cd infra/envs/prod
terraform init
terraform validate
terraform plan -refresh=false -var-file=prod.tfvars
```

The backend files are intentionally local examples:

- `infra/envs/dev/backend.tf`
- `infra/envs/prod/backend.tf`

For a real team deployment, replace them with S3 backend configuration and DynamoDB state locking.

## GitHub Actions

The workflow in `.github/workflows/terraform.yml` runs on pull requests and performs:

- `terraform fmt -check -recursive`
- `terraform init`
- `terraform validate`
- `terraform plan -refresh=false`

The generated plan is uploaded as a workflow artifact.

## Local PostgreSQL

Start the database:

```bash
docker compose up -d
```

The database is exposed on `localhost:5432`.

Default credentials:

```text
database: insurance_db
username: insurance_user
password: insurance_pass
```

Docker automatically runs:

- `db/migrations/001_create_tables.sql`
- `db/migrations/002_indexes.sql`
- `db/seeds/001_seed_data.sql`

### Verify Seed Data

```bash
docker compose exec postgres psql -U insurance_user -d insurance_db -c "SELECT COUNT(*) FROM hotel_bookings;"
docker compose exec postgres psql -U insurance_user -d insurance_db -c "SELECT COUNT(*) FROM booking_events;"
```

Expected result:

- `hotel_bookings` has at least 100 rows
- `booking_events` has events for a subset of bookings

## Query Optimization

Target query:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Index added:

```sql
CREATE INDEX idx_hotel_bookings_city_created_org_status
ON hotel_bookings (city, created_at, org_id, status)
INCLUDE (amount);
```

Why this index:

- `city` is an equality filter, so it is first.
- `created_at` is a range filter, so it follows `city`.
- `org_id` and `status` support the grouping step.
- `amount` is included so PostgreSQL can satisfy the aggregation with less table access when visibility maps permit index-only scans.

Verify the plan:

```bash
docker compose exec postgres psql -U insurance_user -d insurance_db -c "EXPLAIN ANALYZE SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status;"
```

## Backup and Restore

Create a timestamped dump:

```bash
./scripts/backup.sh
```

Backups are written to:

```text
backups/insurance_db_YYYYMMDD_HHMMSS.dump
```

Restore the latest backup into a fresh local database named `insurance_db_restored`:

```bash
./scripts/restore.sh
```

Restore a specific dump:

```bash
./scripts/restore.sh backups/insurance_db_YYYYMMDD_HHMMSS.dump
```

Verify restore:

```bash
docker compose exec postgres psql -U insurance_user -d insurance_db_restored -c "SELECT COUNT(*) FROM hotel_bookings;"
docker compose exec postgres psql -U insurance_user -d insurance_db_restored -c "SELECT COUNT(*) FROM booking_events;"
docker compose exec postgres psql -U insurance_user -d insurance_db_restored -c "SELECT city, status, COUNT(*) FROM hotel_bookings GROUP BY city, status ORDER BY city, status;"
```

The counts should match the source database before restore.

## Useful Cleanup

Stop containers:

```bash
docker compose down
```

Remove local database volume:

```bash
docker compose down -v
```

tfplan.json will contain the terraform plan
you can check what is the resources what is going to be created.

# deploy container and check container

##output
sudo docker compose up -d
[sudo] password for pikachu: 
[+] up 17/17
 ✔ Image postgres:16-alpine                              Pulled                                       37.4s
 ✔ Network devops_assessment_prakash_ranjan_default      Created                                       0.1s
 ✔ Volume devops_assessment_prakash_ranjan_postgres_data Created                                       0.0s
 ✔ Container devops_assessment_postgres                  Started                                       1.2s


# check seed data
docker compose exec postgres psql -U insurance_user -d insurance_db -c "SELECT COUNT(*) FROM hotel_bookings;"
docker compose exec postgres psql -U insurance_user -d insurance_db -c "SELECT COUNT(*) FROM booking_events;"
 count 
-------
   150
(1 row)

 count 
-------
   268
(1 row)


# Query Optimization

 docker compose exec postgres psql -U insurance_user -d insurance_db -c "EXPLAIN ANALYZE SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status;"
                                                   QUERY PLAN                                                    
-----------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=6.21..6.36 rows=12 width=65) (actual time=0.056..0.058 rows=4 loops=1)
   Group Key: org_id, status
   Batches: 1  Memory Usage: 24kB
   ->  Seq Scan on hotel_bookings  (cost=0.00..6.00 rows=21 width=33) (actual time=0.009..0.030 rows=21 loops=1)
         Filter: (((city)::text = 'delhi'::text) AND (created_at >= (now() - '30 days'::interval)))
         Rows Removed by Filter: 129
 Planning Time: 1.059 ms
 Execution Time: 0.156 ms
(8 rows)


# . Backup and Restore

./scripts/backup.sh
./scripts/restore.sh
Created backup: backups/insurance_db_20260707_192159.dump
NOTICE:  database "insurance_db_restored" does not exist, skipping
DROP DATABASE
CREATE DATABASE
Restored backups/insurance_db_20260707_192159.dump into database insurance_db_restored

