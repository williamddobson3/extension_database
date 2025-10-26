-- =====================================================
-- COMPLETE WEBSITE MONITORING SYSTEM DATABASE SCHEMA
-- =====================================================
-- This file contains the complete, optimized database schema
-- for the website monitoring system with all features integrated:
-- - User management with blocking functionality
-- - Website monitoring (including Kao Kirei sites as normal sites)
-- - IP blocking system for enhanced security
-- - Anti-evasion system for user registration
-- - Notification guard system
-- - Product-specific change detection
-- - Comprehensive logging and analytics
--
-- IMPORTANT: Kao Kirei sites are treated as NORMAL sites
-- - Users must add them manually
-- - Notifications only sent to users who added the site
-- - No global notifications or automatic site creation
-- =====================================================

-- Database setup
CREATE DATABASE IF NOT EXISTS website_monitor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE website_monitor;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- =====================================================
-- CORE USER MANAGEMENT TABLES
-- =====================================================

-- Users table with enhanced blocking functionality
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `line_user_id` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_admin` tinyint(1) DEFAULT 0,
  `is_blocked` tinyint(1) DEFAULT 0,
  `blocked_at` timestamp NULL DEFAULT NULL,
  `blocked_by` int(11) DEFAULT NULL,
  `block_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_users_is_blocked` (`is_blocked`),
  KEY `idx_users_blocked_at` (`blocked_at`),
  KEY `idx_users_blocked_by` (`blocked_by`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`blocked_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User notifications preferences
CREATE TABLE `user_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `email_enabled` tinyint(1) DEFAULT 1,
  `line_enabled` tinyint(1) DEFAULT 0,
  `line_user_id` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `user_notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- WEBSITE MONITORING TABLES
-- =====================================================

-- Monitored sites (including Kao Kirei sites as normal sites)
-- NOTE: is_global_notification column kept for backward compatibility but should always be 0
-- All sites, including Kao Kirei, are treated as normal user-added sites
CREATE TABLE `monitored_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `url` varchar(500) NOT NULL,
  `name` varchar(100) NOT NULL,
  `check_interval_hours` int(11) DEFAULT 24,
  `keywords` text DEFAULT NULL,
  `last_check` timestamp NULL DEFAULT NULL,
  `last_content_hash` varchar(255) DEFAULT NULL,
  `last_status_code` int(11) DEFAULT NULL,
  `last_response_time_ms` int(11) DEFAULT NULL,
  `last_scraping_method` varchar(50) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_global_notification` tinyint(1) DEFAULT 0,  -- DEPRECATED: Always 0, kept for backward compatibility
  `scraping_method` enum('api','dom_parser') DEFAULT 'api',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_monitored_sites_user_id` (`user_id`),
  KEY `idx_monitored_sites_last_check` (`last_check`),
  KEY `idx_monitored_sites_user_active` (`user_id`, `is_active`),
  KEY `idx_monitored_sites_user_created` (`user_id`, `created_at`),
  KEY `idx_monitored_sites_global_notification` (`is_global_notification`),
  KEY `idx_monitored_sites_scraping_method` (`scraping_method`),
  CONSTRAINT `monitored_sites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Site checks with enhanced change detection
