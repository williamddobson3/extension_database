# Kao Kirei Integration Database Modifications

## Overview
This document summarizes the database modifications made to support the integration of Kao Kirei's discontinued products monitoring system.

## Key Changes Made

### 1. Enhanced `monitored_sites` Table
- **Added `is_global_notification` field**: Boolean flag to identify sites that should send notifications to all users
- **Added `scraping_method` field**: Enum to specify scraping method ('api' or 'dom_parser')
- **Updated indexes**: Added indexes for global notification and scraping method queries

### 2. Enhanced `notifications` Table
- **Made `user_id` nullable**: Allows global notifications without specific user association
- **Added `is_global` field**: Boolean flag to identify global notifications
- **Updated indexes**: Added index for global notification queries

### 3. Default Kao Kirei Sites
Two default monitored sites have been added:

#### Site 1: Household Products
- **URL**: `https://www.kao-kirei.com/ja/expire-item/khg/?tw=khg`
- **Name**: 花王 家庭用品の製造終了品一覧
- **Keywords**: 製造終了品,家庭用品,花王
- **Scraping Method**: DOM Parser
- **Global Notification**: Enabled

#### Site 2: Beauty Products
- **URL**: `https://www.kao-kirei.com/ja/expire-item/kbb/?tw=kbb`
- **Name**: 花王・カネボウ化粧品 製造終了品一覧
- **Keywords**: 製造終了品,化粧品,花王,カネボウ
- **Scraping Method**: DOM Parser
- **Global Notification**: Enabled

### 4. System User
- **Created system user (ID: 0)**: `system_global` for managing global notifications
- **Admin privileges**: Full administrative access
- **Purpose**: Owns the global notification sites

### 5. Sample Notifications
Added sample global notifications to demonstrate the system:
- Email notification for household products changes
- LINE notification for beauty products changes

## Notification Logic

### Global Notifications
- **Kao Kirei URLs**: All users receive notifications for changes to these specific URLs
- **Other URLs**: Only the user who registered the site receives notifications

### Notification Types
- **Email notifications**: Sent to all users with email notifications enabled
- **LINE notifications**: Sent to all users with LINE notifications enabled

### Scraping Methods
- **API Method**: Default for most sites
- **DOM Parser Method**: Required for Kao Kirei sites due to lack of API support

## Database Schema Changes

### New Fields Added
```sql
-- monitored_sites table
is_global_notification TINYINT(1) DEFAULT 0
scraping_method ENUM('api','dom_parser') DEFAULT 'api'

-- notifications table
is_global TINYINT(1) DEFAULT 0
user_id INT(11) DEFAULT NULL (made nullable)
```

### New Indexes
```sql
-- monitored_sites table
idx_monitored_sites_global_notification (is_global_notification)
idx_monitored_sites_scraping_method (scraping_method)

-- notifications table
idx_notifications_is_global (is_global)
```

## Implementation Notes

1. **Global Notification Sites**: Sites with `is_global_notification = 1` will send notifications to all active users
2. **User-Specific Sites**: Sites with `is_global_notification = 0` will only send notifications to the user who registered them
3. **DOM Parser Support**: Kao Kirei sites use DOM parser due to lack of API support
4. **System User**: ID 0 is reserved for system-level operations and global notifications

## Usage Examples

### Query for Global Notification Sites
```sql
SELECT * FROM monitored_sites WHERE is_global_notification = 1;
```

### Query for DOM Parser Sites
```sql
SELECT * FROM monitored_sites WHERE scraping_method = 'dom_parser';
```

### Query for Global Notifications
```sql
SELECT * FROM notifications WHERE is_global = 1;
```

## Next Steps

1. Update the scraping service to handle DOM parser method
2. Modify notification service to support global notifications
3. Update the frontend to display global notification sites
4. Implement change detection for product additions/removals
5. Test the complete notification flow for both global and user-specific sites
