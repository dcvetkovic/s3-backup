# Restore Guide

## CLI

```bash
# Download from S3
aws s3 cp s3://your-bucket/backups/backup_20260114_120000.sql.gz ./

# Restore to database
gunzip -c backup_20260114_120000.sql.gz | psql -h 127.0.0.1 -U supply -d supplyme_db_prod_v2
```

Or in one step directly from S3:
```bash
aws s3 cp s3://your-bucket/backups/backup_20260114_120000.sql.gz - | gunzip | psql -h 127.0.0.1 -U supply -d supplyme_db_prod_v2
```

## pgAdmin

1. Download backup from S3 and decompress:
   ```bash
   gunzip backup_20260114_120000.sql.gz
   ```

2. In pgAdmin:
   - Right-click target database → **Query Tool**
   - Click **Open File** (folder icon) → select `backup_20260114_120000.sql`
   - Click **Execute** (play button)

   Or:
   - Right-click target database → **Restore**
   - Format: **Plain**
   - Filename: select the `.sql` file
   - Click **Restore**