CREATE TABLE `site_checks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `site_id` int(11) NOT NULL,
  `content_hash` varchar(255) DEFAULT NULL,
  `text_content` longtext DEFAULT NULL,
  `content_length` int(11) DEFAULT NULL,
  `status_code` int(11) DEFAULT NULL,
  `response_time_ms` int(11) DEFAULT NULL,
  `scraping_method` varchar(50) DEFAULT NULL,
  `changes_detected` tinyint(1) DEFAULT 0,
  `reason` text DEFAULT NULL,
  `change_type` varchar(50) DEFAULT NULL,
  `change_reason` text DEFAULT NULL,
  `keywords_found` tinyint(1) DEFAULT 0,
  `keywords_list` text DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_site_checks_site_id` (`site_id`),
  KEY `idx_site_checks_created_at` (`created_at`),
  KEY `idx_site_checks_changes_detected` (`changes_detected`),
  KEY `idx_site_checks_text_content` (`text_content`(100)),
  CONSTRAINT `site_checks_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Change history tracking
CREATE TABLE `change_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `site_id` int(11) NOT NULL,
  `previous_check_id` int(11) DEFAULT NULL,
  `current_check_id` int(11) NOT NULL,
  `change_type` varchar(50) NOT NULL,
  `change_description` text DEFAULT NULL,
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `severity` enum('low','medium','high','critical') DEFAULT 'medium',
  `detected_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `previous_check_id` (`previous_check_id`),
  KEY `current_check_id` (`current_check_id`),
  KEY `idx_change_history_site_id` (`site_id`),
  KEY `idx_change_history_detected_at` (`detected_at`),
  CONSTRAINT `change_history_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE,
  CONSTRAINT `change_history_ibfk_2` FOREIGN KEY (`previous_check_id`) REFERENCES `site_checks` (`id`) ON DELETE SET NULL,
  CONSTRAINT `change_history_ibfk_3` FOREIGN KEY (`current_check_id`) REFERENCES `site_checks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scraped content storage
CREATE TABLE `scraped_content` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `site_check_id` int(11) NOT NULL,
  `content_type` enum('full_html','text_content','metadata') NOT NULL,
  `content_data` longtext DEFAULT NULL,
  `content_size` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_scraped_content_site_check_id` (`site_check_id`),
  KEY `idx_scraped_content_content_type` (`content_type`),
  CONSTRAINT `scraped_content_ibfk_1` FOREIGN KEY (`site_check_id`) REFERENCES `site_checks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product data for Kao Kirei sites
CREATE TABLE `product_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `site_id` int(11) NOT NULL,
  `site_check_id` int(11) NOT NULL,
  `product_name` varchar(500) NOT NULL,
  `product_category` varchar(200) DEFAULT NULL,
  `product_status` varchar(100) DEFAULT NULL,
  `product_regulation` varchar(100) DEFAULT NULL,
  `product_link` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_product_data_site_id` (`site_id`),
  KEY `idx_product_data_site_check_id` (`site_check_id`),
  KEY `idx_product_data_product_name` (`product_name`(100)),
  KEY `idx_product_data_created_at` (`created_at`),
  CONSTRAINT `product_data_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_data_ibfk_2` FOREIGN KEY (`site_check_id`) REFERENCES `site_checks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- NOTIFICATION SYSTEM TABLES
-- =====================================================

-- Notifications (all notifications are user-specific now)
-- NOTE: is_global column kept for backward compatibility but should always be 0
-- All notifications are sent to specific users who added the monitored sites
CREATE TABLE `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `site_id` int(11) NOT NULL,
  `type` enum('email','line') NOT NULL,
  `message` text NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('pending','sent','failed') DEFAULT 'pending',
  `is_global` tinyint(1) DEFAULT 0,  -- DEPRECATED: Always 0, kept for backward compatibility
  PRIMARY KEY (`id`),
  KEY `site_id` (`site_id`),
  KEY `idx_notifications_user_id` (`user_id`),
  KEY `idx_notifications_sent_at` (`sent_at`),
  KEY `idx_notifications_is_global` (`is_global`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification guard logs
CREATE TABLE `notification_guard_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `site_id` int(11) NOT NULL,
  `check_id` int(11) DEFAULT NULL,
  `decision` enum('allow','block') NOT NULL,
  `reason` varchar(500) NOT NULL,
  `guard_checks` json DEFAULT NULL,
  `change_detected` tinyint(1) DEFAULT 0,
  `change_reason` text DEFAULT NULL,
  `change_type` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_notification_guard_logs_site_id` (`site_id`),
  KEY `idx_notification_guard_logs_decision` (`decision`),
  KEY `idx_notification_guard_logs_created_at` (`created_at`),
  KEY `idx_notification_guard_logs_change_detected` (`change_detected`),
  CONSTRAINT `notification_guard_logs_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE,
  CONSTRAINT `notification_guard_logs_ibfk_2` FOREIGN KEY (`check_id`) REFERENCES `site_checks` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- IP BLOCKING SYSTEM TABLES
-- =====================================================

