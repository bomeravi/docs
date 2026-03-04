# Space Object Storage (DigitalOcean Spaces)
Last updated: **March 4, 2026**

This guide covers creating and connecting a DigitalOcean Spaces bucket for file/object storage.

All screenshots are loaded from `digitalocean/images/bucket/`.

## Prerequisites

- DigitalOcean account with billing enabled
- A project where the Space will be created

## 1. Open Spaces Object Storage

- Open DigitalOcean dashboard.
- Go to `Spaces Object Storage` from the left sidebar.

![Step 1 - Spaces bucket list page](./images/bucket/01-bucket-list-page.png)

## 2. Create a New Space

- Click `Create Bucket` (or `Create a Spaces Bucket`).
- Select:
  - Datacenter region (pick close to your app server)
  - Space name (globally unique)
  - Access type (`Restrict File Listing` for private-by-default)
- Click `Create Space`.

![Step 2 - Create a new Spaces bucket](./images/bucket/02-create-bucket.png)

After creation, verify your bucket appears in the list.

![Step 3 - Bucket list after creation](./images/bucket/03-bucket-list-after-creation.png)

## 3. Generate Access Keys

- In dashboard, open `API` -> `Spaces Keys`.
- On the `Access Keys` tab, click `Create Access Key`.

![Step 4 - Access keys tab](./images/bucket/04-access-keys-list.png)

- Select access scope (`Limited Access` or `Full Access`) based on your app needs.
- Name the key and click `Create Access Key`.

![Step 5 - Create access key dialog](./images/bucket/05-generate-keys.png)

- Save:
  - `Access Key`
  - `Secret Key` (shown once)

![Step 6 - Keys list after creation](./images/bucket/06-keys-list-after-creation.png)

## 4. Test Access from Browser

- Open your bucket from the `Buckets` tab.
- In the `Files` tab, click `Upload`.
- Select a small test file from your computer.
- Confirm the file appears in the bucket list after upload.

![Step 7 - Bucket file upload page](./images/bucket/07-view-bucket.png)

## 5. App Configuration

Set these environment variables in your app/deployment:

```bash
SPACES_KEY=<ACCESS_KEY>
SPACES_SECRET=<SECRET_KEY>
SPACES_BUCKET=<SPACE_NAME>
SPACES_REGION=<REGION>
SPACES_ENDPOINT=https://<REGION>.digitaloceanspaces.com
```

## 6. Optional: Public File Access

- Keep bucket private by default.
- Use signed URLs for protected files.
- For public assets (images/css/js), configure bucket policy or per-object ACL carefully.

## 7. Optional: CDN

- Open your Space settings.
- Enable CDN endpoint if you need global caching.
- Update your app asset URL base to CDN URL.

## Next Step

- If your app server is a Droplet, complete [Droplet setup](./droplet.md) first.