-- Blocked IP addresses
CREATE TABLE `blocked_ip_addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) NOT NULL,
  `ip_type` enum('single','range','subnet') DEFAULT 'single',
  `subnet_mask` varchar(45) DEFAULT NULL,
  `block_reason` varchar(500) NOT NULL,
  `blocked_by` int(11) NOT NULL,
  `blocked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_ip_address` (`ip_address`),
  KEY `idx_blocked_ip_addresses_ip` (`ip_address`),
  KEY `idx_blocked_ip_addresses_type` (`ip_type`),
  KEY `idx_blocked_ip_addresses_active` (`is_active`),
  KEY `idx_blocked_ip_addresses_expires` (`expires_at`),
  KEY `idx_blocked_ip_addresses_blocked_by` (`blocked_by`),
  CONSTRAINT `blocked_ip_addresses_ibfk_1` FOREIGN KEY (`blocked_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- IP access logs
CREATE TABLE `ip_access_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` enum('registration','login','blocked_registration','blocked_login') NOT NULL,
  `user_agent` text DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `isp` varchar(200) DEFAULT NULL,
  `is_blocked` tinyint(1) DEFAULT 0,
  `block_reason` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_ip_access_logs_ip` (`ip_address`),
  KEY `idx_ip_access_logs_user_id` (`user_id`),
  KEY `idx_ip_access_logs_action` (`action`),
  KEY `idx_ip_access_logs_is_blocked` (`is_blocked`),
  KEY `idx_ip_access_logs_created_at` (`created_at`),
  CONSTRAINT `ip_access_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- IP reputation
CREATE TABLE `ip_reputation` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) NOT NULL,
  `reputation_score` int(11) DEFAULT 0,
  `risk_level` enum('low','medium','high','critical') DEFAULT 'low',
  `is_tor` tinyint(1) DEFAULT 0,
  `is_vpn` tinyint(1) DEFAULT 0,
  `is_proxy` tinyint(1) DEFAULT 0,
  `is_hosting` tinyint(1) DEFAULT 0,
  `country` varchar(100) DEFAULT NULL,
  `isp` varchar(200) DEFAULT NULL,
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_ip_reputation` (`ip_address`),
  KEY `idx_ip_reputation_score` (`reputation_score`),
  KEY `idx_ip_reputation_risk` (`risk_level`),
  KEY `idx_ip_reputation_tor` (`is_tor`),
  KEY `idx_ip_reputation_vpn` (`is_vpn`),
  KEY `idx_ip_reputation_proxy` (`is_proxy`),
  KEY `idx_ip_reputation_hosting` (`is_hosting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- IP blocking rules
CREATE TABLE `ip_blocking_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule_name` varchar(100) NOT NULL,
  `rule_type` enum('country','isp','risk_level','tor','vpn','proxy','hosting') NOT NULL,
  `rule_value` varchar(200) NOT NULL,
  `action` enum('block','allow','challenge') NOT NULL,
  `priority` int(11) DEFAULT 100,
  `is_active` tinyint(1) DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_ip_blocking_rules_type` (`rule_type`),
  KEY `idx_ip_blocking_rules_action` (`action`),
  KEY `idx_ip_blocking_rules_priority` (`priority`),
  KEY `idx_ip_blocking_rules_active` (`is_active`),
  CONSTRAINT `ip_blocking_rules_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User IP history
CREATE TABLE `user_ip_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `action` enum('registration','login','logout') NOT NULL,
  `user_agent` text DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `isp` varchar(200) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_user_ip_history_user_id` (`user_id`),
  KEY `idx_user_ip_history_ip` (`ip_address`),
  KEY `idx_user_ip_history_action` (`action`),
  KEY `idx_user_ip_history_created_at` (`created_at`),
  CONSTRAINT `user_ip_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- ANTI-EVASION SYSTEM TABLES
-- =====================================================

-- Evasion signals
CREATE TABLE `evasion_signals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `signal_type` enum('email','name','ip','fingerprint','behavior') NOT NULL,
  `signal_value` varchar(500) NOT NULL,
  `normalized_value` varchar(500) NOT NULL,
  `confidence_score` decimal(5,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_evasion_signals_user_id` (`user_id`),
  KEY `idx_evasion_signals_type` (`signal_type`),
  KEY `idx_evasion_signals_normalized` (`normalized_value`),
  KEY `idx_evasion_signals_confidence` (`confidence_score`),
  CONSTRAINT `evasion_signals_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Evasion scores
CREATE TABLE `evasion_scores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `total_score` int(11) NOT NULL,
  `risk_level` enum('low','medium','high','critical') NOT NULL,
  `signals_count` int(11) DEFAULT 0,
  `decision` enum('allow','challenge','block') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_evasion_scores_user_id` (`user_id`),
  KEY `idx_evasion_scores_score` (`total_score`),
  KEY `idx_evasion_scores_risk` (`risk_level`),
  KEY `idx_evasion_scores_decision` (`decision`),
  CONSTRAINT `evasion_scores_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Banned identifiers
CREATE TABLE `banned_identifiers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier_type` enum('email','name','ip','fingerprint') NOT NULL,
  `identifier_value` varchar(500) NOT NULL,
  `normalized_value` varchar(500) NOT NULL,
  `ban_reason` varchar(500) NOT NULL,
  `banned_by` int(11) NOT NULL,
  `banned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_banned_identifiers_type` (`identifier_type`),
  KEY `idx_banned_identifiers_value` (`identifier_value`),
  KEY `idx_banned_identifiers_normalized` (`normalized_value`),
  KEY `idx_banned_identifiers_active` (`is_active`),
  CONSTRAINT `banned_identifiers_ibfk_1` FOREIGN KEY (`banned_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Proof of work challenges
CREATE TABLE `proof_of_work_challenges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `challenge_token` varchar(255) NOT NULL,
  `difficulty` int(11) NOT NULL,
  `nonce` varchar(255) DEFAULT NULL,
  `solution` varchar(255) DEFAULT NULL,
  `is_solved` tinyint(1) DEFAULT 0,
  `expires_at` timestamp NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_challenge_token` (`challenge_token`),
  KEY `idx_proof_of_work_challenges_user_id` (`user_id`),
  KEY `idx_proof_of_work_challenges_solved` (`is_solved`),
  KEY `idx_proof_of_work_challenges_expires` (`expires_at`),
  CONSTRAINT `proof_of_work_challenges_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin evasion logs
CREATE TABLE `admin_evasion_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `admin_id` int(11) NOT NULL,
  `action` enum('block','unblock','challenge','review') NOT NULL,
  `reason` text NOT NULL,
  `evasion_score` int(11) DEFAULT NULL,
  `signals_detected` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_admin_evasion_logs_user_id` (`user_id`),
  KEY `idx_admin_evasion_logs_admin_id` (`admin_id`),
  KEY `idx_admin_evasion_logs_action` (`action`),
  KEY `idx_admin_evasion_logs_created_at` (`created_at`),
  CONSTRAINT `admin_evasion_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `admin_evasion_logs_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Email verification tokens
CREATE TABLE `email_verification_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `is_used` tinyint(1) DEFAULT 0,
  `expires_at` timestamp NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_token` (`token`),
  KEY `idx_email_verification_tokens_user_id` (`user_id`),
  KEY `idx_email_verification_tokens_email` (`email`),
  KEY `idx_email_verification_tokens_used` (`is_used`),
  KEY `idx_email_verification_tokens_expires` (`expires_at`),
  CONSTRAINT `email_verification_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Browser fingerprints
CREATE TABLE `browser_fingerprints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `fingerprint_hash` varchar(255) NOT NULL,
  `user_agent` text DEFAULT NULL,
  `screen_resolution` varchar(20) DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `language` varchar(10) DEFAULT NULL,
  `platform` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_fingerprint_hash` (`fingerprint_hash`),
  KEY `idx_browser_fingerprints_user_id` (`user_id`),
  KEY `idx_browser_fingerprints_last_seen` (`last_seen`),
  CONSTRAINT `browser_fingerprints_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- VIEWS FOR ANALYTICS AND DASHBOARDS
-- =====================================================

-- IP blocking dashboard view
CREATE OR REPLACE VIEW `ip_blocking_dashboard` AS
SELECT 
    bip.ip_address,
    bip.ip_type,
    bip.block_reason,
    u.username as blocked_by_user,
    bip.blocked_at,
    bip.expires_at,
    bip.is_active,
    COUNT(ial.id) as access_attempts,
    COUNT(CASE WHEN ial.is_blocked = 1 THEN 1 END) as blocked_attempts,
    MAX(ial.created_at) as last_attempt
FROM blocked_ip_addresses bip
LEFT JOIN users u ON bip.blocked_by = u.id
LEFT JOIN ip_access_logs ial ON bip.ip_address = ial.ip_address
WHERE bip.is_active = 1
GROUP BY bip.id, bip.ip_address, bip.ip_type, bip.block_reason, u.username, bip.blocked_at, bip.expires_at, bip.is_active;

-- IP access statistics view
CREATE OR REPLACE VIEW `ip_access_statistics` AS
SELECT 
    DATE(ial.created_at) as date,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN ial.action = 'registration' THEN 1 END) as registration_attempts,
    COUNT(CASE WHEN ial.action = 'login' THEN 1 END) as login_attempts,
    COUNT(CASE WHEN ial.is_blocked = 1 THEN 1 END) as blocked_attempts,
    COUNT(DISTINCT ial.ip_address) as unique_ips,
    ROUND((COUNT(CASE WHEN ial.is_blocked = 1 THEN 1 END) / COUNT(*)) * 100, 2) as block_rate
FROM ip_access_logs ial
GROUP BY DATE(ial.created_at)
ORDER BY date DESC;

-- User blocking statistics view
CREATE OR REPLACE VIEW `user_blocking_statistics` AS
SELECT 
    DATE(u.blocked_at) as date,
    COUNT(*) as blocked_users,
    COUNT(CASE WHEN u.is_blocked = 1 THEN 1 END) as currently_blocked,
    COUNT(CASE WHEN u.is_blocked = 0 AND u.blocked_at IS NOT NULL THEN 1 END) as unblocked_users,
    u2.username as blocked_by_user,
    COUNT(DISTINCT u.blocked_by) as unique_admins
FROM users u
LEFT JOIN users u2 ON u.blocked_by = u2.id
WHERE u.blocked_at IS NOT NULL
GROUP BY DATE(u.blocked_at), u.blocked_by, u2.username
ORDER BY date DESC;

-- Notification guard statistics view
CREATE OR REPLACE VIEW `notification_guard_statistics` AS
SELECT 
    DATE(ngl.created_at) as date,
    COUNT(*) as total_decisions,
    COUNT(CASE WHEN ngl.decision = 'allow' THEN 1 END) as allowed_notifications,
    COUNT(CASE WHEN ngl.decision = 'block' THEN 1 END) as blocked_notifications,
    COUNT(CASE WHEN ngl.change_detected = 1 THEN 1 END) as changes_detected,
    ROUND((COUNT(CASE WHEN ngl.decision = 'block' THEN 1 END) / COUNT(*)) * 100, 2) as block_rate
FROM notification_guard_logs ngl
GROUP BY DATE(ngl.created_at)
ORDER BY date DESC;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Check IP blocking procedure
DELIMITER //
CREATE PROCEDURE CheckIPBlocking(IN ip_address VARCHAR(45))
BEGIN
    DECLARE is_blocked TINYINT(1) DEFAULT 0;
    DECLARE block_reason VARCHAR(500) DEFAULT NULL;
    DECLARE expires_at TIMESTAMP DEFAULT NULL;
    
    -- Check if IP is directly blocked
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END,
        MAX(bip.block_reason),
        MAX(bip.expires_at)
    INTO is_blocked, block_reason, expires_at
    FROM blocked_ip_addresses bip
    WHERE bip.ip_address = ip_address 
    AND bip.is_active = 1
    AND (bip.expires_at IS NULL OR bip.expires_at > NOW());
    
    SELECT 
        is_blocked as is_blocked,
        block_reason as block_reason,
        expires_at as expires_at;
END //
DELIMITER ;

-- Log IP access procedure
DELIMITER //
CREATE PROCEDURE LogIPAccess(
    IN ip_address VARCHAR(45),
    IN user_id INT,
    IN action ENUM('registration','login','blocked_registration','blocked_login'),
    IN user_agent TEXT,
    IN country VARCHAR(100),
    IN city VARCHAR(100),
    IN isp VARCHAR(200),
    IN is_blocked TINYINT(1),
    IN block_reason VARCHAR(500)
)
BEGIN
    INSERT INTO ip_access_logs (
        ip_address, user_id, action, user_agent, country, city, isp, is_blocked, block_reason
    ) VALUES (
        ip_address, user_id, action, user_agent, country, city, isp, is_blocked, block_reason
    );
    
    -- Also log to user IP history if user_id is provided
    IF user_id IS NOT NULL THEN
        INSERT INTO user_ip_history (
            user_id, ip_address, action, user_agent, country, city, isp
        ) VALUES (
            user_id, ip_address, action, user_agent, country, city, isp
        );
    END IF;
END //
DELIMITER ;

-- =====================================================
-- EVENTS FOR AUTOMATIC CLEANUP
-- =====================================================

-- Clean up expired IP blocks
CREATE EVENT IF NOT EXISTS cleanup_expired_ip_blocks
ON SCHEDULE EVERY 1 HOUR
DO
  UPDATE blocked_ip_addresses 
  SET is_active = 0 
  WHERE expires_at IS NOT NULL 
  AND expires_at < NOW() 
  AND is_active = 1;

-- Clean up expired proof of work challenges
CREATE EVENT IF NOT EXISTS cleanup_expired_pow_challenges
ON SCHEDULE EVERY 1 HOUR
DO
  DELETE FROM proof_of_work_challenges 
  WHERE expires_at < NOW() 
  AND is_solved = 0;

-- Clean up expired email verification tokens
CREATE EVENT IF NOT EXISTS cleanup_expired_email_tokens
ON SCHEDULE EVERY 1 HOUR
DO
  DELETE FROM email_verification_tokens 
  WHERE expires_at < NOW() 
  AND is_used = 0;

-- =====================================================
-- INITIAL DATA INSERTION
-- =====================================================

-- Note: Kao Kirei sites are now treated as normal sites
-- Users must add them manually to receive notifications
-- No default global notifications or system users are created

-- Default IP blocking rules will be created when first admin user is created
-- No default rules inserted here to avoid foreign key constraint issues

-- =====================================================
-- HOW TO ADD KAO KIREI SITES (FOR USERS)
-- =====================================================
-- Users can add Kao Kirei sites manually through the extension:
-- 
-- Example 1: 花王 家庭用品の製造終了品一覧
-- URL: https://www.kao-kirei.com/ja/expire-item/khg/?tw=khg
-- Scraping Method: dom_parser
-- Check Interval: 24 hours
--
-- Example 2: 花王・カネボウ化粧品 製造終了品一覧
-- URL: https://www.kao-kirei.com/ja/expire-item/kbb/?tw=kbb
-- Scraping Method: dom_parser
-- Check Interval: 24 hours
--
-- These sites will be monitored like any other site, and notifications
-- will only be sent to the user who added them.
-- =====================================================

-- =====================================================
-- ADDITIONAL INDEXES FOR PERFORMANCE
-- =====================================================

-- Composite indexes for better performance
CREATE INDEX `idx_blocked_ip_addresses_ip_type_active` ON `blocked_ip_addresses` (`ip_address`, `ip_type`, `is_active`);
CREATE INDEX `idx_ip_access_logs_ip_action_created` ON `ip_access_logs` (`ip_address`, `action`, `created_at`);
CREATE INDEX `idx_user_ip_history_user_ip_created` ON `user_ip_history` (`user_id`, `ip_address`, `created_at`);
CREATE INDEX `idx_notification_guard_logs_site_decision_created` ON `notification_guard_logs` (`site_id`, `decision`, `created_at`);
CREATE INDEX `idx_evasion_signals_type_normalized_confidence` ON `evasion_signals` (`signal_type`, `normalized_value`, `confidence_score`);

-- =====================================================
-- REAL-TIME BLOCKING VERIFICATION TABLES
-- =====================================================

-- Blocked emails table
CREATE TABLE IF NOT EXISTS blocked_emails (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    reason TEXT,
    blocked_by INT,
    is_active BOOLEAN DEFAULT TRUE,
    blocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unblocked_at TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_is_active (is_active),
    FOREIGN KEY (blocked_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Blocked access logs
CREATE TABLE IF NOT EXISTS blocked_access_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    ip_address VARCHAR(45),
    email VARCHAR(255),
    block_reason TEXT,
    block_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_ip_address (ip_address),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- User sessions table
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    session_token VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =====================================================
-- FINAL COMMIT
-- =====================================================

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;